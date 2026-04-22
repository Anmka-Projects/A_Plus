# Home Screen Books & Quizzes - Backend Contract

## Goal
Support Home buttons (`Books` and `Quizzes`) with cohort-scoped content:
- Same content for students in the same `faculty + section + grade`
- Content is **locked by default**
- Admin can unlock/lock items from dashboard at any time

This must power:
- `Books` button on home
- `Quizzes` button on home

## Endpoint (Primary)
`GET /api/student/cohort-library`

### Auth
- Required (student token)
- Flutter sends: `Authorization: Bearer <accessToken>`

## Expected Response Shape
```json
{
  "success": true,
  "data": {
    "books_has_access": true,
    "quizzes_has_access": false,
    "subjects": [
      {
        "id": "subject_1",
        "title": "Anatomy",
        "title_ar": "تشريح",
        "groups": [
          {
            "id": "books_group_1",
            "type": "book",
            "label": "Books",
            "label_ar": "كتب",
            "items": [
              {
                "id": "item_1",
                "title": "Upper Limb",
                "title_ar": "الطرف العلوي",
                "type": "book",
                "is_unlocked": false,
                "file_url": "https://.../file.pdf",
                "thumbnail": "/uploads/..."
              }
            ]
          },
          {
            "id": "quizzes_group_1",
            "type": "quiz",
            "label": "Quizzes",
            "label_ar": "اختبارات",
            "items": [
              {
                "id": "quiz_1",
                "title": "Quiz 1",
                "title_ar": "اختبار 1",
                "type": "quiz",
                "is_unlocked": false,
                "exam_id": "123"
              }
            ]
          }
        ]
      }
    ],
    "books": [],
    "quizzes": []
  }
}
```

## Required Behavior Rules
1. Scope by student cohort (`faculty/section/grade`) only.
2. Return only content assigned to that cohort.
3. Every item includes `is_unlocked`:
   - `false` => locked for students
   - `true` => open for students
4. Admin dashboard can toggle lock state per item.
5. Keep response stable even if no content:
   - return empty lists, not null
6. For quiz items, include `exam_id`.
7. For file/book items, include `file_url` when available.

## Flutter Consumption Rules (Implemented)
- Home `Books` and `Quizzes` both open cohort library screen.
- Flutter now uses `/api/student/cohort-library` as **primary source**.
- UI filters:
  - Books tab => non-quiz groups (`book`, `summary`, `file`, etc.)
  - Quizzes tab => quiz/exam groups (+ assignment if backend returns it)
- Locked item (`is_unlocked=false`) shows lock and cannot open.

## Notes for Backend
- Authentication middleware now supports flexible token formats, but preferred format remains:
  - `Authorization: Bearer <accessToken>`
- Please keep Arabic/English titles where possible (`title`, `title_ar`, `label`, `label_ar`) for UI localization.

