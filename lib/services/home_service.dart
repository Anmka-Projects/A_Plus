import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';

/// Parsed cohort library for home books / quizzes gating.
class CohortLibraryPayload {
  CohortLibraryPayload({
    required this.booksHasAccess,
    required this.quizzesHasAccess,
    required this.raw,
  });

  final bool booksHasAccess;
  final bool quizzesHasAccess;
  final Map<String, dynamic> raw;
}

/// Service for fetching home page data
class HomeService {
  HomeService._();

  static final HomeService instance = HomeService._();
  static const bool _useLegacyCohortFallback = false;

  /// Helper method to process course data and add base URL to images
  Map<String, dynamic> _processCourseData(Map<String, dynamic> course) {
    final processedCourse = Map<String, dynamic>.from(course);

    // Add base URL to thumbnail if it exists and is a relative path
    if (processedCourse['thumbnail'] != null) {
      processedCourse['thumbnail'] = ApiEndpoints.getImageUrl(
        processedCourse['thumbnail']?.toString(),
      );
    }

    // Add base URL to other image fields if they exist
    if (processedCourse['image'] != null) {
      processedCourse['image'] = ApiEndpoints.getImageUrl(
        processedCourse['image']?.toString(),
      );
    }

    if (processedCourse['cover_image'] != null) {
      processedCourse['cover_image'] = ApiEndpoints.getImageUrl(
        processedCourse['cover_image']?.toString(),
      );
    }

    // Process instructor avatar if exists
    if (processedCourse['instructor'] != null) {
      final instructor = processedCourse['instructor'] as Map<String, dynamic>?;
      if (instructor != null && instructor['avatar'] != null) {
        instructor['avatar'] = ApiEndpoints.getImageUrl(
          instructor['avatar']?.toString(),
        );
      }
    }

    return processedCourse;
  }

  /// Helper method to process list of courses
  List<Map<String, dynamic>> _processCoursesList(List<dynamic> courses) {
    return courses.map((course) {
      if (course is Map<String, dynamic>) {
        return _processCourseData(course);
      }
      return course as Map<String, dynamic>;
    }).toList();
  }

  /// Helper method to process category data and add base URL to images
  Map<String, dynamic> _processCategoryData(Map<String, dynamic> category) {
    final processedCategory = Map<String, dynamic>.from(category);

    // Add base URL to category image/icon if it exists
    if (processedCategory['image'] != null) {
      processedCategory['image'] = ApiEndpoints.getImageUrl(
        processedCategory['image']?.toString(),
      );
    }

    if (processedCategory['icon'] != null) {
      processedCategory['icon'] = ApiEndpoints.getImageUrl(
        processedCategory['icon']?.toString(),
      );
    }

    if (processedCategory['thumbnail'] != null) {
      processedCategory['thumbnail'] = ApiEndpoints.getImageUrl(
        processedCategory['thumbnail']?.toString(),
      );
    }

    return processedCategory;
  }

  /// Helper method to process list of categories
  List<Map<String, dynamic>> _processCategoriesList(List<dynamic> categories) {
    return categories.map((category) {
      if (category is Map<String, dynamic>) {
        return _processCategoryData(category);
      }
      return category as Map<String, dynamic>;
    }).toList();
  }

  /// Helper method to process hero banner data and add base URL to images
  Map<String, dynamic>? _processHeroBanner(Map<String, dynamic>? banner) {
    if (banner == null) return null;

    final processedBanner = Map<String, dynamic>.from(banner);

    // Add base URL to banner image if it exists
    if (processedBanner['image'] != null) {
      processedBanner['image'] = ApiEndpoints.getImageUrl(
        processedBanner['image']?.toString(),
      );
    }

    if (processedBanner['background_image'] != null) {
      processedBanner['background_image'] = ApiEndpoints.getImageUrl(
        processedBanner['background_image']?.toString(),
      );
    }

    return processedBanner;
  }

