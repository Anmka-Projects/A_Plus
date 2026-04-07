import 'dart:io';

import 'package:flutter/foundation.dart';

import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';

/// Service for homeworks (assignments)
class HomeworksService {
  HomeworksService._();

  static final HomeworksService instance = HomeworksService._();

  /// Get course homeworks list for a given course.
  ///
  /// Uses `GET /api/courses/:courseId/homeworks` as documented in
  /// `API_DOCUMENTATION.md` section "10. الواجبات (Homework)".
  Future<List<Map<String, dynamic>>> getCourseHomeworks(
    String courseId, {
    String? lessonId,
    bool? isPublished,
  }) async {
    try {
      var url = ApiEndpoints.courseHomeworks(courseId);

      // Optional query parameters: lessonId, isPublished
      final queryParams = <String, String>{};
      if (lessonId != null && lessonId.isNotEmpty) {
        queryParams['lessonId'] = lessonId;
      }
      if (isPublished != null) {
        queryParams['isPublished'] = isPublished.toString();
      }

      if (queryParams.isNotEmpty) {
        final queryString = queryParams.entries
            .map((e) =>
                '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
            .join('&');
        url = '$url?$queryString';
      }

      final response = await ApiClient.instance.get(
        url,
        requireAuth: true,
        logTag: 'HomeworksService.getCourseHomeworks',
      );

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        if (data is List) {
          return data
              .whereType<Map<String, dynamic>>()
              .map((hw) => hw)
              .toList();
        }
        return [];
      } else {
        throw Exception(
            response['message'] ?? 'Failed to fetch course homeworks');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get homework details including questions for a student.
  ///
  /// GET /api/homeworks/:id
  Future<Map<String, dynamic>> getHomeworkDetails(String homeworkId) async {
    try {
      final response = await ApiClient.instance.get(
        '${ApiEndpoints.baseUrl}/homeworks/$homeworkId',
        requireAuth: true,
        logTag: 'HomeworksService.getHomeworkDetails',
      );

      if (response['success'] == true && response['data'] != null) {
        return Map<String, dynamic>.from(response['data'] as Map);
      }
      throw Exception(
          response['message'] ?? 'Failed to fetch homework details');
    } catch (e) {
      if (kDebugMode) {
        print('❌ HomeworksService.getHomeworkDetails error: $e');
      }
      rethrow;
    }
  }

  /// Get my submission for a homework (if exists).
  ///
  /// GET /api/homeworks/:id/my-submission
  Future<Map<String, dynamic>?> getMyHomeworkSubmission(
      String homeworkId) async {
    try {
      final response = await ApiClient.instance.get(
        '${ApiEndpoints.baseUrl}/homeworks/$homeworkId/my-submission',
        requireAuth: true,
        logTag: 'HomeworksService.getMyHomeworkSubmission',
      );

      if (response['success'] == true && response['data'] != null) {
        return Map<String, dynamic>.from(response['data'] as Map);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ HomeworksService.getMyHomeworkSubmission error: $e');
      }
      // 404 or other error – let caller decide; for now we treat as "no submission"
      return null;
    }
  }

  /// Submit or save draft for homework answers.
  ///
  /// POST /api/homeworks/:id/submit (multipart when files are attached)
  Future<Map<String, dynamic>> submitHomework(
    String homeworkId, {
    required String action,
    required List<Map<String, dynamic>> answers,
    Map<String, File>? fileAnswers,
  }) async {
    try {
      final hasFiles = fileAnswers != null && fileAnswers.isNotEmpty;

      if (!hasFiles) {
        // Simple JSON body
        final response = await ApiClient.instance.post(
          '${ApiEndpoints.baseUrl}/homeworks/$homeworkId/submit',
          body: {
            'action': action,
            'answers': answers,
          },
          requireAuth: true,
          logTag: 'HomeworksService.submitHomework',
        );

        if (response['success'] == true && response['data'] != null) {
          return Map<String, dynamic>.from(response['data'] as Map);
        }
        throw Exception(
            response['message'] ?? 'Failed to submit homework answers');
      }

      // Multipart with files
      final fields = <String, String>{
        'action': action,
        'answers': answers.map((a) => a).toList().toString(),
      };

      // Map question_id to File for multipart
      final files = <String, File>{};
      int index = 0;
      fileAnswers.forEach((questionId, file) {
        final fieldName = 'answers[$index][file]';
        files[fieldName] = file;
        index++;
      });

      final response = await ApiClient.instance.postMultipart(
        '${ApiEndpoints.baseUrl}/homeworks/$homeworkId/submit',
        fields: fields,
        files: files,
        requireAuth: true,
        logTag: 'HomeworksService.submitHomeworkMultipart',
      );

      if (response['success'] == true && response['data'] != null) {
        return Map<String, dynamic>.from(response['data'] as Map);
      }
      throw Exception(response['message'] ??
          'Failed to submit homework answers (multipart)');
    } catch (e) {
      if (kDebugMode) {
        print('❌ HomeworksService.submitHomework error: $e');
      }
      rethrow;
    }
  }
}
