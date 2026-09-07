import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';
import '../../../resume/presentation/controllers/resume_controller.dart';
import '../controllers/interview_controller.dart';
import '../models/interview_phase.dart';
import '../widgets/ai_voice_status_bar.dart';
import '../widgets/live_caption_card.dart';
import '../widgets/question_streaming_card.dart';
import '../widgets/session_error_view.dart';
import '../widgets/session_header.dart';
import '../widgets/voice_control_center.dart';
import 'interview_result_page.dart';

export '../models/interview_phase.dart';

class InterviewSessionPage extends StatefulWidget {
  const InterviewSessionPage({super.key});

  @override
  State<InterviewSessionPage> createState() => _InterviewSessionPageState();
}

class _InterviewSessionPageState extends State<InterviewSessionPage>
    with TickerProviderStateMixin {

  // ── TTS & STT ─────────────────────────────────────────────────────────────
  final FlutterTts _tts = FlutterTts();
  bool _ttsAvailable = false;

  final stt.SpeechToText _stt = stt.SpeechToText();
  bool _sttAvailable = false;
  String _accumulatedTranscript = '';
  String _currentUtterance = '';
  String _liveTranscript = '';
  bool _isExplicitlyStopping = false;
  final TextEditingController _answerCtrl = TextEditingController();
  final FocusNode _answerFocusNode = FocusNode();

  // ── Scroll Controllers for Dynamic UI Adjustments ─────────────────────────
  final ScrollController _contentScrollCtrl = ScrollController();
  final ScrollController _liveTranscriptScrollCtrl = ScrollController();
  final ScrollController _answerEditorScrollCtrl = ScrollController();

  void _autoScrollTranscript() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_liveTranscriptScrollCtrl.hasClients) {
        _liveTranscriptScrollCtrl.animateTo(
          _liveTranscriptScrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
        );
      }
      if (_contentScrollCtrl.hasClients) {
        _contentScrollCtrl.animateTo(
          _contentScrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Word-by-Word Streaming Question State ─────────────────────────────────
  Timer? _streamingTimer;
  int _displayedWordCount = 0;
  List<String> _questionWords = [];
  bool _isAcknowledgementFinished = false;

  // ── State & Timers ────────────────────────────────────────────────────────
  InterviewPhase _phase = InterviewPhase.loading;
  int _sessionElapsedSeconds = 0;
  Timer? _sessionTimer;

  // ── Wave & Pulse Animations ───────────────────────────────────────────────
  late AnimationController _waveAnimCtrl;
  late AnimationController _pulseAnimCtrl;

  Timer? _ttsSafetyTimer;

  // ── Loading Status Rotation ───────────────────────────────────────────────
  static const _loadingStatuses = [
    'Preparing your interview…',
    'Analyzing your profile…',
    'Selecting interview topics…',
    'Getting your first question ready…',
    'Almost there…',
  ];
  int _loadingStatusIndex = 0;
  Timer? _loadingStatusTimer;
  late AnimationController _loadingFadeCtrl;
  late Animation<double> _loadingFadeAnim;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    _waveAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _loadingFadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _loadingFadeAnim = CurvedAnimation(
      parent: _loadingFadeCtrl,
      curve: Curves.easeInOut,
    );
    _loadingFadeCtrl.forward();

    _initStt();
    _startLoadingStatusCycle();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initTts();
      if (mounted) {
        _startSession();
        _startSessionTimer();
      }
    });
  }

  @override
  void dispose() {
    _streamingTimer?.cancel();
    _ttsSafetyTimer?.cancel();
    _loadingStatusTimer?.cancel();
    _tts.stop();
    _stt.stop();
    _sessionTimer?.cancel();
    _waveAnimCtrl.dispose();
    _pulseAnimCtrl.dispose();
    _loadingFadeCtrl.dispose();
    _answerCtrl.dispose();
    _answerFocusNode.dispose();
    _contentScrollCtrl.dispose();
    _liveTranscriptScrollCtrl.dispose();
    _answerEditorScrollCtrl.dispose();
    super.dispose();
  }

  // ── Loading Status Cycle ─────────────────────────────────────────────────

  void _startLoadingStatusCycle() {
    _loadingStatusTimer?.cancel();
    _loadingStatusTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      _loadingFadeCtrl.reverse().then((_) {
        if (!mounted) return;
        setState(() {
          _loadingStatusIndex =
              (_loadingStatusIndex + 1) % _loadingStatuses.length;
        });
        _loadingFadeCtrl.forward();
      });
    });
  }

  void _stopLoadingStatusCycle() {
    _loadingStatusTimer?.cancel();
    _loadingStatusTimer = null;
  }

  // ── Engine Initializers ───────────────────────────────────────────────────

  Future<void> _initTts() async {
    final langResult = await _tts.setLanguage('en-US');
    if (langResult != 1 && mounted) {
      await _tts.setLanguage('en');
    }

    await _tts.setSpeechRate(0.48);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);

    _tts.setCompletionHandler(() {
      _ttsSafetyTimer?.cancel();
      if (mounted) {
        _completeTextStreaming();
        if (_phase == InterviewPhase.speaking) {
          _setPhase(InterviewPhase.listening);
        }
      }
    });

    _tts.setErrorHandler((msg) {
      _ttsSafetyTimer?.cancel();
      debugPrint('[TTS Error]: $msg');
      if (mounted) {
        _completeTextStreaming();
        if (_phase == InterviewPhase.speaking) {
          _setPhase(InterviewPhase.listening);
        }
      }
    });

    if (mounted) setState(() => _ttsAvailable = true);
  }

  Future<void> _initStt() async {
    final ok = await _stt.initialize(
      onError: (e) async {
        debugPrint('[STT Error]: ${e.errorMsg} (permanent: ${e.permanent})');
        // Transient pause timeouts (e.g. error_speech_timeout or error_no_match)
        // should never abort active recording. Seamlessly resume listening.
        if (mounted && _phase == InterviewPhase.recording && !_isExplicitlyStopping) {
          if (_currentUtterance.isNotEmpty) {
            _accumulatedTranscript = _liveTranscript;
            _currentUtterance = '';
          }
          await Future.delayed(const Duration(milliseconds: 250));
          if (mounted && _phase == InterviewPhase.recording && !_isExplicitlyStopping) {
            await _listenInternal();
          }
        }
      },
      onStatus: (status) async {
        debugPrint('[STT Status]: $status');
        // When engine stops listening after utterance boundary or pause,
        // seamlessly resume listening so the candidate can continue speaking.
        if (status == 'notListening' &&
            _phase == InterviewPhase.recording &&
            !_isExplicitlyStopping) {
          if (_currentUtterance.isNotEmpty) {
            _accumulatedTranscript = _liveTranscript;
            _currentUtterance = '';
          }
          await Future.delayed(const Duration(milliseconds: 200));
          if (mounted && _phase == InterviewPhase.recording && !_isExplicitlyStopping) {
            await _listenInternal();
          }
        }
      },
    );
    if (mounted) setState(() => _sttAvailable = ok);
  }

  // ── Session Orchestration ─────────────────────────────────────────────────

  Future<void> _startSession() async {
    final ic = context.read<InterviewController>();
    final rc = context.read<ResumeController>();
    final pc = context.read<ProfileController>();

    if (ic.sessionStatus == SessionStatus.active && ic.prompts.isNotEmpty) {
      _stopLoadingStatusCycle();
      _speakCurrentQuestion();
      return;
    }

    if (ic.sessionStatus == SessionStatus.idle) {
      final auth = context.read<AuthController>();
      final userRole = pc.profile?.targetRole?.trim().isNotEmpty == true
          ? pc.profile!.targetRole!.trim()
          : (auth.user?.targetRole.trim().isNotEmpty == true
              ? auth.user!.targetRole.trim()
              : null);
      await ic.startInterview(
        resume: rc.resume,
        profile: pc.profile,
        targetRole: userRole,
      );
      if (!mounted) return;
      if (ic.sessionStatus == SessionStatus.active && ic.prompts.isNotEmpty) {
        _stopLoadingStatusCycle();
        _speakCurrentQuestion();
      }
    }
  }

  void _retryStartInterview() {
    final ic = context.read<InterviewController>();
    final rc = context.read<ResumeController>();
    final pc = context.read<ProfileController>();
    final auth = context.read<AuthController>();
    final userRole = pc.profile?.targetRole?.trim().isNotEmpty == true
        ? pc.profile!.targetRole!.trim()
        : (auth.user?.targetRole.trim().isNotEmpty == true
            ? auth.user!.targetRole.trim()
            : null);
    ic.startInterview(
      resume: rc.resume,
      profile: pc.profile,
      targetRole: userRole,
    ).then((_) {
      if (mounted && ic.sessionStatus == SessionStatus.active) {
        _speakCurrentQuestion();
      }
    });
  }

  void _speakCurrentQuestion() {
    final ic = context.read<InterviewController>();
    if (!mounted || ic.prompts.isEmpty) return;

    _ttsSafetyTimer?.cancel();
    _setPhase(InterviewPhase.speaking);

    // Prepare streaming word list
    final questionText = ic.currentQuestion.trim();
    _questionWords = questionText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    _displayedWordCount = 0;
    _isAcknowledgementFinished = true;

    _startTextStreaming();

    final speech = ic.currentAcknowledgement.isNotEmpty
        ? '${ic.currentAcknowledgement} ${ic.currentQuestion}'
        : ic.currentQuestion;

    if (_ttsAvailable && speech.isNotEmpty) {
      final approxDurationMs = (speech.split(' ').length * 360) + 1800;
      _ttsSafetyTimer = Timer(Duration(milliseconds: approxDurationMs), () {
        if (mounted && _phase == InterviewPhase.speaking) {
          _completeTextStreaming();
          _setPhase(ic.isComplete ? InterviewPhase.done : InterviewPhase.listening);
        }
      });

      _tts.speak(speech).catchError((_) {
        if (mounted && _phase == InterviewPhase.speaking) {
          _completeTextStreaming();
          _setPhase(ic.isComplete ? InterviewPhase.done : InterviewPhase.listening);
        }
      });
    } else {
      _completeTextStreaming();
      _setPhase(ic.isComplete ? InterviewPhase.done : InterviewPhase.listening);
    }
  }

  void _skipTts() {
    final ic = context.read<InterviewController>();
    _ttsSafetyTimer?.cancel();
    _tts.stop();
    _completeTextStreaming();
    _setPhase(ic.isComplete ? InterviewPhase.done : InterviewPhase.listening);
  }

  // ── Word-by-Word Streaming Engine ─────────────────────────────────────────

  void _startTextStreaming() {
    _streamingTimer?.cancel();

    // Stream words progressively at speech tempo (~190ms per word)
    const wordInterval = Duration(milliseconds: 190);
    _streamingTimer = Timer.periodic(wordInterval, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (!_isAcknowledgementFinished) {
          _isAcknowledgementFinished = true;
        } else if (_displayedWordCount < _questionWords.length) {
          _displayedWordCount++;
        } else {
          timer.cancel();
        }
      });
    });
  }

  void _completeTextStreaming() {
    _streamingTimer?.cancel();
    if (mounted) {
      setState(() {
        _isAcknowledgementFinished = true;
        _displayedWordCount = _questionWords.length;
      });
    }
  }

  // ── Voice Input Lifecycle ─────────────────────────────────────────────────

  Future<void> _startRecording() async {
    if (!_sttAvailable || _phase == InterviewPhase.recording) return;

    _isExplicitlyStopping = false;
    _accumulatedTranscript = '';
    _currentUtterance = '';
    setState(() {
      _liveTranscript = '';
    });
    _setPhase(InterviewPhase.recording);

    await _listenInternal();
  }

  Future<void> _listenInternal() async {
    if (!_sttAvailable || _isExplicitlyStopping || _phase != InterviewPhase.recording) {
      return;
    }

    try {
      await _stt.listen(
        onResult: (result) {
          if (!mounted || _phase != InterviewPhase.recording) return;

          final words = result.recognizedWords.trim();
          if (words.isEmpty) return;

          setState(() {
            _currentUtterance = words;
            _liveTranscript = _accumulatedTranscript.isEmpty
                ? _currentUtterance
                : '$_accumulatedTranscript $_currentUtterance';
          });

          _autoScrollTranscript();

          // When engine finalizes an utterance chunk, commit to accumulated transcript
          if (result.finalResult) {
            _accumulatedTranscript = _liveTranscript;
            _currentUtterance = '';
          }
        },
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.dictation,
          cancelOnError: false,
          partialResults: true,
          listenFor: const Duration(minutes: 10),
          pauseFor: const Duration(seconds: 15),
        ),
      );
    } catch (e) {
      debugPrint('[STT listen exception]: $e');
    }
  }

  Future<void> _finishRecordingAndSubmit() async {
    _isExplicitlyStopping = true;
    await _stt.stop();
    if (_currentUtterance.isNotEmpty) {
      _accumulatedTranscript = _liveTranscript;
      _currentUtterance = '';
    }
    final answer = _liveTranscript.trim();
    if (answer.isNotEmpty) {
      // Move to answered phase: show editable transcript card
      _answerCtrl.text = answer;
      _setPhase(InterviewPhase.answered);
    } else {
      _setPhase(InterviewPhase.listening);
    }
  }

  Future<void> _submitAnswer(String answer) async {
    final ic = context.read<InterviewController>();
    _setPhase(InterviewPhase.thinking);

    await ic.submitAnswer(answer);

    if (!mounted) return;

    if (ic.sessionStatus == SessionStatus.complete ||
        ic.sessionStatus == SessionStatus.evaluating) {
      _navigateToResult(ic);
      return;
    }

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _accumulatedTranscript = '';
        _currentUtterance = '';
        setState(() {
          _liveTranscript = '';
        });
        _answerCtrl.clear();
        _speakCurrentQuestion();
      }
    });
  }

  void _navigateToResult(InterviewController ic) {
    _streamingTimer?.cancel();
    _tts.stop();
    _stt.stop();
    _sessionTimer?.cancel();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const InterviewResultPage()),
      );
    });
  }

  /// Re-plays the current question via TTS without changing the UI phase.
  void _replayQuestion() {
    final ic = context.read<InterviewController>();
    if (!mounted || ic.prompts.isEmpty) return;
    final speech = ic.currentAcknowledgement.isNotEmpty
        ? '${ic.currentAcknowledgement} ${ic.currentQuestion}'
        : ic.currentQuestion;
    if (_ttsAvailable && speech.trim().isNotEmpty) {
      _tts.speak(speech);
    }
  }

  /// Clears the answer draft and re-starts STT recording.
  Future<void> _reRecord() async {
    _isExplicitlyStopping = false;
    _accumulatedTranscript = '';
    _currentUtterance = '';
    _answerCtrl.clear();
    setState(() => _liveTranscript = '');
    await _startRecording();
  }

  /// Submits the (possibly keyboard-edited) answer from the editor.
  Future<void> _submitFromEditor() async {
    _answerFocusNode.unfocus();
    final answer = _answerCtrl.text.trim();
    if (answer.isEmpty) return;
    await _submitAnswer(answer);
  }

  // ── Session Controls ──────────────────────────────────────────────────────

  void _startSessionTimer() {
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _sessionElapsedSeconds++);
    });
  }

  void _setPhase(InterviewPhase p) {
    if (!mounted) return;
    setState(() => _phase = p);
  }

  void _confirmExit(AppColorScheme colors) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: colors.border.withValues(alpha: 0.4)),
        ),
        title: Text('Exit Interview?', style: AppTypography.bold(16, color: colors.text)),
        content: Text(
          'Are you sure you want to end this mock interview session?',
          style: AppTypography.regular(13, color: colors.mutedForeground),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Continue', style: AppTypography.semiBold(13, color: colors.mutedForeground)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.destructive,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              _streamingTimer?.cancel();
              _tts.stop();
              _stt.stop();
              Navigator.of(context).pop();
            },
            child: Text('End Session', style: AppTypography.bold(13, color: colors.destructiveForeground)),
          ),
        ],
      ),
    );
  }

  // ── Main UI Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = AppColorScheme.of(context);
    final ic = context.watch<InterviewController>();

    if (ic.sessionStatus == SessionStatus.complete && _phase != InterviewPhase.done) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _phase = InterviewPhase.done);
          _navigateToResult(ic);
        }
      });
    }

    // Reactive sync: When controller transitions to active with questions, start speaking if still in loading phase
    if (_phase == InterviewPhase.loading &&
        ic.sessionStatus == SessionStatus.active &&
        ic.prompts.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _phase == InterviewPhase.loading) {
          _speakCurrentQuestion();
        }
      });
    }

    final hasError = ic.sessionStatus == SessionStatus.error ||
        (ic.errorMessage != null && ic.prompts.isEmpty);

    if (hasError) {
      return SessionErrorView(
        errorMessage: ic.errorMessage,
        colors: colors,
        onExit: () => Navigator.of(context).pop(),
        onRetry: _retryStartInterview,
      );
    }

    final isLoading = _phase == InterviewPhase.loading || ic.prompts.isEmpty;
    final role = ic.config.role.isNotEmpty ? ic.config.role : 'Candidate';

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── 1. Compact Header ───────────────────────────────────────────
            SessionHeader(
              role: role,
              elapsedSeconds: _sessionElapsedSeconds,
              onExit: () => _confirmExit(colors),
              colors: colors,
            ),

            // ── 2. Interactive Interview Room Content ───────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 12),

                    // ── Sleek Dynamic AI Voice Status Pill ──────────────────
                    AIVoiceStatusBar(
                      colors: colors,
                      isLoading: isLoading,
                      isComplete: ic.isComplete,
                      phase: _phase,
                      waveAnimCtrl: _waveAnimCtrl,
                    ),

                    const SizedBox(height: 14),

                    // ── HERO: Word-by-Word Streaming Question Card ──────────
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          controller: _contentScrollCtrl,
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!isLoading && ic.currentQuestion.isNotEmpty)
                                QuestionStreamingCard(
                                  question: ic.currentQuestion,
                                  questionWords: _questionWords,
                                  displayedWordCount: _displayedWordCount,
                                  isSpeaking: _phase == InterviewPhase.speaking,
                                  pulseAnim: _pulseAnimCtrl,
                                  colors: colors,
                                )
                              else if (isLoading)
                                LoadingQuestionPlaceholder(
                                  colors: colors,
                                  fadeAnim: _loadingFadeAnim,
                                  statusText: _loadingStatuses[_loadingStatusIndex],
                                ),

                              // Live transcript dynamically expanding while recording
                              if (_phase == InterviewPhase.recording)
                                LiveCaptionCard(
                                  liveTranscript: _liveTranscript,
                                  scrollController: _liveTranscriptScrollCtrl,
                                  pulseAnim: _pulseAnimCtrl,
                                  colors: colors,
                                ),

                              // Editable answer card after recording stops
                              if (_phase == InterviewPhase.answered)
                                AnswerEditorCard(
                                  answerController: _answerCtrl,
                                  focusNode: _answerFocusNode,
                                  scrollController: _answerEditorScrollCtrl,
                                  colors: colors,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── 3. Voice Controls & Primary Actions ─────────────────
                    VoiceControlCenter(
                      isLoading: isLoading,
                      isComplete: ic.isComplete,
                      phase: _phase,
                      colors: colors,
                      onViewEvaluation: () => _navigateToResult(ic),
                      onSkipTts: _skipTts,
                      onStopRecording: _finishRecordingAndSubmit,
                      onReplayQuestion: _replayQuestion,
                      onReRecord: _reRecord,
                      onSubmitFromEditor: _submitFromEditor,
                      onStartRecording: _startRecording,
                    ),

                    const SizedBox(height: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
