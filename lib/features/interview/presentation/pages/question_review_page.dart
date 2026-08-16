import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/pill_badge.dart';
import '../../../../core/widgets/section_title.dart';
import '../controllers/interview_controller.dart';

class QuestionReviewPage extends StatefulWidget {
  const QuestionReviewPage({super.key});

  @override
  State<QuestionReviewPage> createState() => _QuestionReviewPageState();
}

class _QuestionReviewPageState extends State<QuestionReviewPage> {
  int _index = 0;

  final List<Map<String, dynamic>> _defaultQuestions = [
    {
      'q': 'Can you walk me through one Flutter project you’ve worked on?',
      'score': '8.5',
      'tone': PillTone.success,
      'answer': 'I built an OTT application where I owned the mobile architecture, state management with Provider, and worked closely with the backend team.',
      'feedback': 'Strong project framing and clear ownership. You effectively explained your technical stack.',
      'idealAnswer':
          'In my recent OTT video streaming app, I architected the app using Clean Architecture and Provider. One key challenge was seamless video playback caching during intermittent network drops, which I solved by building an offline sync repository with Hive and SQLite. This reduced video buffer latency by 35%.',
      'missing': 'Specific performance metrics and concrete architectural trade-offs.',
      'tip': 'Use the STAR format: Situation, Task, Action, and measurable Result.',
    },
    {
      'q': 'How did you handle state management in your Flutter application?',
      'score': '7.0',
      'tone': PillTone.coral,
      'answer': 'I used Provider to keep state predictable and separate from the UI layer.',
      'feedback': 'Good grasp of fundamentals, but lacked depth on lifecycle and scaling.',
      'idealAnswer':
          'I separated business logic into ChangeNotifier models, keeping UI widgets dumb and stateless. For scoped vs global state, I used proxy providers and dependency injection. If building today, I would consider Riverpod or Bloc for complex asynchronous event streams and immutable states.',
      'missing': 'Comparison with alternative state solutions (Riverpod/Bloc) and dependency injection patterns.',
      'tip': 'Explain why you chose this solution over alternatives.',
    },
    {
      'q': 'How do you handle API errors so the user never sees a broken experience?',
      'score': '8.0',
      'tone': PillTone.success,
      'answer': 'I modelled failures explicitly and gave the user a recoverable state with retry actions instead of a blank screen.',
      'feedback': 'Clear and practical answer focusing on user experience and resilience.',
      'idealAnswer':
          'I create a sealed Failure hierarchy (ServerFailure, NetworkFailure, CacheFailure) and map HTTP status codes at the DataSource layer. The presentation layer consumes these states and renders an ErrorState widget with an immediate retry CTA and offline cached data.',
      'missing': 'Production telemetry, crashlytics tracking, and automated retries with exponential backoff.',
      'tip': 'Mention production observability and crash monitoring tools.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final colors = AppColorScheme.of(context);
    final interviewCtrl = context.watch<InterviewController>();
    final history = interviewCtrl.sessionHistory;

    final total = history.isNotEmpty ? history.length : _defaultQuestions.length;
    final item = history.isNotEmpty && _index < history.length
        ? {
            'q': history[_index]['question'] ?? _defaultQuestions[_index % _defaultQuestions.length]['q'],
            'score': '8.2',
            'tone': PillTone.success,
            'answer': history[_index]['answer'] ?? _defaultQuestions[_index % _defaultQuestions.length]['answer'],
            'feedback': 'Solid response demonstrating practical experience and technical clarity.',
            'idealAnswer': _defaultQuestions[_index % _defaultQuestions.length]['idealAnswer'],
            'missing': _defaultQuestions[_index % _defaultQuestions.length]['missing'],
            'tip': _defaultQuestions[_index % _defaultQuestions.length]['tip'],
          }
        : _defaultQuestions[_index];

    return AppScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppHeader(
            title: 'Question Review',
            subtitle: 'Question ${_index + 1} of $total',
            onBack: () => Navigator.of(context).pop(),
          ),

          // Question selector chips
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: List.generate(total, (i) {
                  final isSelected = _index == i;
                  return Padding(
                    padding: const EdgeInsets.only(right: 9.0),
                    child: InkWell(
                      onTap: () => setState(() => _index = i),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isSelected ? colors.primary : colors.secondary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${i + 1}',
                          style: AppTypography.bold(
                            12,
                            color: isSelected ? colors.primaryForeground : colors.mutedForeground,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),

          // Question Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'QUESTION ${_index + 1}',
                      style: AppTypography.bold(10, color: colors.primary, letterSpacing: 1.3),
                    ),
                    PillBadge(label: 'Score: ${item['score']}/10', tone: item['tone'] as PillTone),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  item['q'] as String,
                  style: AppTypography.bold(18, color: colors.foreground, height: 1.35),
                ),
              ],
            ),
          ),

          const SectionTitle(title: 'Your Response'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.border),
            ),
            child: Text(
              item['answer'] as String,
              style: AppTypography.regular(13, color: colors.foreground, height: 1.5),
            ),
          ),

          const SectionTitle(title: 'AI Evaluation & Feedback'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.secondary,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(FeatherIcons.star, size: 17, color: colors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item['feedback'] as String,
                    style: AppTypography.regular(12, color: colors.foreground, height: 1.45),
                  ),
                ),
              ],
            ),
          ),

          const SectionTitle(title: 'Ideal Answer Example'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.border),
            ),
            child: Text(
              item['idealAnswer'] as String,
              style: AppTypography.regular(12, color: colors.foreground, height: 1.5),
            ),
          ),

          const SectionTitle(title: 'What Was Missing & Tip'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(FeatherIcons.alertCircle, size: 15, color: colors.coral),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Missing: ${item['missing']}',
                        style: AppTypography.regular(11, color: colors.foreground, height: 1.4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(FeatherIcons.zap, size: 15, color: colors.mint),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Coach Tip: ${item['tip']}',
                        style: AppTypography.regular(11, color: colors.foreground, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
