import 'dart:async';
import 'dart:math' as math;
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../../core/theme/app_typography.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';
import '../../../resume/presentation/controllers/resume_controller.dart';
import '../controllers/interview_controller.dart';
import 'interview_result_page.dart';

// ── Turn state ────────────────────────────────────────────────────────────────

enum _Turn {
  loading,     // Generating questions
  aiSpeaking,  // TTS reading the question
  userTurn,    // Mic is hot — user speaks
  processing,  // Submitting answer, generating next question
  done,        // Interview finished
}

class InterviewSessionPage extends StatefulWidget {
  const InterviewSessionPage({super.key});

  @override
  State<InterviewSessionPage> createState() => _InterviewSessionPageState();
}

class _InterviewSessionPageState extends State<InterviewSessionPage>
    with TickerProviderStateMixin {

  // ── TTS ───────────────────────────────────────────────────────────────────
  final FlutterTts _tts = FlutterTts();
  bool _ttsAvailable = false;

  // ── STT ───────────────────────────────────────────────────────────────────
  final stt.SpeechToText _stt = stt.SpeechToText();
  bool _sttAvailable = false;
  String _transcript = '';
  String _partialTranscript = '';

  // ── Session state ──────────────────────────────────────────────────────────
  _Turn _turn = _Turn.loading;
  int _sessionElapsedSeconds = 0;
  Timer? _sessionTimer;

  // ── Animations ────────────────────────────────────────────────────────────
  late AnimationController _pulseCtrl;
  late AnimationController _waveCtrl;
  late Animation<double> _pulseAnim;
  late Animation<double> _waveAnim;

  // Visualizer bars
  final List<double> _bars = List.generate(24, (_) => 0.15);
  Timer? _barTimer;
  final _rng = math.Random();

  // Scroll controller for transcribed text when long
  final ScrollController _transcriptScrollCtrl = ScrollController();

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _waveAnim = CurvedAnimation(parent: _waveCtrl, curve: Curves.linear);

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
    _tts.stop();
    _stt.stop();
    _pulseCtrl.dispose();
    _waveCtrl.dispose();
    _sessionTimer?.cancel();
    _barTimer?.cancel();
    _transcriptScrollCtrl.dispose();
    super.dispose();
  }

  // ── Init helpers ──────────────────────────────────────────────────────────

  Future<void> _initTts() async {
    final langResult = await _tts.setLanguage('en-US');
    if (langResult != 1 && mounted) {
      await _tts.setLanguage('en');
    }

    await _tts.setSpeechRate(0.48);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);

    _tts.setCompletionHandler(() {
      if (mounted && _turn == _Turn.aiSpeaking) {
        _setTurn(_Turn.userTurn);
      }
    });

    _tts.setErrorHandler((msg) {
      debugPrint('TTS error: $msg');
      if (mounted && _turn == _Turn.aiSpeaking) {
        _setTurn(_Turn.userTurn);
      }
    });

    if (mounted) setState(() => _ttsAvailable = true);
  }

  Future<void> _initStt() async {
    final ok = await _stt.initialize(
      onError: (e) {
        if (mounted && _turn == _Turn.userTurn) {
          setState(() => _partialTranscript = '');
        }
      },
    );
    if (mounted) setState(() => _sttAvailable = ok);
  }

  // ── Session flow ──────────────────────────────────────────────────────────

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

    _setTurn(_Turn.aiSpeaking);
    _animateBars(calm: true);

    final speech = ic.currentAcknowledgement.isNotEmpty
        ? '${ic.currentAcknowledgement} ${ic.currentQuestion}'
        : ic.currentQuestion;

    if (_ttsAvailable) {
      _tts.speak(speech);
    } else {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && _turn == _Turn.aiSpeaking) {
          _setTurn(_Turn.userTurn);
        }
      });
    }
  }

  // ── Mic control ───────────────────────────────────────────────────────────

  Future<void> _startListening() async {
    if (!_sttAvailable || _turn != _Turn.userTurn) return;
    setState(() {
      _transcript = '';
      _partialTranscript = '';
    });
    _animateBars(calm: false);

    await _stt.listen(
      onResult: (result) {
        if (!mounted) return;
        setState(() {
          if (result.finalResult) {
            _transcript = result.recognizedWords;
            _partialTranscript = '';
          } else {
            _partialTranscript = result.recognizedWords;
          }
        });
        // Auto scroll to bottom of live transcript
        if (_transcriptScrollCtrl.hasClients) {
          _transcriptScrollCtrl.animateTo(
            _transcriptScrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
          );
        }
      },
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.dictation,
        cancelOnError: false,
        partialResults: true,
      ),
    );
  }

  Future<void> _stopListening() async {
    await _stt.stop();
    _stopBarAnimation();
    final answer = _transcript.isNotEmpty ? _transcript : _partialTranscript;
    if (answer.trim().isNotEmpty) {
      _submitAnswer(answer.trim());
    }
  }

  Future<void> _submitAnswer(String answer) async {
    final ic = context.read<InterviewController>();
    _setTurn(_Turn.processing);

    await ic.submitAnswer(answer);

    if (!mounted) return;

    if (ic.sessionStatus == SessionStatus.complete ||
        ic.sessionStatus == SessionStatus.evaluating) {
      _navigateToResult(ic);
      return;
    }

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _speakCurrentQuestion();
    });
  }

  void _navigateToResult(InterviewController ic) {
    _tts.stop();
    _sessionTimer?.cancel();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const InterviewResultPage()),
      );
    });
  }

  // ── Timers & animations ───────────────────────────────────────────────────

  void _startSessionTimer() {
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _sessionElapsedSeconds++);
    });
  }

  void _animateBars({required bool calm}) {
    _barTimer?.cancel();
    _barTimer = Timer.periodic(
      Duration(milliseconds: calm ? 100 : 50),
      (_) {
        if (!mounted) return;
        setState(() {
          for (int i = 0; i < _bars.length; i++) {
            _bars[i] = calm
                ? 0.12 + _rng.nextDouble() * 0.35
                : 0.25 + _rng.nextDouble() * 0.7;
          }
        });
      },
    );
  }

  void _stopBarAnimation() {
    _barTimer?.cancel();
    if (mounted) {
      setState(() {
        for (int i = 0; i < _bars.length; i++) {
          _bars[i] = 0.08;
        }
      });
    }
  }

  void _setTurn(_Turn t) {
    if (!mounted) return;
    setState(() => _turn = t);
  }

  String _formatTime(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  void _exitSession() {
    _tts.stop();
    _stt.stop();
    Navigator.of(context).pop();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final ic = context.watch<InterviewController>();

    if (ic.sessionStatus == SessionStatus.complete && _turn != _Turn.done) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _turn = _Turn.done);
          _navigateToResult(ic);
        }
      });
    }

    const bg = Color(0xFF090D1A);
    const cardBg = Color(0xFF111728);
    const mintGreen = Color(0xFF2DE4B6);
    const coralRed = Color(0xFFFF6B6B);
    const softWhite = Color(0xFFE8EEFF);

    final hasError = ic.sessionStatus == SessionStatus.error ||
        (ic.errorMessage != null && ic.prompts.isEmpty);

    // ── Error state ──────────────────────────────────────────────────────────
    if (hasError) {
      return Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: GestureDetector(
                    onTap: _exitSession,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(FeatherIcons.x, size: 14, color: Colors.white54),
                          const SizedBox(width: 5),
                          Text('Exit', style: AppTypography.semiBold(11, color: Colors.white54)),
                        ],
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: coralRed.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: coralRed.withValues(alpha: 0.4), width: 1.5),
                  ),
                  child: const Icon(FeatherIcons.alertTriangle, size: 28, color: coralRed),
                ),
                const SizedBox(height: 16),
                Text('AI Interview Error', style: AppTypography.bold(18, color: softWhite)),
                const SizedBox(height: 6),
                Text(
                  'Failed to connect to AI interview service. Please try again.',
                  style: AppTypography.regular(12, color: Colors.white60),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: coralRed.withValues(alpha: 0.2)),
                  ),
                  child: SelectableText(
                    ic.errorMessage ?? 'Unknown error occurred.',
                    style: AppTypography.regular(11, color: Colors.white70),
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _exitSession,
                        child: Text('Exit', style: AppTypography.semiBold(13, color: Colors.white70)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: mintGreen,
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
                        child: Text('Retry', style: AppTypography.bold(13, color: const Color(0xFF0B0F1E))),
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

    final isLoading = _turn == _Turn.loading || ic.prompts.isEmpty;
    final isAI = _turn == _Turn.aiSpeaking;
    final isUser = _turn == _Turn.userTurn;
    final isProcessing = _turn == _Turn.processing;

    final questionNum = ic.questionNumber;
    final totalQ = ic.totalQuestions;
    final progress = totalQ > 0 ? questionNum / totalQ : 0.0;
    final question = ic.currentQuestion;
    final category = ic.currentCategory;
    final acknowledgement = ic.currentAcknowledgement;

    final displayTranscript = _transcript.isNotEmpty ? _transcript : _partialTranscript;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            children: [
              const SizedBox(height: 10),

              // ── Top Bar ──────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Exit
                  GestureDetector(
                    onTap: _exitSession,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(FeatherIcons.x, size: 13, color: Colors.white54),
                          const SizedBox(width: 4),
                          Text('Exit', style: AppTypography.semiBold(11, color: Colors.white54)),
                        ],
                      ),
                    ),
                  ),

                  // Topic Header
                  Column(
                    children: [
                      Text(
                        isLoading ? 'Preparing…' : 'Topic $questionNum of $totalQ',
                        style: AppTypography.bold(12, color: softWhite),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        category.isNotEmpty ? category : 'Interview Session',
                        style: AppTypography.regular(10, color: mintGreen.withValues(alpha: 0.8)),
                      ),
                    ],
                  ),

                  // Timer Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(FeatherIcons.clock, size: 11, color: Colors.white38),
                        const SizedBox(width: 4),
                        Text(
                          _formatTime(_sessionElapsedSeconds),
                          style: AppTypography.semiBold(11, color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // ── Progress Bar ─────────────────────────────────────────
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 2.5,
                  backgroundColor: Colors.white.withValues(alpha: 0.06),
                  valueColor: const AlwaysStoppedAnimation<Color>(mintGreen),
                ),
              ),

              const SizedBox(height: 14),

              // ── Sleek Compact AI Voice Visualizer & Status Bar ──────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: cardBg.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isAI
                        ? mintGreen.withValues(alpha: 0.25)
                        : isUser
                            ? coralRed.withValues(alpha: 0.25)
                            : Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                child: Row(
                  children: [
                    // Pulse status icon
                    ScaleTransition(
                      scale: _pulseAnim,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (isUser ? coralRed : isAI ? mintGreen : Colors.white24)
                              .withValues(alpha: 0.15),
                        ),
                        child: Icon(
                          isUser
                              ? FeatherIcons.mic
                              : isAI
                                  ? FeatherIcons.volume2
                                  : isProcessing
                                      ? FeatherIcons.cpu
                                      : FeatherIcons.loader,
                          size: 13,
                          color: isUser ? coralRed : isAI ? mintGreen : Colors.white60,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Status label
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isLoading
                                ? 'AI Planning Interview…'
                                : isAI
                                    ? 'Interviewer is speaking'
                                    : isUser
                                        ? (_stt.isListening ? 'Listening to your answer…' : 'Your turn to answer')
                                        : 'Evaluating response…',
                            style: AppTypography.semiBold(
                              11,
                              color: isUser ? coralRed : isAI ? mintGreen : Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Mini waveform animation
                    if (!isLoading)
                      SizedBox(
                        width: 70,
                        height: 20,
                        child: AnimatedBuilder(
                          animation: _waveAnim,
                          builder: (_, __) => CustomPaint(
                            painter: _WavePainter(
                              bars: _bars.sublist(0, 14),
                              color: isUser ? coralRed : mintGreen,
                              animValue: _waveCtrl.value,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── Conversational Content Area (Flex-safe) ─────────────
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Question Card
                      if (!isLoading && question.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isAI
                                  ? mintGreen.withValues(alpha: 0.3)
                                  : Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: const BoxDecoration(
                                      color: mintGreen,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    category.toUpperCase(),
                                    style: AppTypography.bold(
                                      9,
                                      color: mintGreen,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                ],
                              ),
                              if (acknowledgement.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  '"$acknowledgement"',
                                  style: AppTypography.medium(
                                    11.5,
                                    color: mintGreen.withValues(alpha: 0.9),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Text(
                                question,
                                style: AppTypography.semiBold(
                                  13.5,
                                  color: softWhite,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Live User Answer Card (When user speaks or has transcribed text)
                      if (isUser && displayTranscript.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxHeight: 180),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: coralRed.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: coralRed.withValues(alpha: 0.28),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Icon(FeatherIcons.mic, size: 11, color: coralRed),
                                  const SizedBox(width: 6),
                                  Text(
                                    'YOUR LIVE ANSWER',
                                    style: AppTypography.bold(9, color: coralRed, letterSpacing: 1.0),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Flexible(
                                child: Scrollbar(
                                  controller: _transcriptScrollCtrl,
                                  thumbVisibility: true,
                                  child: SingleChildScrollView(
                                    controller: _transcriptScrollCtrl,
                                    physics: const BouncingScrollPhysics(),
                                    child: Text(
                                      displayTranscript,
                                      style: AppTypography.regular(
                                        12,
                                        color: Colors.white.withValues(alpha: 0.9),
                                        height: 1.45,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // ── Unified Bottom Control Area ──────────────────────────
              if (!isLoading)
                Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: _UnifiedBottomControls(
                    turn: _turn,
                    sttAvailable: _sttAvailable,
                    isListening: _stt.isListening,
                    mintGreen: mintGreen,
                    coralRed: coralRed,
                    onStartListening: _startListening,
                    onStopListening: _stopListening,
                    onSkip: () {
                      _tts.stop();
                      _setTurn(_Turn.userTurn);
                      _animateBars(calm: false);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Unified Bottom Controls ───────────────────────────────────────────────────

class _UnifiedBottomControls extends StatelessWidget {
  final _Turn turn;
  final bool sttAvailable;
  final bool isListening;
  final Color mintGreen;
  final Color coralRed;
  final VoidCallback onStartListening;
  final VoidCallback onStopListening;
  final VoidCallback onSkip;

  const _UnifiedBottomControls({
    required this.turn,
    required this.sttAvailable,
    required this.isListening,
    required this.mintGreen,
    required this.coralRed,
    required this.onStartListening,
    required this.onStopListening,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    if (turn == _Turn.aiSpeaking) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: onSkip,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(FeatherIcons.skipForward, size: 13, color: Colors.white70),
                  const SizedBox(width: 6),
                  Text(
                    'Skip reading',
                    style: AppTypography.semiBold(11.5, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (turn == _Turn.userTurn) {
      final listening = isListening;
      final label = listening ? 'Tap to finish answer' : 'Tap to speak answer';
      final color = listening ? coralRed : mintGreen;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: listening ? onStopListening : onStartListening,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: listening ? 64 : 58,
              height: listening ? 64 : 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.15),
                border: Border.all(color: color, width: 1.5),
                boxShadow: listening
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 18,
                          spreadRadius: 3,
                        ),
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: Icon(
                listening ? FeatherIcons.square : FeatherIcons.mic,
                size: 22,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppTypography.semiBold(11, color: color),
          ),
        ],
      );
    }

    // Processing state spinner
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(mintGreen),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Processing…',
          style: AppTypography.semiBold(11, color: Colors.white54),
        ),
      ],
    );
  }
}

// ── Waveform painter ──────────────────────────────────────────────────────────

class _WavePainter extends CustomPainter {
  final List<double> bars;
  final Color color;
  final double animValue;

  const _WavePainter({
    required this.bars,
    required this.color,
    required this.animValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (bars.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final w = size.width / bars.length;
    for (int i = 0; i < bars.length; i++) {
      final amp = bars[i] *
          (0.6 + 0.4 * math.sin(animValue * 2 * math.pi + i * 0.6));
      final h = (amp * size.height).clamp(3.0, size.height * 0.9);
      final x = w * i + w / 2;
      final cy = size.height / 2;
      canvas.drawLine(
        Offset(x, cy - h / 2),
        Offset(x, cy + h / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WavePainter old) => true;
}
