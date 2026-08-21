import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../../../core/config/api_config.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/storage/token_storage.dart';
import '../../domain/entities/resume_entity.dart';

/// Parsed profile returned by `POST /api/resume/parse`
class ParsedResumeProfile {
  final String name;
  final String email;
  final String phone;
  final String targetRole;
  final double experienceYears;
  final List<String> skills;
  final String summary;
  final List<Map<String, dynamic>> education;
  final List<Map<String, dynamic>> projects;
  final List<Map<String, dynamic>> workExperience;
  final List<Map<String, dynamic>> certifications;

  const ParsedResumeProfile({
    required this.name,
    required this.email,
    required this.phone,
    required this.targetRole,
    required this.experienceYears,
    required this.skills,
    required this.summary,
    required this.education,
    required this.projects,
    required this.workExperience,
    required this.certifications,
  });

  factory ParsedResumeProfile.fromJson(Map<String, dynamic> json) {
    return ParsedResumeProfile(
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      targetRole: json['target_role'] as String? ?? 'Software Engineer',
      experienceYears: (json['experience_years'] as num?)?.toDouble() ?? 0.0,
      skills: (json['skills'] as List<dynamic>?)?.cast<String>() ?? [],
      summary: json['summary'] as String? ?? '',
      education: (json['education'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      projects: (json['projects'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      workExperience: (json['work_experience'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      certifications: (json['certifications'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
    );
  }

  /// Convert the parsed API response into a ResumeEntity for in-app use.
  ResumeEntity toResumeEntity({
    required String fileName,
    required String fileSize,
  }) {
    final expLabel = experienceYears == 0
        ? 'Fresher'
        : experienceYears == experienceYears.truncateToDouble()
            ? '${experienceYears.toInt()} year${experienceYears != 1 ? 's' : ''}'
            : '$experienceYears years';

    final eduLabel = education.isNotEmpty
        ? '${education.first['degree'] ?? ''}, ${education.first['institution'] ?? ''}'
        : '';

    final projectItems = projects
        .map(
          (p) => ResumeProjectItem(
            title: p['name'] as String? ?? '',
            role: 'Developer',
            description: p['description'] as String? ?? '',
            techStack: (p['technologies'] as List<dynamic>?)?.cast<String>() ?? [],
          ),
        )
        .toList();

    final workItems = workExperience
        .map(
          (w) => ResumeWorkExperience(
            company: w['company'] as String? ?? '',
            role: w['role'] as String? ?? '',
            duration: w['duration'] as String? ?? '',
            responsibilities: (w['responsibilities'] as List<dynamic>?)
                    ?.cast<String>() ??
                [],
            technologiesUsed: (w['technologies'] as List<dynamic>?)?.cast<String>() ?? [],
          ),
        )
        .toList();

    final certItems = certifications
        .map(
          (c) => ResumeCertification(
            name: c['name'] as String? ?? '',
            issuer: c['issuer'] as String? ?? '',
            issueYear: c['year']?.toString() ?? '',
          ),
        )
        .toList();

    return ResumeEntity(
      id: 'res_${DateTime.now().millisecondsSinceEpoch}',
      name: fileName,
      candidateName: name,
      email: email,
      phone: phone,
      source: ResumeSource.upload,
      status: ResumeStatus.ready,
      isDefault: true,
      uploadedDate: _formattedToday(),
      fileSize: fileSize,
      summary: summary,
      skills: skills,
      experience: expLabel,
      education: eduLabel,
      projects: projectItems.length,
      projectItems: projectItems,
      workExperiences: workItems,
      certifications: certItems,
      confidenceScore: 95,
    );
  }

  String _formattedToday() {
    final now = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }
}

abstract class ResumeRemoteDataSource {
  /// Upload a PDF/DOC file and receive a structured candidate profile back.
  Future<ParsedResumeProfile> parseResume({
    required String filePath,
    required String fileName,
    void Function(double progress)? onProgress,
  });
}

class ResumeRemoteDataSourceImpl implements ResumeRemoteDataSource {
  final TokenStorage tokenStorage;

  ResumeRemoteDataSourceImpl({required this.tokenStorage});

  @override
  Future<ParsedResumeProfile> parseResume({
    required String filePath,
    required String fileName,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final token = await tokenStorage.getAccessToken();
      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.resumeParseEndpoint}');

      final request = http.MultipartRequest('POST', uri);

      // Auth header
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Attach file
      final multipartFile = await http.MultipartFile.fromPath(
        'file', // field name expected by Node.js multer
        filePath,
        filename: fileName,
      );
      request.files.add(multipartFile);

      onProgress?.call(0.2);

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
      );

      onProgress?.call(0.7);

      final response = await http.Response.fromStream(streamedResponse);

      onProgress?.call(1.0);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        // Backend returns: { success: true, profile: { ... } }
        final profileJson = json['profile'] as Map<String, dynamic>? ?? json;
        return ParsedResumeProfile.fromJson(profileJson);
      }

      // Error response
      String message = 'Failed to parse resume (${response.statusCode})';
      try {
        final errJson = jsonDecode(response.body);
        if (errJson is Map && errJson['message'] != null) {
          message = errJson['message'] as String;
        }
      } catch (_) {}

      if (response.statusCode >= 500) {
        throw ServerException(message, null);
      }
      throw ValidationException(message);
    } on SocketException {
      throw NetworkException('No internet connection. Please check your network.');
    } on NetworkException {
      rethrow;
    } catch (e) {
      if (e is ServerException || e is ValidationException || e is NetworkException) {
        rethrow;
      }
      throw NetworkException('Upload failed: ${e.toString()}');
    }
  }
}