  /// Fetch home page data
  Future<Map<String, dynamic>> getHomeData() async {
    try {
      // Log request details
      if (kDebugMode) {
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('📤 HOME API REQUEST');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('Method: GET');
        print('URL: ${ApiEndpoints.home}');
        print('Require Auth: true');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      }

      final response = await ApiClient.instance.get(
        ApiEndpoints.home,
        requireAuth: true,
      );

      // Log response details
      if (kDebugMode) {
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('📥 HOME API RESPONSE');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('URL: ${ApiEndpoints.home}');
        try {
          final prettyJson =
              const JsonEncoder.withIndent('  ').convert(response);
          print('Response Body:');
          print(prettyJson);
        } catch (e) {
          print('Response: $response');
        }
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

        // Log specific data sections
        if (response['data'] != null) {
          final data = response['data'] as Map<String, dynamic>;
          print('📊 Home Data Summary:');
          print(
              '  - User Summary: ${data['user_summary'] != null ? "✓" : "✗"}');
          print('  - Hero Banner: ${data['hero_banner'] != null ? "✓" : "✗"}');
          print(
              '  - Categories Count: ${(data['categories'] as List?)?.length ?? 0}');
          print(
              '  - Featured Courses Count: ${(data['featured_courses'] as List?)?.length ?? 0}');
          print(
              '  - Popular Courses Count: ${(data['popular_courses'] as List?)?.length ?? 0}');
          print(
              '  - Continue Learning Count: ${(data['continue_learning'] as List?)?.length ?? 0}');
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        }
      }

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;
        final processedData = Map<String, dynamic>.from(data);

        // Process featured courses
        if (processedData['featured_courses'] != null) {
          final featuredCourses = processedData['featured_courses'] as List?;
          if (featuredCourses != null) {
            processedData['featured_courses'] =
                _processCoursesList(featuredCourses);
          }
        }

        // Process popular courses
        if (processedData['popular_courses'] != null) {
          final popularCourses = processedData['popular_courses'] as List?;
          if (popularCourses != null) {
            processedData['popular_courses'] =
                _processCoursesList(popularCourses);
          }
        }

        // Process continue learning courses
        if (processedData['continue_learning'] != null) {
          final continueLearning = processedData['continue_learning'] as List?;
          if (continueLearning != null) {
            processedData['continue_learning'] =
                _processCoursesList(continueLearning);
          }
        }

        // Process categories
        if (processedData['categories'] != null) {
          final categories = processedData['categories'] as List?;
          if (categories != null) {
            processedData['categories'] = _processCategoriesList(categories);
          }
        }

        // Process hero banner
        if (processedData['hero_banner'] != null) {
          final heroBanner = processedData['hero_banner'];
          if (heroBanner is Map<String, dynamic>) {
            processedData['hero_banner'] = _processHeroBanner(heroBanner);
          }
        }

        // Process user summary avatar if exists
        if (processedData['user_summary'] != null) {
          final userSummary =
              processedData['user_summary'] as Map<String, dynamic>?;
          if (userSummary != null && userSummary['avatar'] != null) {
            userSummary['avatar'] = ApiEndpoints.getImageUrl(
              userSummary['avatar']?.toString(),
            );
          }
        }

        if (kDebugMode) {
          print('✅ Home data processed - Images URLs updated');
        }

        return processedData;
      } else {
        throw Exception(response['message'] ?? 'Failed to fetch home data');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Home API Error: $e');
      }
      rethrow;
    }
  }

  /// Cohort-scoped books & quizzes (same faculty+section+grade for all students).
  /// Primary source:
  /// - GET /api/student/cohort-library
  ///
  /// Compatibility fallback (legacy aggregation path):
  /// - GET /api/enrollments
  /// - GET /api/courses/:id
  /// - GET /api/courses/:id/exams
  Future<CohortLibraryPayload?> getCohortLibrary() async {
    try {
      if (kDebugMode) {
        print('📤 COHORT LIBRARY primary GET ${ApiEndpoints.studentCohortLibrary}');
      }
      final response = await ApiClient.instance.get(
        ApiEndpoints.studentCohortLibrary,
        requireAuth: true,
        logTag: 'cohort-library',
      );
      final primary = parseCohortLibraryEnvelope(response);
      if (primary != null) return primary;

      if (kDebugMode) {
        print(
            '⚠️ cohort-library returned unexpected envelope shape; check backend response against MD contract');
      }
      if (_useLegacyCohortFallback) {
        final fromStudentContent = await _getCohortLibraryFromStudentContent();
        if (fromStudentContent != null) return fromStudentContent;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Cohort library primary failed: $e');
      }
      if (_useLegacyCohortFallback) {
        return await _getCohortLibraryFromStudentContent();
      }
      return null;
    }
  }

  Future<CohortLibraryPayload?> _getCohortLibraryFromStudentContent() async {
    try {
      final enrollmentsUrl = '${ApiEndpoints.enrollments}?status=all&page=1&per_page=50';
      if (kDebugMode) {
        print('📤 STUDENT CONTENT enrollments GET $enrollmentsUrl');
      }

      final enrollmentsResp = await ApiClient.instance.get(
        enrollmentsUrl,
        requireAuth: true,
        logTag: 'cohort-library',
      );
      if (enrollmentsResp['success'] != true || enrollmentsResp['data'] == null) {
        return null;
      }

      final rows = _extractEnrollmentRows(enrollmentsResp['data']);
      if (rows.isEmpty) {
        return parseCohortLibraryEnvelope({
          'success': true,
          'data': <String, dynamic>{
            'subjects': <dynamic>[],
            'books': <dynamic>[],
            'quizzes': <dynamic>[],
            'books_has_access': false,
            'quizzes_has_access': false,
          },
        });
      }

      final subjects = <Map<String, dynamic>>[];
      final flatBooks = <Map<String, dynamic>>[];
      final flatQuizzes = <Map<String, dynamic>>[];

      for (final row in rows) {
        final course = _courseFromEnrollmentRow(row);
        final courseId = course['id']?.toString();
        if (courseId == null || courseId.isEmpty) continue;

        final details = await ApiClient.instance.get(
          ApiEndpoints.course(courseId),
          requireAuth: true,
          logTag: 'cohort-library',
        );
        final detailsData = details['data'] is Map
            ? Map<String, dynamic>.from(details['data'] as Map)
            : <String, dynamic>{};

        final subjectTitle = detailsData['title_ar']?.toString().isNotEmpty == true
            ? detailsData['title_ar'].toString()
            : (detailsData['title']?.toString().isNotEmpty == true
                ? detailsData['title'].toString()
                : (course['title']?.toString() ?? 'Course'));

        final lessonItems = _extractBookLikeItemsFromCourse(detailsData);

        final examsResp = await ApiClient.instance.get(
          ApiEndpoints.courseExams(courseId),
          requireAuth: true,
          logTag: 'cohort-library',
        );
        final quizItems = _extractQuizItemsFromExams(examsResp['data'], courseId);

        flatBooks.addAll(lessonItems);
        flatQuizzes.addAll(quizItems);

        final groups = <Map<String, dynamic>>[];
        if (lessonItems.isNotEmpty) {
          groups.add({
            'id': '${courseId}_books',
            'type': 'book',
            'label': 'Books',
            'label_ar': 'كتب',
            'items': lessonItems,
          });
        }
        if (quizItems.isNotEmpty) {
          groups.add({
            'id': '${courseId}_quizzes',
            'type': 'quiz',
            'label': 'Quizzes',
            'label_ar': 'اختبارات',
            'items': quizItems,
          });
        }
        if (groups.isNotEmpty) {
          subjects.add({
            'id': courseId,
            'title': detailsData['title'] ?? subjectTitle,
            'title_ar': detailsData['title_ar'] ?? subjectTitle,
            'groups': groups,
          });
        }
      }

      return parseCohortLibraryEnvelope({
        'success': true,
        'data': <String, dynamic>{
          'subjects': subjects,
          'books': flatBooks,
          'quizzes': flatQuizzes,
          'books_has_access': flatBooks.any((b) => _coerceBool(b['is_unlocked'])),
          'quizzes_has_access':
              flatQuizzes.any((q) => _coerceBool(q['is_unlocked'])),
        },
      });
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Student-content aggregation unavailable: $e');
      }
      return null;
    }
  }

  static List<Map<String, dynamic>> _extractEnrollmentRows(dynamic data) {
    if (data is List) {
      return data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    if (data is Map<String, dynamic>) {
      final src = data['courses'] ?? data['enrollments'] ?? data['data'];
      if (src is List) {
        return src
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    }
    return <Map<String, dynamic>>[];
  }

  static Map<String, dynamic> _courseFromEnrollmentRow(
      Map<String, dynamic> row) {
    final nested = row['course'];
    if (nested is Map) {
      return Map<String, dynamic>.from(nested);
    }
    return Map<String, dynamic>.from(row);
  }

  static List<Map<String, dynamic>> _extractBookLikeItemsFromCourse(
      Map<String, dynamic> courseData) {
    final out = <Map<String, dynamic>>[];
    final curriculum = courseData['curriculum'];
    if (curriculum is! List) return out;

    for (final sec in curriculum) {
      if (sec is! Map) continue;
      final section = Map<String, dynamic>.from(sec);
      final lessons = section['lessons'];
      if (lessons is! List) continue;

      for (final l in lessons) {
        if (l is! Map) continue;
        final lesson = Map<String, dynamic>.from(l);
        final type = (lesson['type'] ?? '').toString().toLowerCase();
        final isBookLike =
            type == 'book' || type == 'file' || type == 'summary' || type == 'pdf';
        if (!isBookLike) continue;

        out.add({
          'id': lesson['id']?.toString() ?? '',
          'title': lesson['title']?.toString() ?? '',
          'title_ar': lesson['title_ar']?.toString(),
          'type': type.isEmpty ? 'book' : type,
          'is_unlocked': !(lesson['is_locked'] == true),
          'file_url': lesson['content_pdf_url'] ?? lesson['file_url'],
          'thumbnail': lesson['thumbnail'] ?? lesson['cover_image'],
          'course_id': courseData['id']?.toString(),
        });
      }
    }
    return out;
  }

  static List<Map<String, dynamic>> _extractQuizItemsFromExams(
      dynamic examsData, String courseId) {
    if (examsData is! List) return <Map<String, dynamic>>[];
    return examsData.whereType<Map>().map((e) {
      final exam = Map<String, dynamic>.from(e);
      return <String, dynamic>{
        'id': exam['id']?.toString() ?? '',
        'title': exam['title']?.toString() ?? '',
        'title_ar': exam['title_ar']?.toString(),
        'type': 'quiz',
        'is_unlocked': _coerceBool(exam['can_start']) || !_coerceBool(exam['is_locked']),
        'exam_id': exam['id']?.toString(),
        'course_id': courseId,
      };
    }).toList();
  }

  static bool _coerceBool(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final s = v.toLowerCase();
      return s == 'true' || s == '1' || s == 'yes';
    }
    return false;
  }

  static bool _listHasUnlocked(dynamic list) {
    if (list is! List) return false;
    for (final item in list) {
      if (item is Map && _coerceBool(item['is_unlocked'])) {
        return true;
      }
    }
    return false;
  }

  /// Ensures [data] has [subjects] for hierarchical UI; mutates [data] in place.
  static void _ensureSubjectsTree(Map<String, dynamic> data) {
    _normalizeSubjectsTree(data);
    final subs = data['subjects'];
    if (subs is! List || subs.isEmpty) {
      data['subjects'] = _buildSyntheticSubjects(data);
    }
    _processSubjectTreeImages(data['subjects']);
  }

  static void _normalizeSubjectsTree(Map<String, dynamic> data) {
    final subjects = data['subjects'];
    if (subjects is! List) return;
    final normalizedSubjects = <Map<String, dynamic>>[];
    for (final s in subjects) {
      if (s is! Map) continue;
      final subject = Map<String, dynamic>.from(s);
      final groups = subject['groups'];
      if (groups is List && groups.isNotEmpty) {
        subject['groups'] = _normalizeGroups(groups);
        normalizedSubjects.add(subject);
        continue;
      }

      // Backward/variant contract: subjects may contain direct `books`/`quizzes`
      // arrays instead of nested `groups`.
      final syntheticGroups = <Map<String, dynamic>>[];
      final books = _mapListFromDynamic(subject['books']);
      final quizzes = _mapListFromDynamic(subject['quizzes']);
      final assignments = _mapListFromDynamic(subject['assignments']);
      final genericItems = _mapListFromDynamic(subject['items']);

      if (books.isNotEmpty) {
        syntheticGroups.add({
          'id': '${subject['id']}_books',
          'type': 'book',
          'label': 'Books',
          'label_ar': 'كتب',
          'items': books,
        });
      }
      if (quizzes.isNotEmpty) {
        syntheticGroups.add({
          'id': '${subject['id']}_quizzes',
          'type': 'quiz',
          'label': 'Quizzes',
          'label_ar': 'اختبارات',
          'items': quizzes,
        });
      }
      if (assignments.isNotEmpty) {
        syntheticGroups.add({
          'id': '${subject['id']}_assignments',
          'type': 'assignment',
          'label': 'Assignments',
          'label_ar': 'تكليفات',
          'items': assignments,
        });
      }
      if (genericItems.isNotEmpty && syntheticGroups.isEmpty) {
        syntheticGroups.add({
          'id': '${subject['id']}_items',
          'type': 'book',
          'label': 'Items',
          'label_ar': 'محتوى',
          'items': genericItems,
        });
      }

      if (syntheticGroups.isNotEmpty) {
        subject['groups'] = _normalizeGroups(syntheticGroups);
      }
      normalizedSubjects.add(subject);
    }
    data['subjects'] = normalizedSubjects;
  }

  static List<Map<String, dynamic>> _normalizeGroups(List groups) {
    final out = <Map<String, dynamic>>[];
    for (final g in groups) {
      if (g is! Map) continue;
      final group = Map<String, dynamic>.from(g);
      group['items'] = _normalizeGroupItems(group);
      if ((group['type']?.toString().trim().isEmpty ?? true)) {
        final hint = '${group['label'] ?? group['id'] ?? ''}'.toLowerCase();
        if (hint.contains('quiz') || hint.contains('exam')) {
          group['type'] = 'quiz';
        } else if (hint.contains('assignment')) {
          group['type'] = 'assignment';
        } else {
          group['type'] = 'book';
        }
      }
      out.add(group);
    }
    return out;
  }

  static List<Map<String, dynamic>> _normalizeGroupItems(
      Map<String, dynamic> group) {
    final variants = <dynamic>[
      group['items'],
      group['contents'],
      group['lessons'],
      group['data'],
      group['books'],
      group['quizzes'],
    ];
    for (final src in variants) {
      if (src is List) {
        final list = _mapListFromDynamic(src);
        for (final item in list) {
          if (item['is_unlocked'] == null && item['is_locked'] != null) {
            item['is_unlocked'] = !_coerceBool(item['is_locked']);
          }
        }
        return list;
      }
    }
    return <Map<String, dynamic>>[];
  }

  static List<Map<String, dynamic>> _buildSyntheticSubjects(
      Map<String, dynamic> data) {
    final books = _mapListFromDynamic(data['books']);
    final quizzes = _mapListFromDynamic(data['quizzes']);
    final groups = <Map<String, dynamic>>[];
    if (books.isNotEmpty) {
      groups.add({
        'id': '_synthetic_books',
        'type': 'book',
        'items': books,
      });
    }
    if (quizzes.isNotEmpty) {
      groups.add({
        'id': '_synthetic_quizzes',
        'type': 'quiz',
        'items': quizzes,
      });
    }
    if (groups.isEmpty) return [];
    return [
      {
        'id': '_synthetic_root',
        'title': null,
        'title_ar': null,
        'groups': groups,
      },
    ];
  }

  static List<Map<String, dynamic>> _mapListFromDynamic(dynamic v) {
    if (v is! List) return [];
    final out = <Map<String, dynamic>>[];
    for (final e in v) {
      if (e is Map<String, dynamic>) {
        out.add(Map<String, dynamic>.from(e));
      } else if (e is Map) {
        out.add(Map<String, dynamic>.from(e));
      }
    }
    return out;
  }

  static void _processSubjectTreeImages(dynamic subjects) {
    if (subjects is! List) return;
    for (final s in subjects) {
      if (s is! Map) continue;
      final sm = Map<String, dynamic>.from(s);
      final groups = sm['groups'];
      if (groups is! List) continue;
      for (final g in groups) {
        if (g is! Map) continue;
        final gm = Map<String, dynamic>.from(g);
        final items = gm['items'];
        if (items is! List) continue;
        for (var i = 0; i < items.length; i++) {
          final it = items[i];
          if (it is! Map) continue;
          final m = Map<String, dynamic>.from(it);
          for (final key in ['thumbnail', 'cover_image']) {
            if (m[key] != null) {
              m[key] = ApiEndpoints.getImageUrl(m[key]?.toString());
            }
          }
          items[i] = m;
        }
      }
    }
  }
}

