import 'dart:convert';
import 'dart:io';

import 'package:educational_app/services/home_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseCohortLibraryEnvelope', () {
    test('fixture: hierarchical subjects + unlocked book → payload & flags', () async {
      final path = '${Directory.current.path}/test/fixtures/student_cohort_library_success.json';
      final envelope =
          jsonDecode(await File(path).readAsString()) as Map<String, dynamic>;

      final payload = parseCohortLibraryEnvelope(envelope);
      expect(payload, isNotNull);
      expect(payload!.booksHasAccess, isTrue);
      expect(payload.quizzesHasAccess, isFalse);

      final subjects = payload.raw['subjects'] as List;
      expect(subjects, isNotEmpty);
      expect(subjects.first['id'], 'subj-psych');
      final groups = (subjects.first as Map<String, dynamic>)['groups'] as List;
      expect(groups.length, 2);
    });

    test('fixture: no subjects, flat books → synthetic subjects tree', () async {
      final path =
          '${Directory.current.path}/test/fixtures/student_cohort_library_flat_books_only.json';
      final envelope =
          jsonDecode(await File(path).readAsString()) as Map<String, dynamic>;

      final payload = parseCohortLibraryEnvelope(envelope);
      expect(payload, isNotNull);
      expect(payload!.booksHasAccess, isTrue);
      expect(payload.quizzesHasAccess, isFalse);

      final subjects = payload.raw['subjects'] as List<dynamic>;
      expect(subjects, isNotEmpty);
      final root = subjects.single as Map<String, dynamic>;
      expect(root['id'], '_synthetic_root');
      final groups = root['groups'] as List<dynamic>;
      final booksGroup =
          groups.cast<Map<String, dynamic>>().firstWhere((g) => g['id'] == '_synthetic_books');
      expect(booksGroup['items'], isNotEmpty);
    });

    test('success false or missing data → null', () {
      expect(parseCohortLibraryEnvelope({'success': false, 'data': {}}), isNull);
      expect(parseCohortLibraryEnvelope({'success': true}), isNull);
    });

    test('accepts unwrapped payload (no data wrapper)', () {
      final payload = parseCohortLibraryEnvelope({
        'success': true,
        'subjects': [
          {
            'id': 's1',
            'title': 'S1',
            'groups': [
              {
                'id': 'g1',
                'type': 'book',
                'items': [
                  {'id': 'i1', 'title': 'Book 1', 'is_unlocked': true}
                ]
              }
            ]
          }
        ],
        'books_has_access': true,
        'quizzes_has_access': false,
      });
      expect(payload, isNotNull);
      expect(payload!.booksHasAccess, isTrue);
      final subjects = payload.raw['subjects'] as List<dynamic>;
      expect(subjects, isNotEmpty);
    });

    test('normalizes subject books/quizzes arrays into groups', () {
      final payload = parseCohortLibraryEnvelope({
        'success': true,
        'data': {
          'subjects': [
            {
              'id': 'sub1',
              'title': 'Subject 1',
              'books': [
                {'id': 'b1', 'title': 'Book A', 'is_locked': false}
              ],
              'quizzes': [
                {'id': 'q1', 'title': 'Quiz A', 'is_locked': true}
              ]
            }
          ]
        }
      });
      expect(payload, isNotNull);
      final subjects = payload!.raw['subjects'] as List<dynamic>;
      final subject = subjects.first as Map<String, dynamic>;
      final groups = subject['groups'] as List<dynamic>;
      expect(groups.length, 2);
      final booksGroup =
          groups.cast<Map<String, dynamic>>().firstWhere((g) => g['type'] == 'book');
      final quizzesGroup =
          groups.cast<Map<String, dynamic>>().firstWhere((g) => g['type'] == 'quiz');
      expect((booksGroup['items'] as List).isNotEmpty, isTrue);
      expect((quizzesGroup['items'] as List).isNotEmpty, isTrue);
      final firstBook = (booksGroup['items'] as List).first as Map<String, dynamic>;
      final firstQuiz = (quizzesGroup['items'] as List).first as Map<String, dynamic>;
      expect(firstBook['is_unlocked'], isTrue);
      expect(firstQuiz['is_unlocked'], isFalse);
    });
  });
}
