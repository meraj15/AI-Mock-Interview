import 'dart:async';
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';
import '../../../resume/presentation/controllers/resume_controller.dart';
import '../controllers/interview_controller.dart';
import 'interview_result_page.dart';

// ── Voice Interview Room States ──────────────────────────────────────────────

enum InterviewPhase {
  loading,   // Initial session setup / planning
  speaking,  // AI interviewer is speaking question & streaming text
  listening, // AI is waiting for candidate to start speaking
  recording, // Candidate is actively recording response
  thinking,  // Answer received, AI is processing / generating next question
  done,      // Session finished
}

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
  String _liveTranscript = '';

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

    _initStt();

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
    _tts.stop();
    _stt.stop();
    _sessionTimer?.cancel();
    _waveAnimCtrl.dispose();
    _pulseAnimCtrl.dispose();
    super.dispose();
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
      if (mounted) {
        _completeTextStreaming();
        if (_phase == InterviewPhase.speaking) {
          _setPhase(InterviewPhase.listening);
        }
      }
    });

    _tts.setErrorHandler((msg) {
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
      onError: (e) {
        debugPrint('[STT Error]: ${e.errorMsg}');
        if (mounted && _phase == InterviewPhase.recording) {
          _setPhase(InterviewPhase.listening);
        }
      },
      onStatus: (status) {
        if (status == 'notListening' && _phase == InterviewPhase.recording) {
          // Idle status
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

    if (ic.sessionStatus == SessionStatus.loading ||
        ic.sessionStatus == SessionStatus.active) {
      if (ic.sessionStatus != SessionStatus.active &&
          ic.sessionStatus != SessionStatus.error) {
        await _waitForQuestions(ic);
      }
    } else if (ic.sessionStatus != SessionStatus.error) {
      await ic.startInterview(resume: rc.resume, profile: pc.profile);
    }

    if (!mounted) return;
    if (ic.sessionStatus == SessionStatus.error || ic.prompts.isEmpty) {
      return;
    }
    _speakCurrentQuestion();
  }

  Future<void> _waitForQuestions(InterviewController ic) async {
    int waited = 0;
    while (ic.sessionStatus == SessionStatus.loading && waited < 40 && mounted) {
      await Future.delayed(const Duration(milliseconds: 300));
      waited++;
    }
  }

  void _speakCurrentQuestion() {
    final ic = context.read<InterviewController>();
    if (!mounted || ic.prompts.isEmpty) return;

    _setPhase(InterviewPhase.speaking);

    // Prepare streaming word list
    final questionText = ic.currentQuestion.trim();
    _questionWords = questionText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    _displayedWordCount = 0;
    _isAcknowledgementFinished = ic.currentAcknowledgement.isEmpty;

    _startTextStreaming();

    final speech = ic.currentAcknowledgement.isNotEmpty
        ? '${ic.currentAcknowledgement} ${ic.currentQuestion}'
        : ic.currentQuestion;

    if (_ttsAvailable) {
      _tts.speak(speech);
    } else {
      Future.delayed(Duration(milliseconds: 400 + (_questionWords.length * 200)), () {
        if (mounted && _phase == InterviewPhase.speaking) {
          _completeTextStreaming();
          _setPhase(InterviewPhase.listening);
        }
      });
    }
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

    setState(() {
      _liveTranscript = '';
    });
    _setPhase(InterviewPhase.recording);

    await _stt.listen(
      onResult: (result) {
        if (!mounted) return;
        setState(() {
          _liveTranscript = result.recognizedWords;
        });
      },
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.dictation,
        cancelOnError: false,
        partialResults: true,
      ),
    );
  }

  Future<void> _finishRecordingAndSubmit() async {
    await _stt.stop();
    final answer = _liveTranscript.trim();
    if (answer.isNotEmpty) {
      _submitAnswer(answer);
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
        setState(() {
          _liveTranscript = '';
        });
        _speakCurrentQuestion();
      }
    });
  }

  void _skipTts() {
    _tts.stop();
    _completeTextStreaming();
    _setPhase(InterviewPhase.listening);
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

  String _formatTime(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
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

    final hasError = ic.sessionStatus == SessionStatus.error ||
        (ic.errorMessage != null && ic.prompts.isEmpty);

    if (hasError) {
      return _buildErrorView(ic, colors);
    }

    final isLoading = _phase == InterviewPhase.loading || ic.prompts.isEmpty;
    final role = ic.config.role.isNotEmpty ? ic.config.role : 'Candidate';

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── 1. Compact Header ───────────────────────────────────────────
            _buildCompactHeader(role, colors),

            // ── 2. Interactive Interview Room Content ───────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 12),

                    // ── Sleek Dynamic AI Voice Status Pill ──────────────────
                    _buildDynamicAIVoiceBar(colors, isLoading),

                    const SizedBox(height: 14),

                    // ── HERO: Word-by-Word Streaming Question Card ──────────
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!isLoading && ic.currentQuestion.isNotEmpty)
                                _buildStreamingQuestionCard(ic, colors)
                              else if (isLoading)
                                _buildLoadingQuestionPlaceholder(colors),

                              // Live Caption (Appears smoothly when recording)
                              if (_phase == InterviewPhase.recording && _liveTranscript.isNotEmpty)
                                _buildLiveCaptionCard(colors),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── 3. Voice Controls & Primary Actions ─────────────────
                    _buildVoiceControlCenter(isLoading, colors),

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

  // ── Compact Header ────────────────────────────────────────────────────────

  Widget _buildCompactHeader(String role, AppColorScheme colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(
          bottom: BorderSide(color: colors.border.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Exit Button
          GestureDetector(
            onTap: () => _confirmExit(colors),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.border.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(FeatherIcons.x, size: 12, color: colors.mutedForeground),
                  const SizedBox(width: 4),
                  Text('Exit', style: AppTypography.semiBold(11, color: colors.text)),
                ],
              ),
            ),
          ),

          // Role Title & Subtitle
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    role,
                    style: AppTypography.bold(12.5, color: colors.text),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'AI Mock Interview',
                    style: AppTypography.medium(10, color: colors.mint),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // Timer Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.border.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(FeatherIcons.clock, size: 11, color: colors.mutedForeground),
                const SizedBox(width: 4),
                Text(
                  _formatTime(_sessionElapsedSeconds),
                  style: AppTypography.semiBold(11, color: colors.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Sleek Dynamic AI Voice Status Capsule ─────────────────────────────────

  Widget _buildDynamicAIVoiceBar(AppColorScheme colors, bool isLoading) {
    Color accentColor;
    String statusLabel;
    IconData icon;

    if (isLoading) {
      accentColor = colors.primary;
      statusLabel = 'AI Interviewer • Preparing question…';
      icon = FeatherIcons.loader;
    } else {
      switch (_phase) {
        case InterviewPhase.speaking:
          accentColor = colors.mint;
          statusLabel = 'AI Interviewer • Speaking';
          icon = FeatherIcons.volume2;
          break;
        case InterviewPhase.listening:
          accentColor = colors.primary;
          statusLabel = 'AI Interviewer • Listening to you';
          icon = FeatherIcons.radio;
          break;
        case InterviewPhase.recording:
          accentColor = colors.destructive;
          statusLabel = 'You • Recording answer…';
          icon = FeatherIcons.mic;
          break;
        case InterviewPhase.thinking:
          accentColor = colors.violet;
          statusLabel = 'AI Interviewer • Evaluating response…';
          icon = FeatherIcons.cpu;
          break;
        case InterviewPhase.done:
        case InterviewPhase.loading:
          accentColor = colors.mint;
          statusLabel = 'AI Interviewer';
          icon = FeatherIcons.check;
          break;
      }
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withValues(alpha: 0.35), width: 1),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.12),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated Waveform Bars / Glowing Dot
          if (_phase == InterviewPhase.speaking || _phase == InterviewPhase.recording)
            _MiniVoiceWaveVisualizer(
              color: accentColor,
              anim: _waveAnimCtrl,
            )
          else
            Icon(icon, size: 13, color: accentColor),

          const SizedBox(width: 8),

          Text(
            statusLabel,
            style: AppTypography.semiBold(11.5, color: accentColor),
          ),
        ],
      ),
    );
  }

  // ── HERO: Word-by-Word Streaming Question Card ────────────────────────────

  Widget _buildStreamingQuestionCard(InterviewController ic, AppColorScheme colors) {
    final acknowledgement = ic.currentAcknowledgement.trim();
    final isStreamingActive = _phase == InterviewPhase.speaking &&
        _displayedWordCount < _questionWords.length;

    // Display revealed words up to _displayedWordCount
    final displayedText = isStreamingActive
        ? _questionWords.take(_displayedWordCount).join(' ')
        : ic.currentQuestion.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _phase == InterviewPhase.speaking
              ? colors.mint.withValues(alpha: 0.45)
              : colors.border.withValues(alpha: 0.6),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Acknowledgement Banner (if available)
          if (acknowledgement.isNotEmpty && _isAcknowledgementFinished) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(FeatherIcons.check, size: 13, color: colors.mint),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '"$acknowledgement"',
                    style: AppTypography.medium(
                      12.5,
                      color: colors.mint,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: colors.border.withValues(alpha: 0.4), height: 1),
            const SizedBox(height: 14),
          ],

          // Question Text (Streaming word-by-word with pulsing caret)
          RichText(
            text: TextSpan(
              style: AppTypography.semiBold(
                17,
                color: colors.text,
                height: 1.48,
              ),
              children: [
                TextSpan(text: displayedText),
                if (isStreamingActive)
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: FadeTransition(
                      opacity: _pulseAnimCtrl,
                      child: Container(
                        margin: const EdgeInsets.only(left: 4),
                        width: 7,
                        height: 16,
                        decoration: BoxDecoration(
                          color: colors.mint,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingQuestionPlaceholder(AppColorScheme colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 34),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border.withValues(alpha: 0.4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Formulating your next question…',
            style: AppTypography.medium(13, color: colors.mutedForeground),
          ),
        ],
      ),
    );
  }

  // ── Temporary Live Caption Widget ─────────────────────────────────────────

  Widget _buildLiveCaptionCard(AppColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxHeight: 90),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: colors.destructive.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.destructive.withValues(alpha: 0.3)),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: colors.destructive,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _liveTranscript,
                  style: AppTypography.regular(
                    12.5,
                    color: colors.text,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Voice Interaction & Minimal Controls ──────────────────────────────────

  Widget _buildVoiceControlCenter(bool isLoading, AppColorScheme colors) {
    if (isLoading) {
      return const SizedBox(height: 72);
    }

    if (_phase == InterviewPhase.speaking) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colors.border.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(FeatherIcons.volume2, size: 14, color: colors.mint),
            const SizedBox(width: 8),
            Text(
              'AI speaking…',
              style: AppTypography.medium(12, color: colors.mutedForeground),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _skipTts,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.mint.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Skip',
                  style: AppTypography.bold(11, color: colors.mint),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_phase == InterviewPhase.thinking) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Evaluating response…',
              style: AppTypography.semiBold(12, color: colors.text),
            ),
          ],
        ),
      );
    }

    // Listening or Recording Phase
    final isRecording = _phase == InterviewPhase.recording;
    final btnColor = isRecording ? colors.destructive : colors.mint;
    final actionLabel = isRecording ? 'Tap to finish' : 'Tap to speak answer';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: isRecording ? _finishRecordingAndSubmit : _startRecording,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: btnColor.withValues(alpha: isRecording ? 0.22 : 0.12),
              border: Border.all(color: btnColor, width: 1.8),
              boxShadow: [
                BoxShadow(
                  color: btnColor.withValues(alpha: isRecording ? 0.45 : 0.2),
                  blurRadius: isRecording ? 18 : 10,
                  spreadRadius: isRecording ? 2 : 0,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Icon(
              isRecording ? FeatherIcons.square : FeatherIcons.mic,
              size: 22,
              color: btnColor,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          actionLabel,
          style: AppTypography.semiBold(11.5, color: btnColor),
        ),
      ],
    );
  }

  // ── Error View ────────────────────────────────────────────────────────────

  Widget _buildErrorView(InterviewController ic, AppColorScheme colors) {
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: colors.card,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: colors.border.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(FeatherIcons.x, size: 14, color: colors.mutedForeground),
                        const SizedBox(width: 5),
                        Text('Exit', style: AppTypography.semiBold(11, color: colors.text)),
                      ],
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: colors.destructive.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.destructive.withValues(alpha: 0.4), width: 1.5),
                ),
                child: Icon(FeatherIcons.alertTriangle, size: 26, color: colors.destructive),
              ),
              const SizedBox(height: 16),
              Text('Connection Issue', style: AppTypography.bold(18, color: colors.text)),
              const SizedBox(height: 6),
              Text(
                'Unable to reach the AI interview engine. Please verify backend connectivity.',
                style: AppTypography.regular(12, color: colors.mutedForeground),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.destructive.withValues(alpha: 0.2)),
                ),
                child: SelectableText(
                  ic.errorMessage ?? 'Unknown error occurred.',
                  style: AppTypography.regular(11, color: colors.text),
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: colors.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Exit', style: AppTypography.semiBold(13, color: colors.text)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        final rc = context.read<ResumeController>();
                        ic.startInterview(resume: rc.resume).then((_) {
                          if (mounted && ic.sessionStatus == SessionStatus.active) {
                            _speakCurrentQuestion();
                          }
                        });
                      },
                      child: Text('Retry', style: AppTypography.bold(13, color: colors.primaryForeground)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Mini Voice Wave Visualizer Bars ──────────────────────────────────────────

class _MiniVoiceWaveVisualizer extends StatelessWidget {
  final Color color;
  final Animation<double> anim;

  const _MiniVoiceWaveVisualizer({
    required this.color,
    required this.anim,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: anim,
      builder: (ctx, _) {
        final v = anim.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _bar(4 + (v * 8)),
            const SizedBox(width: 2.5),
            _bar(10 - (v * 6)),
            const SizedBox(width: 2.5),
            _bar(6 + (v * 7)),
            const SizedBox(width: 2.5),
            _bar(12 - (v * 8)),
          ],
        );
      },
    );
  }

  Widget _bar(double height) {
    return Container(
      width: 2.5,
      height: height.clamp(3.0, 14.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
