# Backend: كتب واختبارات حسب الكلية + القسم + الفرقة (نفس المحتوى لكل الطلبة في المجموعة)

## الهدف (بالبلدي)

- كل الطلبة المسجلين بنفس **الكلية (faculty)** ونفس **القسم (section)** ونفس **الفرقة / الصف (grade)** يشوفوا **نفس قائمة الكتب** و**نفس قائمة الـ quizzes**.
- المحتوى يظهر في التطبيق **مقفول** لحد ما الـ **Admin** يفتحه من لوحة التحكم (unlock) لكل مورد أو لسياسة تختاروها انتو في الباكند.
- التطبيق (Flutter) جاهز يستدعي endpoint واحد على الـ Home؛ أول ما تنفذوا الـ API بالشكل ده، القفل/الفتح هيظهر تلقائي في الواجهة.

---

## 1) تعريف المجموعة (Cohort)

المجموعة = `(faculty_id, section_id, grade_id)` كما في مسار التسجيل:

- `GET /api/registration/faculties`
- `GET /api/registration/faculties/{facultyId}/sections`
- `GET /api/registration/sections/{sectionId}/grades`

**المطلوب:** تخزين نفس المعرفات على مستخدم الطالب (في `auth/me` أو الجدول المكافئ) بحيث السيرفر يقدر يحدد مجموعة الطالب من الـ JWT بدون ما التطبيق يبعت IDs يدويًا (يقلل التلاعب).

---

## 2) Endpoint الطالب (للـ Home — كتب واختبارات)

### `GET /api/student/cohort-library`

- **Auth:** Bearer مطلوب (طالب مسجل).
- **منطق:** من التوكن → `faculty_id`, `section_id`, `grade_id` للطالب → جلب كل الموارد المربوطة بنفس المجموعة.
- **Response 200** (مقترح — التطبيق ي parse الحقول دي):

```json
{
  "success": true,
  "data": {
    "cohort": {
      "faculty_id": "uuid-or-int",
      "section_id": "uuid-or-int",
      "grade_id": "uuid-or-int",
      "label": "طب بشري — فرقة ثالثة",
      "label_ar": "طب بشري — الفرقة الثالثة"
    },
    "books_has_access": false,
    "quizzes_has_access": false,
    "books": [
      {
        "id": "res-1",
        "title": "Anatomy PDF",
        "thumbnail": "/uploads/...",
        "is_unlocked": false,
        "file_url": null
      }
    ],
    "quizzes": [
      {
        "id": "qz-1",
        "title": "Chapter 1 quiz",
        "exam_id": "exam-uuid",
        "is_unlocked": false
      }
    ]
  }
}
```

### قواعد الحقول

| الحقل | الوصف |
|--------|--------|
| `books_has_access` | `true` لو فيه **كتاب واحد على الأقل** `is_unlocked: true` (أو لو عندكم “بوابة” عامة للكتب مفتوحة). |
| `quizzes_has_access` | `true` لو فيه **quiz واحد على الأقل** `is_unlocked: true`. |
| `books[].is_unlocked` | لو `false`: لا ترجع `file_url` (أو رجّع `null`)؛ لو `true`: رجّع رابط تحميل/عرض آمن. |
| `quizzes[].is_unlocked` | لو `false`: التطبيق يمنع بدء الامتحان؛ لو `true`: يستخدم `exam_id` مع مسارات الامتحانات الحالية. |
| الصور | مسارات نسبية كالمعتاد؛ التطبيق يكمّلها بـ base URL (نفس منطق باقي الـ API). |

### أخطاء مقترحة

| الحالة | HTTP | ملاحظة |
|--------|------|---------|
| طالب بدون faculty/section/grade | 422 | رسالة واضحة “أكمل بيانات التسجيل الأكاديمية” |
| لا يوجد محتوى للمجموعة بعد | 200 | `books` / `quizzes` مصفوفات فاضية و`has_access` = false |
| غير مصرح | 401 | |

**ملاحظة للتطبيق:** لو الـ endpoint مش متاح لسه (404) أو فشل الشبكة، الـ Home يفضل السلوك القديم (فتح الشاشات بدون قفل) عشان ما يتكسرش الإنتاج لحد ما تنشروا الـ API.

---

## 3) بديل: إدماج داخل `GET /api/home`

لو تفضلوا طلب واحد فقط:

- أضيفوا تحت `data` مفتاح `cohort_library` بنفس شكل `data` في القسم السابق.

حدّثوا التطبيق أو الـ MD لو اخترتم المسار ده بدل `/student/cohort-library` (وغيّروا الـ URL في `ApiEndpoints` على الموبايل).

---

## 4) لوحة الأدمن — فتح المحتوى (Unlock)

لازم APIs للأدمن تغيّر حالة `is_unlocked` (أو جدول `cohort_resource_unlocks`):

### أمثلة (تختاروا أسماء متوافقة مع الـ router عندكم)

- `PATCH /api/admin/cohort-resources/books/{id}` body: `{ "is_unlocked": true }`
- `PATCH /api/admin/cohort-resources/quizzes/{id}` body: `{ "is_unlocked": true }`

أو unlock بالمجموعة:

- `POST /api/admin/cohorts/{facultyId}/{sectionId}/{gradeId}/unlock-all` body اختياري لتصفية نوع المورد.

**مهم:** أي تغيير من الأدمن لازم ينعكس في الاستجابة التالية لـ `GET /api/student/cohort-library` (أو `home`) عشان التطبيق يحدّث بعد الـ pull-to-refresh.

---

## 5) نموذج بيانات مقترح (DB)

- جدول **CohortContent** يربط: `(faculty_id, section_id, grade_id)` + نوع المورد (`book` | `quiz`) + `resource_id` + `is_unlocked` + timestamps.
- أو جدول محتوى عام + pivot للمجموعات.

القرار التصميمي عندكم؛ المهم توحيد الـ JSON الظاهر للموبايل كما فوق.

---

## 6) Checklist قبول (QA)

- [ ] طالبان بنفس الثلاثي يروا نفس عدد الكتب/الـ quizzes.
- [ ] كل الموارد الجديدة تظهر `is_unlocked: false` حتى يفتحها الأدمن.
- [ ] بعد `PATCH` من الأدمن، `cohort-library` يرجع `true` للعنصر و`books_has_access` / `quizzes_has_access` يتحدثوا منطقيًا.
- [ ] طالب من مجموعة تانية لا يرى موارد مجموعة أخرى.
- [ ] `GET /api/student/cohort-library` يعمل مع نفس الـ auth middleware المستخدم في `auth/me`.

---

## 7) مرجع التطبيق (Flutter)

- المسار المتوقع حاليًا في الكود: `GET /api/student/cohort-library` (`ApiEndpoints.studentCohortLibrary`).
- عند التغيير لمسار آخر، حدّثوا `lib/core/api/api_endpoints.dart` وأرسلوا PR للموبايل.

### شجرة المواد (مادة ← مجموعات ← عناصر)

راجع: [`BACKEND_COHORT_LIBRARY_HIERARCHICAL.md`](./BACKEND_COHORT_LIBRARY_HIERARCHICAL.md) — نفس الـ endpoint مع حقل `subjects`؛ القفل على مستوى العنصر داخل الشاشة وليس على كارت الرئيسية.
