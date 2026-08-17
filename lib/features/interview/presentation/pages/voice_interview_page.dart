import 'dart:async';
import 'dart:math' as math;
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import '../../../interview/domain/entities/interview_config_entity.dart';

// ── Voice Session State Machine ──────────────────────────────────────────────

enum VoiceSessionPhase {
  aiSpeaking,    // AI is reading the question aloud
  listening,     // Candidate is speaking
  processing,    // STT processing
  thinking,      // Brief AI thinking pause before follow-up
  finished,      // Session complete
}

// ── Waveform Painter ─────────────────────────────────────────────────────────

class _WaveformPainter extends CustomPainter {
  final List<double> amplitudes;
  final Color color;
  final double animValue;

  _WaveformPainter({
    required this.amplitudes,
    required this.color,
    required this.animValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final barWidth = size.width / amplitudes.length;
    for (int i = 0; i < amplitudes.length; i++) {
      final amp = amplitudes[i] * (0.7 + 0.3 * math.sin(animValue * 2 * math.pi + i * 0.5));
      final barH = (amp * size.height * 0.8).clamp(4.0, size.height * 0.9);
      final x = barWidth * i + barWidth / 2;
      final centerY = size.height / 2;
      canvas.drawLine(
        Offset(x, centerY - barH / 2),
        Offset(x, centerY + barH / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) => true;
}

// ── Voice Interview Session Page ─────────────────────────────────────────────

class VoiceInterviewPage extends StatefulWidget {
  final InterviewConfigEntity config;
  final List<String> questions;
  final List<String> categories;
  final List<String> hints;

  const VoiceInterviewPage({
    super.key,
    required this.config,
    required this.questions,
    required this.categories,
    required this.hints,
  });

  @override
  State<VoiceInterviewPage> createState() => _VoiceInterviewPageState();
}

class _VoiceInterviewPageState extends State<VoiceInterviewPage>
    with TickerProviderStateMixin {
  // Animations
  late AnimationController _waveController;
  late AnimationController _orbController;
  late AnimationController _fadeController;
  late Animation<double> _orbScale;
  late Animation<double> _fadeAnim;

  // State
  VoiceSessionPhase _phase = VoiceSessionPhase.aiSpeaking;
  int _questionIndex = 0;
  bool _isFollowUp = false;
  String _liveTranscript = '';
  bool _transcriptStreaming = false;
  final List<String> _answers = [];
  final List<double> _waveAmplitudes = List.generate(28, (i) => 0.2);
  Timer? _waveTimer;
  Timer? _phaseTimer;
  int _aiSpeakProgress = 0; // character index for typewriter effect
  String _displayedQuestion = '';

  // Sample follow-up questions
  static const _followUps = [
    'You mentioned a structured approach. How did you validate this decision in production under real traffic?',
    'That shows strong technical instincts. Can you walk me through a failure scenario and how you recovered from it?',
    'Excellent. How would you scale this approach for a team of 10 engineers with varying experience levels?',
  ];

  // Sample voice transcripts (simulate STT)
  static const _sampleAnswers = [
    'I architected the solution using Clean Architecture with three layers — domain, data, and presentation. The domain layer had zero framework dependencies, which made it fully testable without running the app.',
    'We used Riverpod for reactive state management because it provides compile-time safety and eliminates the need for BuildContext in non-widget code. This made our business logic fully unit testable.',
    'For offline support, I implemented a local-first strategy using SQLite as the single source of truth. Sync operations were queued and replayed with exponential backoff when connectivity was restored.',
    'I reduced cold start time by 60% by lazy-loading non-critical plugins, moving heavy computation to Dart isolates, and caching serialized response models in FlutterSecureStorage.',
  ];

  @override
  void initState() {
    super.initState();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _orbScale = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _orbController, curve: Curves.easeInOut),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _fadeController.forward();
    _startAISpeakingPhase();
  }

  @override
  void dispose() {
    _waveController.dispose();
    _orbController.dispose();
    _fadeController.dispose();
    _waveTimer?.cancel();
    _phaseTimer?.cancel();
    super.dispose();
  }

  String get _currentQuestion => _isFollowUp
      ? _followUps[_questionIndex % _followUps.length]
      : widget.questions[_questionIndex];

  String get _currentCategory => widget.categories[_questionIndex];
  String get _currentHint => widget.hints[_questionIndex];

  // ── Phase Machine ──────────────────────────────────────────────────────────

  void _startAISpeakingPhase() {
    setState(() {
      _phase = VoiceSessionPhase.aiSpeaking;
      _liveTranscript = '';
      _transcriptStreaming = false;
      _aiSpeakProgress = 0;
      _displayedQuestion = '';
    });

    _stopWaveAnimation();
    _startAIWaveAnimation(calm: true);

    // Typewriter effect for displayed question
    final q = _currentQuestion;
    _phaseTimer?.cancel();
    _phaseTimer = Timer.periodic(const Duration(milliseconds: 18), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_aiSpeakProgress < q.length) {
        setState(() {
          _aiSpeakProgress++;
          _displayedQuestion = q.substring(0, _aiSpeakProgress);
        });
      } else {
        t.cancel();
        // Auto-transition to listening after question is read
        Future.delayed(const Duration(milliseconds: 900), () {
          if (mounted) _startListeningPhase();
        });
      }
    });
  }

  void _startListeningPhase() {
    setState(() {
      _phase = VoiceSessionPhase.listening;
      _liveTranscript = '';
      _transcriptStreaming = true;
    });

    _stopWaveAnimation();
    _startCandidateWaveAnimation();

    // Simulate STT streaming word by word
    final sampleAnswer = _sampleAnswers[_questionIndex % _sampleAnswers.length];
    final words = sampleAnswer.split(' ');
    int wordIndex = 0;

    _phaseTimer?.cancel();
    _phaseTimer = Timer.periodic(const Duration(milliseconds: 160), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (wordIndex < words.length) {
        setState(() => _liveTranscript = words.sublist(0, wordIndex + 1).join(' '));
        wordIndex++;
      } else {
        t.cancel();
        // Simulate candidate finishing speaking
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) _startProcessingPhase();
        });
      }
    });
  }

  void _startProcessingPhase() {
    setState(() {
      _phase = VoiceSessionPhase.processing;
      _transcriptStreaming = false;
    });
    _stopWaveAnimation();

    // Lock in the answer
    final answer = _liveTranscript;
    _answers.add(answer);

    _phaseTimer?.cancel();
    _phaseTimer = Timer(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      if (!_isFollowUp) {
        // Show follow-up
        setState(() => _isFollowUp = true);
        _startThinkingPhase();
      } else {
        _isFollowUp = false;
        _questionIndex++;
        if (_questionIndex >= widget.questions.length) {
          setState(() => _phase = VoiceSessionPhase.finished);
          _stopWaveAnimation();
        } else {
          _startThinkingPhase();
        }
      }
    });
  }

  void _startThinkingPhase() {
    setState(() => _phase = VoiceSessionPhase.thinking);
    _stopWaveAnimation();
    _startAIWaveAnimation(calm: true);

    _phaseTimer?.cancel();
    _phaseTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) _startAISpeakingPhase();
    });
  }

  void _stopCurrent() {
    _phaseTimer?.cancel();
    _waveTimer?.cancel();

    final currentAnswer = _liveTranscript.isNotEmpty
        ? _liveTranscript
        : 'Answer submitted by candidate.';
    if (_answers.length <= _questionIndex) {
      _answers.add(currentAnswer);
    }

    setState(() {
      _transcriptStreaming = false;
      _isFollowUp = false;
      _questionIndex++;
    });

    if (_questionIndex >= widget.questions.length) {
      setState(() => _phase = VoiceSessionPhase.finished);
      _stopWaveAnimation();
    } else {
      _startThinkingPhase();
    }
  }

  // ── Waveform Animations ────────────────────────────────────────────────────

  void _startAIWaveAnimation({bool calm = false}) {
    _waveTimer?.cancel();
    final rng = math.Random();
    _waveTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      if (!mounted) return;
      setState(() {
        for (int i = 0; i < _waveAmplitudes.length; i++) {
          _waveAmplitudes[i] = calm
              ? 0.15 + rng.nextDouble() * 0.35
              : 0.25 + rng.nextDouble() * 0.65;
        }
      });
    });
  }

  void _startCandidateWaveAnimation() {
    _waveTimer?.cancel();
    final rng = math.Random();
    _waveTimer = Timer.periodic(const Duration(milliseconds: 60), (_) {
      if (!mounted) return;
      setState(() {
        for (int i = 0; i < _waveAmplitudes.length; i++) {
          _waveAmplitudes[i] = 0.4 + rng.nextDouble() * 0.55;
        }
      });
    });
  }

  void _stopWaveAnimation() {
    _waveTimer?.cancel();
    if (mounted) {
      setState(() {
        for (int i = 0; i < _waveAmplitudes.length; i++) {
          _waveAmplitudes[i] = 0.1;
        }
      });
    }
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0C0E17) : const Color(0xFF0F1225);
    final navyAccent = const Color(0xFF1E2A4A);
    final mintGreen = const Color(0xFF2DE4B6);
    final coralRed = const Color(0xFFFF6B6B);
    final amberYellow = const Color(0xFFFFC047);

    final progress = (_questionIndex + (_isFollowUp ? 0.5 : 0)) / widget.questions.length;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Stack(
            children: [
              // Background radial glow
              Positioned(
                top: -100,
                left: -60,
                child: _GlowOrb(
                  color: const Color(0xFF1E6BFF).withValues(alpha: 0.18),
                  size: 320,
                ),
              ),
              Positioned(
                bottom: -80,
                right: -60,
                child: _GlowOrb(
                  color: mintGreen.withValues(alpha: 0.12),
                  size: 260,
                ),
              ),

              Column(
                children: [
                  // ── Top Bar ──────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(FeatherIcons.x, size: 14, color: Colors.white70),
                                const SizedBox(width: 6),
                                Text('Exit', style: _style(12, Colors.white70)),
                              ],
                            ),
                          ),
                        ),
                        Column(
                          children: [
                            Text(
                              'Voice Interview',
                              style: _style(13, Colors.white, bold: true),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _phase == VoiceSessionPhase.finished
                                  ? 'Session complete'
                                  : '${_isFollowUp ? 'Follow-up' : 'Q${_questionIndex + 1}'} of ${widget.questions.length}',
                              style: _style(10, Colors.white54),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            widget.config.aiPersona.split(' ').first,
                            style: _style(10, Colors.white60),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Progress bar ─────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        valueColor: AlwaysStoppedAnimation<Color>(mintGreen),
                        minHeight: 4,
                      ),
                    ),
                  ),

                  Expanded(
                    child: _phase == VoiceSessionPhase.finished
                        ? _buildFinishedView(mintGreen, context)
                        : Column(
                            children: [
                              const SizedBox(height: 28),

                              // ── Central AI Orb ────────────────────────────
                              ScaleTransition(
                                scale: _orbScale,
                                child: _buildAIOrb(
                                  mintGreen,
                                  coralRed,
                                  amberYellow,
                                  navyAccent,
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Phase label
                              _PhaseLabel(phase: _phase, mintGreen: mintGreen, amberYellow: amberYellow, coralRed: coralRed),

                              const SizedBox(height: 20),

                              // ── Waveform ──────────────────────────────────
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 40),
                                child: SizedBox(
                                  height: 56,
                                  child: AnimatedBuilder(
                                    animation: _waveController,
                                    builder: (context, child) {
                                      return CustomPaint(
                                        painter: _WaveformPainter(
                                          amplitudes: _waveAmplitudes,
                                          color: _phase == VoiceSessionPhase.listening
                                              ? coralRed
                                              : mintGreen,
                                          animValue: _waveController.value,
                                        ),
                                        size: const Size(double.infinity, 56),
                                      );
                                    },
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // ── Question / Transcript Card ────────────────
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24),
                                  child: SingleChildScrollView(
                                    physics: const BouncingScrollPhysics(),
                                    child: Column(
                                      children: [
                                        // AI Question Typewriter
                                        if (_phase == VoiceSessionPhase.aiSpeaking ||
                                            _phase == VoiceSessionPhase.thinking ||
                                            _phase == VoiceSessionPhase.listening) ...[
                                          _GlassCard(
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
                                                      _isFollowUp ? 'FOLLOW-UP' : _currentCategory.toUpperCase(),
                                                      style: _style(9, mintGreen, bold: true, spacing: 1.4),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 10),
                                                Text(
                                                  _displayedQuestion,
                                                  style: _style(16, Colors.white, bold: true, height: 1.45),
                                                ),
                                                if (_phase == VoiceSessionPhase.aiSpeaking &&
                                                    _aiSpeakProgress < _currentQuestion.length) ...[
                                                  const SizedBox(height: 6),
                                                  _BlinkingCursor(color: mintGreen),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ],

                                        // Hint Card
                                        if (_phase == VoiceSessionPhase.listening) ...[
                                          const SizedBox(height: 12),
                                          _GlassCard(
                                            opacity: 0.06,
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Icon(FeatherIcons.info, size: 13, color: Colors.white38),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    _currentHint,
                                                    style: _style(10, Colors.white54, height: 1.5),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],

                                        // Transcript live card
                                        if (_liveTranscript.isNotEmpty &&
                                            (_phase == VoiceSessionPhase.listening ||
                                                _phase == VoiceSessionPhase.processing)) ...[
                                          const SizedBox(height: 12),
                                          _GlassCard(
                                            borderColor: coralRed.withValues(alpha: 0.3),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Container(
                                                      width: 6,
                                                      height: 6,
                                                      decoration: BoxDecoration(
                                                        color: coralRed,
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      _phase == VoiceSessionPhase.processing
                                                          ? 'TRANSCRIPT CAPTURED'
                                                          : 'LIVE TRANSCRIPT',
                                                      style: _style(9, coralRed, bold: true, spacing: 1.4),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  _liveTranscript,
                                                  style: _style(13, Colors.white70, height: 1.5),
                                                ),
                                                if (_transcriptStreaming) ...[
                                                  const SizedBox(height: 4),
                                                  _BlinkingCursor(color: coralRed),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ],

                                        // Processing indicator
                                        if (_phase == VoiceSessionPhase.processing) ...[
                                          const SizedBox(height: 16),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              SizedBox(
                                                width: 14,
                                                height: 14,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor: AlwaysStoppedAnimation<Color>(amberYellow),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Text(
                                                'AI evaluating your response…',
                                                style: _style(11, amberYellow),
                                              ),
                                            ],
                                          ),
                                        ],

                                        const SizedBox(height: 24),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // ── Bottom Action Bar ─────────────────────────
                              _buildBottomBar(mintGreen, coralRed, amberYellow),
                            ],
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

  Widget _buildAIOrb(Color mint, Color coral, Color amber, Color navy) {
    final isListening = _phase == VoiceSessionPhase.listening;
    final isProcessing = _phase == VoiceSessionPhase.processing;

    final orbColor = isListening ? coral : isProcessing ? amber : mint;
    final outerGlow = orbColor.withValues(alpha: 0.2);

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: outerGlow,
      ),
      alignment: Alignment.center,
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              orbColor.withValues(alpha: 0.5),
              orbColor.withValues(alpha: 0.15),
            ],
          ),
          border: Border.all(color: orbColor.withValues(alpha: 0.6), width: 1.5),
        ),
        alignment: Alignment.center,
        child: Icon(
          isListening ? FeatherIcons.mic : isProcessing ? FeatherIcons.cpu : FeatherIcons.messageCircle,
          size: 34,
          color: orbColor,
        ),
      ),
    );
  }

  Widget _buildBottomBar(Color mint, Color coral, Color amber) {
    if (_phase == VoiceSessionPhase.aiSpeaking) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(FeatherIcons.volume2, size: 14, color: Colors.white38),
            const SizedBox(width: 6),
            Text('AI Interviewer is speaking…', style: _style(11, Colors.white38)),
          ],
        ),
      );
    }

    if (_phase == VoiceSessionPhase.listening) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _startProcessingPhase,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [coral, coral.withValues(alpha: 0.7)]),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(color: coral.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 4)),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(FeatherIcons.checkSquare, size: 16, color: Colors.white),
                      const SizedBox(width: 8),
                      Text('Done Answering', style: _style(13, Colors.white, bold: true)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _stopCurrent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(FeatherIcons.skipForward, size: 18, color: Colors.white60),
              ),
            ),
          ],
        ),
      );
    }

    if (_phase == VoiceSessionPhase.thinking || _phase == VoiceSessionPhase.processing) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(mint),
              ),
            ),
            const SizedBox(width: 10),
            Text('Preparing next question…', style: _style(11, Colors.white38)),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildFinishedView(Color mint, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: mint.withValues(alpha: 0.15),
              border: Border.all(color: mint.withValues(alpha: 0.5), width: 1.5),
            ),
            alignment: Alignment.center,
            child: Icon(FeatherIcons.checkCircle, size: 38, color: mint),
          ),
          const SizedBox(height: 24),
          Text(
            'Voice session complete!',
            style: _style(26, Colors.white, bold: true),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            '${_answers.length} responses captured. AI is now generating\nyour full performance evaluation report.',
            style: _style(13, Colors.white54, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [mint, mint.withValues(alpha: 0.7)]),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(color: mint.withValues(alpha: 0.25), blurRadius: 18, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(FeatherIcons.barChart2, size: 16, color: Colors.black87),
                  const SizedBox(width: 8),
                  Text('View Results', style: _style(14, Colors.black87, bold: true)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _style(double size, Color color, {
    bool bold = false,
    double height = 1.0,
    double spacing = 0.0,
  }) {
    return TextStyle(
      fontFamily: 'Inter',
      fontSize: size,
      color: color,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
      height: height,
      letterSpacing: spacing,
    );
  }
}

// ── Supporting Widgets ────────────────────────────────────────────────────────

class _GlowOrb extends StatelessWidget {
  final Color color;
  final double size;

  const _GlowOrb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [BoxShadow(color: color, blurRadius: 80, spreadRadius: 10)],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final Color? borderColor;
  final double opacity;

  const _GlassCard({required this.child, this.borderColor, this.opacity = 0.1});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor ?? Colors.white.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: child,
    );
  }
}

class _BlinkingCursor extends StatefulWidget {
  final Color color;
  const _BlinkingCursor({required this.color});

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _ctrl,
      child: Container(
        width: 2,
        height: 16,
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _PhaseLabel extends StatelessWidget {
  final VoiceSessionPhase phase;
  final Color mintGreen;
  final Color amberYellow;
  final Color coralRed;

  const _PhaseLabel({
    required this.phase,
    required this.mintGreen,
    required this.amberYellow,
    required this.coralRed,
  });

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (phase) {
      VoiceSessionPhase.aiSpeaking => ('AI Interviewer Speaking', mintGreen, FeatherIcons.volume2),
      VoiceSessionPhase.listening => ('Listening to your answer…', coralRed, FeatherIcons.mic),
      VoiceSessionPhase.processing => ('Processing response…', amberYellow, FeatherIcons.cpu),
      VoiceSessionPhase.thinking => ('Preparing follow-up…', mintGreen, FeatherIcons.loader),
      VoiceSessionPhase.finished => ('Session Complete', mintGreen, FeatherIcons.checkCircle),
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
