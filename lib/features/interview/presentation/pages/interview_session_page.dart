import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/pill_badge.dart';
import '../../../../core/widgets/progress_bar.dart';
import '../../../resume/presentation/controllers/resume_controller.dart';
import '../controllers/interview_controller.dart';
import 'interview_result_page.dart';

class InterviewSessionPage extends StatefulWidget {
  const InterviewSessionPage({super.key});

  @override
  State<InterviewSessionPage> createState() => _InterviewSessionPageState();
}

class _InterviewSessionPageState extends State<InterviewSessionPage> {
  final _answerController = TextEditingController();
  int _question = 1;
  bool _voice = false;
  bool _recording = false;
  String _voiceAnswer = '';
  bool _submitted = false;
  bool _evaluating = false;

  void _record() {
    if (_recording) {
      setState(() {
        _recording = false;
        _voiceAnswer = 'I separated the data layer from the UI and made failures recoverable.';
      });
    } else {
      setState(() {
        _recording = true;
      });
    }
  }

  void _submit() {
    final interviewCtrl = context.read<InterviewController>();
    if (!_submitted) {
      setState(() {
        _submitted = true;
        _answerController.clear();
        _voiceAnswer = '';
        _recording = false;
      });
      return;
    }

    if (_question < interviewCtrl.config.questions) {
      setState(() {
        _question++;
        _submitted = false;
        _answerController.clear();
        _voiceAnswer = '';
      });
    } else {
      interviewCtrl.finishInterview();
      setState(() => _evaluating = true);
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const InterviewResultPage()),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorScheme.of(context);
    final interviewCtrl = context.watch<InterviewController>();
    final resumeCtrl = context.watch<ResumeController>();

    final resumeSkills = resumeCtrl.resume.skills.take(3).join(', ');
    final prompts = [
      {
        'primary': 'Hi Meraj. I noticed $resumeSkills on your resume. Walk me through a project where you used them together.',
        'followUp': 'You mentioned a real project. What was the most difficult technical trade-off you made?',
      },
      {
        'primary': 'How did you handle state management in your Flutter application?',
        'followUp': 'You chose Provider. Why was it the right fit, and what would you consider today?',
      },
      {
        'primary': 'How do you handle API errors so the user never sees a broken experience?',
        'followUp': 'How would you observe and debug that failure in production?',
      },
    ];

    final prompt = prompts[(_question - 1) % prompts.length];
    final currentText = _submitted ? prompt['followUp']! : prompt['primary']!;
    final canSubmit = _submitted || (_voice ? _voiceAnswer.isNotEmpty : _answerController.text.trim().isNotEmpty);

    if (_evaluating) {
      return Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: colors.accent,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    alignment: Alignment.center,
                    child: Icon(FeatherIcons.checkCircle, size: 28, color: colors.accentForeground),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Interview completed',
                    style: AppTypography.bold(26, color: colors.foreground),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    'Analyzing your performance and preparing your feedback…',
                    style: AppTypography.regular(13, color: colors.mutedForeground, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              // Top Bar
              SizedBox(
                height: 48,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      child: Row(
                        children: [
                          Icon(FeatherIcons.x, size: 20, color: colors.foreground),
                          const SizedBox(width: 7),
                          Text(
                            'Exit interview',
                            style: AppTypography.semiBold(12, color: colors.foreground),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Icon(FeatherIcons.clock, size: 14, color: colors.mutedForeground),
                        const SizedBox(width: 5),
                        Text(
                          '18:42',
                          style: AppTypography.semiBold(12, color: colors.mutedForeground),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Progress
              ProgressBar(value: (_question / interviewCtrl.config.questions) * 100),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Question $_question of ${interviewCtrl.config.questions}',
                    style: AppTypography.medium(11, color: colors.mutedForeground),
                  ),
                  PillBadge(label: interviewCtrl.config.type, tone: PillTone.muted),
                ],
              ),

              // Main Section
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      // AI Interviewer Avatar
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 74,
                            height: 74,
                            decoration: BoxDecoration(
                              color: colors.navy,
                              borderRadius: BorderRadius.circular(25),
                            ),
                            alignment: Alignment.center,
                            child: Icon(FeatherIcons.messageCircle, size: 25, color: colors.mint),
                          ),
                          Positioned(
                            right: -3,
                            top: -3,
                            child: Container(
                              width: 12,
                              height: 12,
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
                      Text(
                        'AI Interviewer',
                        style: AppTypography.bold(15, color: colors.foreground),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Resume-aware · ${interviewCtrl.config.difficulty} difficulty',
                        style: AppTypography.regular(10, color: colors.mutedForeground),
                      ),

                      // Question Card
                      Container(
                        margin: const EdgeInsets.only(top: 20),
                        padding: const EdgeInsets.all(21),
                        decoration: BoxDecoration(
                          color: colors.card,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: colors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _submitted ? 'FOLLOW-UP QUESTION' : 'QUESTION $_question',
                              style: AppTypography.bold(10, color: colors.primary, letterSpacing: 1.3),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              currentText,
                              style: AppTypography.bold(20, color: colors.foreground, height: 1.35),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              _submitted
                                  ? 'Nice start. Let’s go one level deeper.'
                                  : 'Take your time. A clear example will make your answer stronger.',
                              style: AppTypography.regular(11, color: colors.mutedForeground, height: 1.5),
                            ),
                          ],
                        ),
                      ),

                      if (_submitted) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                          decoration: BoxDecoration(
                            color: colors.accent,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Row(
                            children: [
                              Icon(FeatherIcons.checkCircle, size: 15, color: colors.accentForeground),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                  'Answer captured. The interviewer has a follow-up.',
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

              // Answer Wrap
              Container(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: colors.border, width: 1)),
                ),
                padding: const EdgeInsets.only(top: 14, bottom: 12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _submitted ? 'Your follow-up answer' : 'Your answer',
                          style: AppTypography.bold(14, color: colors.foreground),
                        ),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _voice = !_voice;
                              _recording = false;
                            });
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
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
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (_voice) ...[
                      InkWell(
                        onTap: _record,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          height: 130,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: _recording ? colors.accent : colors.secondary,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: _recording ? colors.coral : colors.primary,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  _recording ? FeatherIcons.square : FeatherIcons.mic,
                                  size: 22,
                                  color: colors.primaryForeground,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _recording
                                    ? 'AI is listening…'
                                    : _voiceAnswer.isNotEmpty
                                        ? 'Transcript ready'
                                        : 'Tap to start recording',
                                style: AppTypography.semiBold(13, color: colors.foreground),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _voiceAnswer.isNotEmpty ? _voiceAnswer : 'Your transcript will appear here',
                                style: AppTypography.regular(10, color: colors.mutedForeground),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ] else ...[
                      AppTextField(
                        controller: _answerController,
                        placeholder: 'Type your answer...',
                        multiline: true,
                        minLines: 3,
                        maxLines: 4,
                        onChanged: (_) => setState(() {}),
                      ),
                    ],

                    AppButton(
                      label: _submitted && _question == interviewCtrl.config.questions
                          ? 'Finish interview'
                          : _submitted
                              ? 'Continue interview'
                              : 'Submit answer',
                      icon: FeatherIcons.arrowRight,
                      disabled: !canSubmit,
                      onPress: _submit,
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
}