/// Parses the JSON envelope from `GET …/student/cohort-library` after [ApiClient] decodes it.
///
/// Used by [HomeService.getCohortLibrary] and by unit tests with fixture files.
CohortLibraryPayload? parseCohortLibraryEnvelope(Map<String, dynamic> response) {
  bool isExplicitFailure(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value == false;
    if (value is num) return value == 0;
    if (value is String) {
      final s = value.toLowerCase().trim();
      return s == 'false' || s == '0' || s == 'fail' || s == 'error';
    }
    return false;
  }

  if (isExplicitFailure(response['success'])) {
    return null;
  }

  Map<String, dynamic>? body;
  if (response['data'] is Map) {
    body = Map<String, dynamic>.from(response['data'] as Map);
  } else if (response['subjects'] != null ||
      response['books'] != null ||
      response['quizzes'] != null) {
    // Some backends return the payload directly without wrapping in `data`.
    body = Map<String, dynamic>.from(response);
  }
  if (body == null) return null;
  final data = body;

  void processBook(Map<String, dynamic> b) {
    for (final key in ['thumbnail', 'cover_image']) {
      if (b[key] != null) {
        b[key] = ApiEndpoints.getImageUrl(b[key]?.toString());
      }
    }
  }

  if (data['books'] is List) {
    data['books'] = (data['books'] as List).map((e) {
      if (e is Map<String, dynamic>) {
        final m = Map<String, dynamic>.from(e);
        if (m['is_unlocked'] == null && m['is_locked'] != null) {
          m['is_unlocked'] = !HomeService._coerceBool(m['is_locked']);
        }
        processBook(m);
        return m;
      }
      if (e is Map) {
        final m = Map<String, dynamic>.from(e);
        if (m['is_unlocked'] == null && m['is_locked'] != null) {
          m['is_unlocked'] = !HomeService._coerceBool(m['is_locked']);
        }
        processBook(m);
        return m;
      }
      return e;
    }).toList();
  }

  if (data['quizzes'] is List) {
    data['quizzes'] = (data['quizzes'] as List).map((e) {
      if (e is Map) {
        final m = Map<String, dynamic>.from(e);
        if (m['is_unlocked'] == null && m['is_locked'] != null) {
          m['is_unlocked'] = !HomeService._coerceBool(m['is_locked']);
        }
        return m;
      }
      return e;
    }).toList();
  }

  HomeService._ensureSubjectsTree(data);

  final booksHas = HomeService._coerceBool(data['books_has_access']) ||
      HomeService._listHasUnlocked(data['books']);
  final quizzesHas = HomeService._coerceBool(data['quizzes_has_access']) ||
      HomeService._listHasUnlocked(data['quizzes']);

  return CohortLibraryPayload(
    booksHasAccess: booksHas,
    quizzesHasAccess: quizzesHas,
    raw: data,
  );
}
