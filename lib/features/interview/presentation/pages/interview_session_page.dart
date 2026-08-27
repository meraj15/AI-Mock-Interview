import 'dart:async';
import 'dart:math' as math;
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../../core/theme/app_typography.dart';
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

  // Fake waveform bars
  final List<double> _bars = List.generate(30, (_) => 0.15);
  Timer? _barTimer;
  final _rng = math.Random();

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _pulseAnim = Tween<double>(begin: 0.88, end: 1.12)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _waveAnim = CurvedAnimation(parent: _waveCtrl, curve: Curves.linear);

    _initStt();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initTts();   // ← wait for TTS to be fully ready first
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
    super.dispose();
  }

  // ── Init helpers ──────────────────────────────────────────────────────────

  Future<void> _initTts() async {
    // Set language first — returns an integer result code on Android
    final langResult = await _tts.setLanguage('en-US');
    if (langResult != 1 && mounted) {
      // Language not available — try a fallback
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
      // Even on error — hand turn over to user so session doesn't freeze
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
          // Fallback — treat silence as empty answer, allow retry
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

    if (ic.sessionStatus == SessionStatus.loading ||
        ic.sessionStatus == SessionStatus.active) {
      // Already started from setup page — wait for questions
      if (ic.sessionStatus != SessionStatus.active &&
          ic.sessionStatus != SessionStatus.error) {
        await _waitForQuestions(ic);
      }
    } else if (ic.sessionStatus != SessionStatus.error) {
      await ic.startInterview(resume: rc.resume);
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
      // No TTS — auto-advance to user turn after a delay
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
      },
      listenFor: const Duration(minutes: 5),
      pauseFor: const Duration(seconds: 30),
      partialResults: true,
      listenOptions: stt.SpeechListenOptions(cancelOnError: false),
    );
  }

  Future<void> _stopListening() async {
    await _stt.stop();
    _stopBarAnimation();
    final answer = _transcript.isNotEmpty ? _transcript : _partialTranscript;
    if (answer.trim().isNotEmpty) {
      _submitAnswer(answer.trim());
    }
    // If empty — stay on userTurn so user can try again
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

    // Small pause then speak next question
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _speakCurrentQuestion();
    });
  }

  void _navigateToResult(InterviewController ic) {
    _tts.stop();
    _sessionTimer?.cancel();
    // Give evaluating state time to complete
    Future.delayed(const Duration(milliseconds: 800), () {
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
      Duration(milliseconds: calm ? 120 : 60),
      (_) {
        if (!mounted) return;
        setState(() {
          for (int i = 0; i < _bars.length; i++) {
            _bars[i] = calm
                ? 0.1 + _rng.nextDouble() * 0.4
                : 0.3 + _rng.nextDouble() * 0.65;
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

  // ── Exit ──────────────────────────────────────────────────────────────────

  void _exitSession() {
    _tts.stop();
    _stt.stop();
    Navigator.of(context).pop();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final ic = context.watch<InterviewController>();

    // Redirect on complete
    if (ic.sessionStatus == SessionStatus.complete && _turn != _Turn.done) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _turn = _Turn.done);
          _navigateToResult(ic);
        }
      });
    }

    // Dark immersive background
    const bg = Color(0xFF0B0F1E);
    const navyDeep = Color(0xFF131929);
    const mintGreen = Color(0xFF2DE4B6);
    const coralRed = Color(0xFFFF6B6B);
    const softWhite = Color(0xFFE8EEFF);

    final hasError = ic.sessionStatus == SessionStatus.error ||
        (ic.errorMessage != null && ic.prompts.isEmpty);

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
                          Text(
                            'Exit',
                            style: AppTypography.semiBold(11, color: Colors.white54),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: coralRed.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: coralRed.withValues(alpha: 0.4), width: 2),
                  ),
                  child: const Icon(FeatherIcons.alertTriangle, size: 34, color: coralRed),
                ),
                const SizedBox(height: 20),
                Text(
                  'AI Question Error',
                  style: AppTypography.bold(20, color: softWhite),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Failed to generate interview questions from AI. Fallback questions have been removed.',
                  style: AppTypography.regular(13, color: Colors.white60),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: navyDeep,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: coralRed.withValues(alpha: 0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(FeatherIcons.terminal, size: 13, color: coralRed),
                          const SizedBox(width: 6),
                          Text(
                            'ERROR DETAILS',
                            style: AppTypography.bold(10, color: coralRed, letterSpacing: 1.1),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SelectableText(
                        ic.errorMessage ?? 'Unknown error occurred while contacting AI service.',
                        style: AppTypography.regular(12, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _exitSession,
                        child: Text('Exit', style: AppTypography.semiBold(14, color: Colors.white70)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: mintGreen,
                          padding: const EdgeInsets.symmetric(vertical: 14),
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
                        child: Text('Retry', style: AppTypography.bold(14, color: const Color(0xFF0B0F1E))),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
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

    final displayTranscript = _transcript.isNotEmpty
        ? _transcript
        : _partialTranscript;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Exit
                  GestureDetector(
                    onTap: _exitSession,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(FeatherIcons.x, size: 14, color: Colors.white54),
                          const SizedBox(width: 5),
                          Text(
                            'Exit',
                            style: AppTypography.semiBold(11, color: Colors.white54),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Question counter
                  Column(
                    children: [
                      Text(
                        isLoading
                            ? 'Preparing…'
                            : 'Topic $questionNum of $totalQ',
                        style: AppTypography.bold(13, color: softWhite),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        category.isNotEmpty ? category : 'Interview',
                        style: AppTypography.regular(10, color: Colors.white38),
                      ),
                    ],
                  ),
                  // Elapsed timer
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(FeatherIcons.clock, size: 12, color: Colors.white38),
                        const SizedBox(width: 5),
                        Text(
                          _formatTime(_sessionElapsedSeconds),
                          style: AppTypography.semiBold(11, color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Progress bar ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 3,
                  backgroundColor: Colors.white.withValues(alpha: 0.07),
                  valueColor: const AlwaysStoppedAnimation<Color>(mintGreen),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ── Central orb ──────────────────────────────────────────
            if (isLoading)
              _LoadingOrb(pulseAnim: _pulseAnim)
            else
              _VoiceOrb(
                pulseAnim: _pulseAnim,
                isAI: isAI,
                isUser: isUser,
                isProcessing: isProcessing,
                mintGreen: mintGreen,
                coralRed: coralRed,
              ),

            const SizedBox(height: 14),

            // ── Turn label ────────────────────────────────────────────
            _TurnLabel(
              turn: _turn,
              mintGreen: mintGreen,
              coralRed: coralRed,
            ),

            const SizedBox(height: 20),

            // ── Waveform ──────────────────────────────────────────────
            if (!isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: SizedBox(
                  height: 52,
                  child: AnimatedBuilder(
                    animation: _waveAnim,
                    builder: (_, __) => CustomPaint(
                      painter: _WavePainter(
                        bars: _bars,
                        color: isUser ? coralRed : mintGreen,
                        animValue: _waveCtrl.value,
                      ),
                      size: const Size(double.infinity, 52),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // ── Question card ─────────────────────────────────────────
            if (!isLoading && question.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: navyDeep,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isAI
                          ? mintGreen.withValues(alpha: 0.35)
                          : Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: mintGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            category.toUpperCase(),
                            style: AppTypography.bold(
                              9,
                              color: mintGreen,
                              letterSpacing: 1.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        question,
                        style: AppTypography.bold(
                          16,
                          color: softWhite,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Live transcript ───────────────────────────────────────
            if (isUser && displayTranscript.isNotEmpty) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: coralRed.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: coralRed.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(FeatherIcons.mic, size: 13, color: coralRed),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          displayTranscript,
                          style: AppTypography.regular(
                            12,
                            color: Colors.white70,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const Spacer(),

            // ── Mic button ────────────────────────────────────────────
            if (!isLoading)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: _MicButton(
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
    );
  }
}

// ── Turn label ────────────────────────────────────────────────────────────────

class _TurnLabel extends StatelessWidget {
  final _Turn turn;
  final Color mintGreen;
  final Color coralRed;

  const _TurnLabel({
    required this.turn,
    required this.mintGreen,
    required this.coralRed,
  });

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (turn) {
      _Turn.loading     => ('Generating questions…', Colors.white38, FeatherIcons.loader),
      _Turn.aiSpeaking  => ('AI Interviewer is speaking', mintGreen, FeatherIcons.volume2),
      _Turn.userTurn    => ('Your turn — tap mic to answer', coralRed, FeatherIcons.mic),
      _Turn.processing  => ('Processing your answer…', Colors.white38, FeatherIcons.cpu),
      _Turn.done        => ('Session complete', mintGreen, FeatherIcons.checkCircle),
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 7),
        Text(label, style: AppTypography.semiBold(12, color: color)),
      ],
    );
  }
}

// ── Voice orb ─────────────────────────────────────────────────────────────────

class _VoiceOrb extends StatelessWidget {
  final Animation<double> pulseAnim;
  final bool isAI;
  final bool isUser;
  final bool isProcessing;
  final Color mintGreen;
  final Color coralRed;

  const _VoiceOrb({
    required this.pulseAnim,
    required this.isAI,
    required this.isUser,
    required this.isProcessing,
    required this.mintGreen,
    required this.coralRed,
  });

  @override
  Widget build(BuildContext context) {
    final color = isUser ? coralRed : mintGreen;
    final icon = isUser
        ? FeatherIcons.mic
        : isProcessing
            ? FeatherIcons.cpu
            : FeatherIcons.messageCircle;

    return ScaleTransition(
      scale: pulseAnim,
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.12),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
        ),
        alignment: Alignment.center,
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: 0.35),
                color.withValues(alpha: 0.08),
              ],
            ),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 30, color: color),
        ),
      ),
    );
  }
}

// ── Loading orb ───────────────────────────────────────────────────────────────

class _LoadingOrb extends StatelessWidget {
  final Animation<double> pulseAnim;
  const _LoadingOrb({required this.pulseAnim});

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: pulseAnim,
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.05),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        alignment: Alignment.center,
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Mic button ────────────────────────────────────────────────────────────────

class _MicButton extends StatelessWidget {
  final _Turn turn;
  final bool sttAvailable;
  final bool isListening;
  final Color mintGreen;
  final Color coralRed;
  final VoidCallback onStartListening;
  final VoidCallback onStopListening;
  final VoidCallback onSkip;

  const _MicButton({
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
      // AI speaking — show "Skip" so user can interrupt
      return GestureDetector(
        onTap: onSkip,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(FeatherIcons.skipForward, size: 15, color: Colors.white54),
              const SizedBox(width: 8),
              Text(
                'Skip — I\'ve read it',
                style: AppTypography.semiBold(13, color: Colors.white54),
              ),
            ],
          ),
        ),
      );
    }

    if (turn == _Turn.userTurn) {
      final listening = isListening;
      final label = listening ? 'Tap to stop' : 'Tap to answer';
      final color = listening ? coralRed : mintGreen;

      return Column(
        children: [
          // Large mic button
          GestureDetector(
            onTap: listening ? onStopListening : onStartListening,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: listening ? 80 : 72,
              height: listening ? 80 : 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.15),
                border: Border.all(color: color, width: 2),
                boxShadow: listening
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.35),
                          blurRadius: 24,
                          spreadRadius: 4,
                        )
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: Icon(
                listening ? FeatherIcons.square : FeatherIcons.mic,
                size: 26,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: AppTypography.semiBold(12, color: color),
          ),
        ],
      );
    }

    // Processing / done — show spinner
    return SizedBox(
      width: 24,
      height: 24,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(mintGreen),
      ),
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
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final w = size.width / bars.length;
    for (int i = 0; i < bars.length; i++) {
      final amp = bars[i] *
          (0.6 + 0.4 * math.sin(animValue * 2 * math.pi + i * 0.6));
      final h = (amp * size.height).clamp(4.0, size.height * 0.9);
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


