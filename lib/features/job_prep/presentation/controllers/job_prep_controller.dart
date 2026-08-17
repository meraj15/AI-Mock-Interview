import 'package:flutter/material.dart';
import '../../../../core/services/job_description_service.dart';
import '../../../resume/domain/entities/resume_entity.dart';
import '../../domain/entities/company_profile_entity.dart';
import '../../domain/entities/job_description_entity.dart';

class JobPrepController extends ChangeNotifier {
  final JobDescriptionService _service = MockJobDescriptionService();

  List<CompanyProfileEntity> _companies = CompanyProfileEntity.defaultCompanies;
  CompanyProfileEntity _selectedCompany = CompanyProfileEntity.defaultCompanies.first;
  bool _isAnalyzing = false;
  JDAnalysisResult? _analysisResult;
  String _jdText =
      'We are looking for a Flutter Engineer to build high-performance mobile applications. You will work with Dart, Clean Architecture, REST APIs, Provider/Riverpod, offline caching with SQLite, and automated CI/CD deployment pipelines.';

  List<CompanyProfileEntity> get companies => _companies;
  CompanyProfileEntity get selectedCompany => _selectedCompany;
  bool get isAnalyzing => _isAnalyzing;
  JDAnalysisResult? get analysisResult => _analysisResult;
  String get jdText => _jdText;

  void selectCompany(CompanyProfileEntity company) {
    _selectedCompany = company;
    notifyListeners();
  }

  void updateJdText(String text) {
    _jdText = text;
    notifyListeners();
  }

  Future<void> analyzeJobDescription(ResumeEntity resume) async {
    _isAnalyzing = true;
    _analysisResult = null;
    notifyListeners();

    _analysisResult = await _service.analyzeJobDescription(
      rawText: _jdText,
      companyName: _selectedCompany.name,
      resume: resume,
    );

    _isAnalyzing = false;
    notifyListeners();
  }

  void reset() {
    _isAnalyzing = false;
    _analysisResult = null;
    notifyListeners();
  }
}
