import 'dart:async';
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/progress_bar.dart';
import '../../../resume/presentation/controllers/resume_controller.dart';
import '../controllers/interview_controller.dart';
import 'interview_result_page.dart';
import 'voice_interview_page.dart';

class InterviewSessionPage extends StatefulWidget {
  const InterviewSessionPage({super.key});

  @override
  State<InterviewSessionPage> createState() => _InterviewSessionPageState();
}

class _InterviewSessionPageState extends State<InterviewSessionPage>
    with SingleTickerProviderStateMixin {
  final _answerController = TextEditingController();
  bool _voice = false;
  bool _recording = false;
  String _voiceTranscript = '';
  bool _showHintExpanded = false;

  // Per-question countdown
  Timer? _questionTimer;
  int _remainingSeconds = 0;
  bool _timerExpired = false;

  // Session total timer
  Timer? _sessionTimer;
  int _sessionElapsedSeconds = 0;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final interviewCtrl = context.read<InterviewController>();
      final resumeCtrl = context.read<ResumeController>();

      // If interview was already triggered by the setup page, just start timers
      if (interviewCtrl.sessionStatus == SessionStatus.loading ||
          interviewCtrl.sessionStatus == SessionStatus.active) {
        // Wait for loading to finish before starting timers
        void checkAndStart() {
          if (interviewCtrl.sessionStatus == SessionStatus.active) {
            _startPerQuestionTimer();
            _startSessionTimer();
          } else {
            Future.delayed(const Duration(milliseconds: 200), checkAndStart);
          }
        }
        if (interviewCtrl.sessionStatus == SessionStatus.active) {
          _startPerQuestionTimer();
          _startSessionTimer();
        } else {
          Future.delayed(const Duration(milliseconds: 200), checkAndStart);
        }
      } else {
        // Start fresh
        interviewCtrl.startInterview(resume: resumeCtrl.resume).then((_) {
          _startPerQuestionTimer();
          _startSessionTimer();
        });
      }

      // Respect voice mode from config
      if (interviewCtrl.config.enableVoiceMode) {
        setState(() => _voice = true);
      }
    });
  }

  @override
  void dispose() {
    _answerController.dispose();
    _pulseController.dispose();
    _questionTimer?.cancel();
    _sessionTimer?.cancel();
    super.dispose();
  }

  void _startPerQuestionTimer() {
    _questionTimer?.cancel();
    final interviewCtrl = context.read<InterviewController>();
    final limit = interviewCtrl.config.timeLimitPerQuestion;
    if (limit == 0) return; // No limit configured

    setState(() {
      _remainingSeconds = limit;
      _timerExpired = false;
    });

    _questionTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _timerExpired = true;
          t.cancel();
        }
      });
    });
  }

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    setState(() => _sessionElapsedSeconds = 0);
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _sessionElapsedSeconds++);
    });
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Color _timerColor(AppColorScheme colors) {
    if (_remainingSeconds <= 0) return colors.destructive;
    if (_remainingSeconds <= 20) return colors.coral;
    if (_remainingSeconds <= 60) return colors.accent;
    return colors.mint;
  }

  void _toggleVoice() {
    setState(() {
      _voice = !_voice;
      _recording = false;
      _voiceTranscript = '';
    });
  }

  void _toggleRecording() async {
    if (_recording) {
      setState(() {
        _recording = false;
        _voiceTranscript =
            'I separated the data layer from the UI by adopting Clean Architecture, making failures fully recoverable at each boundary.';
      });
    } else {
      setState(() {
        _recording = true;
        _voiceTranscript = '';
      });
      await Future.delayed(const Duration(milliseconds: 2200));
      if (mounted && _recording) {
        setState(() {
          _recording = false;
          _voiceTranscript =
              'I separated the data layer from the UI by adopting Clean Architecture, making failures fully recoverable at each boundary.';
        });
      }
    }
  }

  void _submit(InterviewController interviewCtrl) {
    final answer = _voice ? _voiceTranscript : _answerController.text.trim();
    if (answer.isEmpty) return;

    _questionTimer?.cancel();
    interviewCtrl.submitAnswer(answer);

    setState(() {
      _answerController.clear();
      _voiceTranscript = '';
      _recording = false;
      _showHintExpanded = false;
      _timerExpired = false;
    });

    // Restart per-question timer on new question
    _startPerQuestionTimer();

    if (interviewCtrl.sessionStatus == SessionStatus.complete) {
      _navigateToResult();
    }
  }

  void _navigateToResult() {
    _sessionTimer?.cancel();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const InterviewResultPage()),
    );
  }

  /// Compute a live answer quality level from 0–4
  int _answerQuality(String text) {
    final words = text.trim().split(' ').where((w) => w.isNotEmpty).length;
    if (words >= 80) return 4;
    if (words >= 50) return 3;
    if (words >= 25) return 2;
    if (words >= 10) return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorScheme.of(context);
    final interviewCtrl = context.watch<InterviewController>();
    final config = interviewCtrl.config;

    if (interviewCtrl.sessionStatus == SessionStatus.complete) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _navigateToResult());
    }

    if (interviewCtrl.sessionStatus == SessionStatus.evaluating) {
      return _buildEvaluatingScreen(colors, config);
    }

    if (interviewCtrl.sessionStatus == SessionStatus.loading ||
        interviewCtrl.prompts.isEmpty) {
      return _buildLoadingScreen(colors, config);
    }

    final isFollowUp = interviewCtrl.isFollowUp;
    final question = interviewCtrl.currentQuestion;
    final hint = interviewCtrl.currentContextHint;
    final category = interviewCtrl.currentCategory;
    final questionNum = interviewCtrl.questionNumber;
    final totalQ = interviewCtrl.totalQuestions;
    final progress = (questionNum / totalQ) * 100;

    final currentText = _voice ? _voiceTranscript : _answerController.text;
    final hasAnswer = currentText.trim().isNotEmpty;
    final isLastQuestion = questionNum >= totalQ && isFollowUp;
    final quality = _answerQuality(currentText);
    final showTimerWarning =
        _timerExpired ||
        (config.timeLimitPerQuestion > 0 &&
            _remainingSeconds <= 20 &&
            _remainingSeconds > 0);

    // Persona display
    final persona = config.aiPersona;
    final personaIcon = persona.contains('CTO')
        ? FeatherIcons.terminal
        : persona.contains('FAANG')
        ? FeatherIcons.zap
        : persona.contains('Mentor')
        ? FeatherIcons.heart
        : persona.contains('Strict')
        ? FeatherIcons.alertTriangle
        : FeatherIcons.messageCircle;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              // ── Top Bar ──────────────────────────────────────
              SizedBox(
                height: 52,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Row(
                            children: [
                              Icon(
                                FeatherIcons.x,
                                size: 18,
                                color: colors.foreground,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Exit',
                                style: AppTypography.semiBold(
                                  12,
                                  color: colors.foreground,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          config.type,
                          style: AppTypography.bold(
                            12,
                            color: colors.foreground,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isFollowUp
                              ? 'Follow-up · Q$questionNum'
                              : 'Question $questionNum of $totalQ',
                          style: AppTypography.regular(
                            10,
                            color: colors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              final prompts = interviewCtrl.prompts.map((p) => p.primaryQuestion).toList();
                              final categories = interviewCtrl.prompts.map((p) => p.category).toList();
                              final hints = interviewCtrl.prompts.map((p) => p.contextHint).toList();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => VoiceInterviewPage(
                                    config: config,
                                    questions: prompts.isNotEmpty ? prompts : ['Walk me through your system architecture.'],
                                    categories: categories.isNotEmpty ? categories : ['Architecture'],
                                    hints: hints.isNotEmpty ? hints : ['Highlight trade-offs.'],
                                  ),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: colors.mint.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(FeatherIcons.mic, size: 12, color: colors.mint),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Voice Mode',
                                    style: AppTypography.semiBold(10, color: colors.mint),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          FeatherIcons.clock,
                          size: 13,
                          color: colors.mutedForeground,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTime(_sessionElapsedSeconds),
                          style: AppTypography.semiBold(
                            12,
                            color: colors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Overall session progress bar
              ProgressBar(value: progress),
              const SizedBox(height: 6),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 22),

                      // ── AI Persona Avatar ───────────────────
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              color: colors.navy,
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: colors.navy.withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              personaIcon,
                              size: 28,
                              color: colors.mint,
                            ),
                          ),
                          Positioned(
                            right: -4,
                            top: -4,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: colors.mint,
                                border: Border.all(
                                  color: colors.background,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        persona,
                        style: AppTypography.bold(14, color: colors.foreground),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${config.role} · ${config.difficulty} mode',
                        style: AppTypography.regular(
                          10,
                          color: colors.mutedForeground,
                        ),
                      ),

                      // ── Per-Question Timer ──────────────────
                      if (config.timeLimitPerQuestion > 0) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: showTimerWarning
                                ? colors.coral.withValues(alpha: 0.15)
                                : colors.secondary,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: showTimerWarning
                                  ? colors.coral.withValues(alpha: 0.5)
                                  : colors.border,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _timerExpired
                                    ? FeatherIcons.alertCircle
                                    : FeatherIcons.clock,
                                size: 13,
                                color: _timerColor(colors),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _timerExpired
                                    ? "Time's up — submit your answer"
                                    : 'Time remaining: ${_formatTime(_remainingSeconds)}',
                                style: AppTypography.semiBold(
                                  11,
                                  color: _timerColor(colors),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // ── Question Card ───────────────────────
                      Container(
                        margin: const EdgeInsets.only(top: 16),
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: colors.card,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: colors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  isFollowUp
                                      ? 'FOLLOW-UP QUESTION'
                                      : 'QUESTION $questionNum · ${category.toUpperCase()}',
                                  style: AppTypography.bold(
                                    9,
                                    color: colors.primary,
                                    letterSpacing: 1.3,
                                  ),
                                ),
                                if (isFollowUp)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colors.accent,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Dig deeper',
                                      style: AppTypography.semiBold(
                                        9,
                                        color: colors.accentForeground,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              question,
                              style: AppTypography.bold(
                                20,
                                color: colors.foreground,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Context Hint (togglable)
                            if (config.showHints || _showHintExpanded) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 9,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.secondary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      FeatherIcons.info,
                                      size: 13,
                                      color: colors.primary,
                                    ),
                                    const SizedBox(width: 7),
                                    Expanded(
                                      child: Text(
                                        hint,
                                        style: AppTypography.regular(
                                          10,
                                          color: colors.mutedForeground,
                                          height: 1.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ] else ...[
                              // Show toggle to reveal hint
                              InkWell(
                                onTap: () =>
                                    setState(() => _showHintExpanded = true),
                                borderRadius: BorderRadius.circular(10),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      FeatherIcons.helpCircle,
                                      size: 13,
                                      color: colors.mutedForeground,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      'Show hint',
                                      style: AppTypography.semiBold(
                                        10,
                                        color: colors.mutedForeground,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      if (isFollowUp) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: colors.accent,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                FeatherIcons.checkCircle,
                                size: 14,
                                color: colors.accentForeground,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Initial answer captured. Now go one level deeper.',
                                  style: AppTypography.semiBold(
                                    10,
                                    color: colors.accentForeground,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // ── Answer Area ───────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: colors.border)),
                ),
                padding: const EdgeInsets.only(top: 14, bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Your answer',
                          style: AppTypography.bold(
                            14,
                            color: colors.foreground,
                          ),
                        ),
                        Row(
                          children: [
                            // Live answer quality indicator
                            if (!_voice && currentText.isNotEmpty) ...[
                              _QualityIndicator(
                                quality: quality,
                                colors: colors,
                              ),
                              const SizedBox(width: 8),
                            ],
                            // Voice / text toggle
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _toggleVoice,
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _voice
                                        ? colors.accent
                                        : colors.secondary,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _voice
                                            ? FeatherIcons.mic
                                            : FeatherIcons.edit3,
                                        size: 13,
                                        color: _voice
                                            ? colors.accentForeground
                                            : colors.secondaryForeground,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        _voice ? 'Voice' : 'Text',
                                        style: AppTypography.semiBold(
                                          10,
                                          color: _voice
                                              ? colors.accentForeground
                                              : colors.secondaryForeground,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (_voice) ...[
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _toggleRecording,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            height: 110,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: _recording
                                  ? colors.accent
                                  : colors.secondary,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _recording
                                    ? colors.primary.withValues(alpha: 0.4)
                                    : colors.border,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _recording
                                    ? ScaleTransition(
                                        scale: _pulseAnimation,
                                        child: Container(
                                          width: 42,
                                          height: 42,
                                          decoration: BoxDecoration(
                                            color: colors.coral,
                                            shape: BoxShape.circle,
                                          ),
                                          alignment: Alignment.center,
                                          child: Icon(
                                            FeatherIcons.square,
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                      )
                                    : Container(
                                        width: 42,
                                        height: 42,
                                        decoration: BoxDecoration(
                                          color: colors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        alignment: Alignment.center,
                                        child: Icon(
                                          FeatherIcons.mic,
                                          size: 18,
                                          color: colors.primaryForeground,
                                        ),
                                      ),
                                const SizedBox(height: 8),
                                Text(
                                  _recording
                                      ? 'AI is listening…'
                                      : _voiceTranscript.isNotEmpty
                                      ? 'Transcript ready · Tap to re-record'
                                      : 'Tap to start voice answer',
                                  style: AppTypography.semiBold(
                                    12,
                                    color: colors.foreground,
                                  ),
                                ),
                                if (_voiceTranscript.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    child: Text(
                                      _voiceTranscript,
                                      style: AppTypography.regular(
                                        9,
                                        color: colors.mutedForeground,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ] else ...[
                      AppTextField(
                        controller: _answerController,
                        placeholder: 'Type your answer here…',
                        multiline: true,
                        minLines: 3,
                        maxLines: 4,
                        onChanged: (_) => setState(() {}),
                      ),
                    ],

                    AppButton(
                      label: isLastQuestion
                          ? 'Finish interview'
                          : isFollowUp
                          ? 'Continue to next question'
                          : 'Submit answer',
                      icon: isLastQuestion
                          ? FeatherIcons.checkCircle
                          : FeatherIcons.arrowRight,
                      disabled: !hasAnswer,
                      onPress: () => _submit(interviewCtrl),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen(AppColorScheme colors, dynamic config) {
    return Scaffold(
      backgroundColor: colors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: colors.navy,
                  borderRadius: BorderRadius.circular(26),
                ),
                alignment: Alignment.center,
                child: Icon(
                  FeatherIcons.messageCircle,
                  size: 32,
                  color: colors.mint,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Preparing your interview',
                style: AppTypography.bold(22, color: colors.foreground),
              ),
              const SizedBox(height: 8),
              Text(
                'Generating ${config.questions} tailored questions\nfor ${config.role} · ${config.difficulty} mode…',
                style: AppTypography.regular(
                  13,
                  color: colors.mutedForeground,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Topics: ${config.focusTopics.take(3).join(', ')}',
                style: AppTypography.semiBold(10, color: colors.primary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEvaluatingScreen(AppColorScheme colors, dynamic config) {
    return Scaffold(
      backgroundColor: colors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: colors.accent,
                  borderRadius: BorderRadius.circular(26),
                ),
                alignment: Alignment.center,
                child: Icon(
                  FeatherIcons.award,
                  size: 32,
                  color: colors.accentForeground,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Interview complete! 🎉',
                style: AppTypography.bold(24, color: colors.foreground),
              ),
              const SizedBox(height: 8),
              Text(
                'Analyzing your ${config.questions} responses and\ngenerating your performance report…',
                style: AppTypography.regular(
                  13,
                  color: colors.mutedForeground,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Live Answer Quality Indicator ────────────────────────────────────────────

class _QualityIndicator extends StatelessWidget {
  final int quality; // 0–4
  final AppColorScheme colors;

  const _QualityIndicator({required this.quality, required this.colors});

  @override
  Widget build(BuildContext context) {
    final labels = ['Too short', 'Brief', 'Developing', 'Good', 'Strong'];
    final barColors = [
      colors.destructive,
      colors.coral,
      colors.accent,
      colors.primary,
      colors.mint,
    ];

    return Row(
      children: [
        ...List.generate(4, (i) {
          return Container(
            width: 6,
            height: i < quality ? 14 : 8,
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: BoxDecoration(
              color: i < quality ? barColors[quality] : colors.border,
              borderRadius: BorderRadius.circular(3),
            ),
          );
        }),
        const SizedBox(width: 5),
        Text(
          labels[quality],
          style: AppTypography.semiBold(9, color: barColors[quality]),
        ),
      ],
    );
  }
}
