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
  final int _timerSeconds = 1200; // 20 min

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

    // Load questions from AI service
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final interviewCtrl = context.read<InterviewController>();
      final resumeCtrl = context.read<ResumeController>();
      interviewCtrl.startInterview(resume: resumeCtrl.resume);
    });
  }

  @override
  void dispose() {
    _answerController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
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
        _voiceTranscript = 'I separated the data layer from the UI by adopting Clean Architecture, making failures fully recoverable at each boundary.';
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
          _voiceTranscript = 'I separated the data layer from the UI by adopting Clean Architecture, making failures fully recoverable at each boundary.';
        });
      }
    }
  }

  void _submit(InterviewController interviewCtrl) {
    final answer = _voice ? _voiceTranscript : _answerController.text.trim();
    if (answer.isEmpty) return;

    interviewCtrl.submitAnswer(answer);

    setState(() {
      _answerController.clear();
      _voiceTranscript = '';
      _recording = false;
    });

    if (interviewCtrl.sessionStatus.name == 'complete') {
      _navigateToResult();
    }
  }

  void _navigateToResult() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const InterviewResultPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorScheme.of(context);
    final interviewCtrl = context.watch<InterviewController>();

    // Completed → navigate to result
    if (interviewCtrl.sessionStatus.name == 'complete') {
      WidgetsBinding.instance.addPostFrameCallback((_) => _navigateToResult());
    }

    // Evaluating screen
    if (interviewCtrl.sessionStatus.name == 'evaluating') {
      return _buildEvaluatingScreen(colors);
    }

    // Loading screen while AI generates questions
    if (interviewCtrl.sessionStatus.name == 'loading' || interviewCtrl.prompts.isEmpty) {
      return _buildLoadingScreen(colors, interviewCtrl);
    }

    final isFollowUp = interviewCtrl.isFollowUp;
    final question = interviewCtrl.currentQuestion;
    final hint = interviewCtrl.currentContextHint;
    final category = interviewCtrl.currentCategory;
    final questionNum = interviewCtrl.questionNumber;
    final totalQ = interviewCtrl.totalQuestions;
    final progress = (questionNum / totalQ) * 100;

    final hasAnswer = _voice ? _voiceTranscript.isNotEmpty : _answerController.text.trim().isNotEmpty;
    final isLastQuestion = questionNum >= totalQ && isFollowUp;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              // Top Bar
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
                              Icon(FeatherIcons.x, size: 18, color: colors.foreground),
                              const SizedBox(width: 6),
                              Text('Exit', style: AppTypography.semiBold(12, color: colors.foreground)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          interviewCtrl.config.type,
                          style: AppTypography.bold(12, color: colors.foreground),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isFollowUp ? 'Follow-up · Q$questionNum' : 'Question $questionNum of $totalQ',
                          style: AppTypography.regular(10, color: colors.mutedForeground),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(FeatherIcons.clock, size: 13, color: colors.mutedForeground),
                        const SizedBox(width: 4),
                        Text(
                          _formatTime(_timerSeconds),
                          style: AppTypography.semiBold(12, color: colors.mutedForeground),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Progress Bar
              ProgressBar(value: progress),
              const SizedBox(height: 6),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 22),

                      // AI Interviewer Avatar
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
                            child: Icon(FeatherIcons.messageCircle, size: 28, color: colors.mint),
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
                                border: Border.all(color: colors.background, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text('AI Interviewer', style: AppTypography.bold(15, color: colors.foreground)),
                      const SizedBox(height: 3),
                      Text(
                        '${interviewCtrl.config.role} · ${interviewCtrl.config.difficulty} mode',
                        style: AppTypography.regular(10, color: colors.mutedForeground),
                      ),

                      // Question Card
                      Container(
                        margin: const EdgeInsets.only(top: 20),
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
                                  isFollowUp ? 'FOLLOW-UP QUESTION' : 'QUESTION $questionNum · $category',
                                  style: AppTypography.bold(9, color: colors.primary, letterSpacing: 1.3),
                                ),
                                if (isFollowUp)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: colors.accent,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Dig deeper',
                                      style: AppTypography.semiBold(9, color: colors.accentForeground),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              question,
                              style: AppTypography.bold(20, color: colors.foreground, height: 1.35),
                            ),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                              decoration: BoxDecoration(
                                color: colors.secondary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(FeatherIcons.info, size: 13, color: colors.primary),
                                  const SizedBox(width: 7),
                                  Expanded(
                                    child: Text(
                                      hint,
                                      style: AppTypography.regular(10, color: colors.mutedForeground, height: 1.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (isFollowUp) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: colors.accent,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Icon(FeatherIcons.checkCircle, size: 14, color: colors.accentForeground),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Initial answer captured. Now go one level deeper.',
                                  style: AppTypography.semiBold(10, color: colors.accentForeground),
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

              // Answer Area
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
                        Text('Your answer', style: AppTypography.bold(14, color: colors.foreground)),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _toggleVoice,
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: _voice ? colors.accent : colors.secondary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _voice ? FeatherIcons.mic : FeatherIcons.edit3,
                                    size: 13,
                                    color: _voice ? colors.accentForeground : colors.secondaryForeground,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    _voice ? 'Voice mode' : 'Text mode',
                                    style: AppTypography.semiBold(
                                      10,
                                      color: _voice ? colors.accentForeground : colors.secondaryForeground,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
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
                            height: 120,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: _recording ? colors.accent : colors.secondary,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _recording ? colors.primary.withValues(alpha: 0.4) : colors.border,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _recording
                                    ? ScaleTransition(
                                        scale: _pulseAnimation,
                                        child: Container(
                                          width: 46,
                                          height: 46,
                                          decoration: BoxDecoration(
                                            color: colors.coral,
                                            shape: BoxShape.circle,
                                          ),
                                          alignment: Alignment.center,
                                          child: Icon(FeatherIcons.square, size: 18, color: Colors.white),
                                        ),
                                      )
                                    : Container(
                                        width: 46,
                                        height: 46,
                                        decoration: BoxDecoration(
                                          color: colors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        alignment: Alignment.center,
                                        child: Icon(FeatherIcons.mic, size: 20, color: colors.primaryForeground),
                                      ),
                                const SizedBox(height: 8),
                                Text(
                                  _recording
                                      ? 'AI is listening…'
                                      : _voiceTranscript.isNotEmpty
                                          ? 'Transcript ready · Tap to re-record'
                                          : 'Tap to start voice answer',
                                  style: AppTypography.semiBold(12, color: colors.foreground),
                                ),
                                if (_voiceTranscript.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    child: Text(
                                      _voiceTranscript,
                                      style: AppTypography.regular(10, color: colors.mutedForeground),
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
                      icon: isLastQuestion ? FeatherIcons.checkCircle : FeatherIcons.arrowRight,
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

  Widget _buildLoadingScreen(AppColorScheme colors, InterviewController interviewCtrl) {
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
                child: Icon(FeatherIcons.messageCircle, size: 32, color: colors.mint),
              ),
              const SizedBox(height: 24),
              Text('Preparing your interview', style: AppTypography.bold(22, color: colors.foreground)),
              const SizedBox(height: 8),
              Text(
                'Reviewing your resume and tailoring\nquestions for ${interviewCtrl.config.role}…',
                style: AppTypography.regular(13, color: colors.mutedForeground, height: 1.5),
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

  Widget _buildEvaluatingScreen(AppColorScheme colors) {
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
                child: Icon(FeatherIcons.award, size: 32, color: colors.accentForeground),
              ),
              const SizedBox(height: 24),
              Text('Interview complete! 🎉', style: AppTypography.bold(24, color: colors.foreground)),
              const SizedBox(height: 8),
              Text(
                'Analyzing your responses and generating\nyour personalized performance report…',
                style: AppTypography.regular(13, color: colors.mutedForeground, height: 1.5),
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
