class JobDescriptionEntity {
  final String jobTitle;
  final String companyName;
  final String requiredExperience;
  final List<String> requiredSkills;
  final List<String> preferredSkills;
  final List<String> keyResponsibilities;
  final String rawText;

  const JobDescriptionEntity({
    required this.jobTitle,
    required this.companyName,
    required this.requiredExperience,
    required this.requiredSkills,
    required this.preferredSkills,
    required this.keyResponsibilities,
    required this.rawText,
  });
}

class JDAnalysisResult {
  final String jobTitle;
  final String companyName;
  final int matchScore; // e.g. 78%
  final List<String> matchedSkills;
  final List<String> skillGaps;
  final List<String> recommendedTopics;
  final List<String> preparationRoadmap;
  final List<String> customQuestions;
  final String summaryAssessment;

  const JDAnalysisResult({
    required this.jobTitle,
    required this.companyName,
    required this.matchScore,
    required this.matchedSkills,
    required this.skillGaps,
    required this.recommendedTopics,
    required this.preparationRoadmap,
    required this.customQuestions,
    required this.summaryAssessment,
  });
}
