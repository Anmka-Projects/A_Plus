# Backend: مكتبة الطالب الهرمية (مادة ← نوع محتوى ← عناصر) — قفل داخلي لكل عنصر

## الهدف (بالعربي)

- بعد ما الطالب يدخل **الكتب** أو **الاختبارات والواجبات** من الرئيسية، المحتوى يكون **متفرّع زي dropdown / accordion**:
  1. **المادة** (مثلاً علم النفس)  
  2. جوّاها **أنواع** (تلخيصات، كتب، ملفات، …)  
  3. جوّا كل نوع **قائمة عناصر**؛ كل عنصر له حالة قفل منفصلة.
- **القفل من جوّا فقط:** ما فيش قفل على مستوى كارت الرئيسية كامل؛ الطالب يقدر يفتح الشجرة ويشوف العناوين، لكن **التحميل / بدء الاختبار** يشتغل بس للعناصر اللي `is_unlocked: true` (الأدمن يفتحها من الـ dashboard).
- التطبيق ي parse نفس الـ endpoint الموصوف هنا (أو امتداد لـ `GET /api/student/cohort-library`). راجع أيضاً [`BACKEND_HOME_COHORT_BOOKS_QUIZZES.md`](./BACKEND_HOME_COHORT_BOOKS_QUIZZES.md) للسياق العام (نفس الـ cohort).

---

## 1) الـ endpoint (طالب)

**مقترح:** توسيع نفس المسار الحالي:

`GET /api/student/cohort-library`

- **Auth:** Bearer (طالب).
- **Cohort:** يُستنتج من المستخدم (كلية + قسم + فرقة) كما في الوثيقة السابقة.

### شكل الاستجابة المفضل (شجرة + توافق للخلف)

أضف مفتاح **`subjects`** (مصفوفة). إذا غاب، التطبيق يبني شجرة مؤقتة من `books` / `quizzes` المسطحين؛ لكن الأفضل أن السيرفر يرسل **`subjects`** جاهزة.

```json
{
  "success": true,
  "data": {
    "cohort": {
      "faculty_id": "...",
      "section_id": "...",
      "grade_id": "...",
      "label_ar": "..."
    },
    "subjects": [
      {
        "id": "subj-psych",
        "title": "Psychology",
        "title_ar": "علم النفس",
        "sort_order": 0,
        "groups": [
          {
            "id": "grp-psych-summaries",
            "type": "summary",
            "label": "Summaries",
            "label_ar": "تلخيصات",
            "sort_order": 0,
            "items": [
              {
                "id": "item-1",
                "title": "Chapter 1 summary",
                "title_ar": "تلخيص الفصل الأول",
                "type": "summary",
                "is_unlocked": false,
                "file_url": null,
                "thumbnail": null,
                "exam_id": null
              }
            ]
          },
          {
            "id": "grp-psych-books",
            "type": "book",
            "label": "Books",
            "label_ar": "كتب",
            "items": [
              {
                "id": "item-2",
                "title": "Course book PDF",
                "type": "book",
                "is_unlocked": true,
                "file_url": "/api/uploads/....pdf",
                "thumbnail": "/uploads/....jpg"
              }
            ]
          },
          {
            "id": "grp-psych-quizzes",
            "type": "quiz",
            "label": "Quizzes",
            "label_ar": "اختبارات",
            "items": [
              {
                "id": "item-3",
                "title": "Midterm quiz",
                "type": "quiz",
                "is_unlocked": false,
                "exam_id": "uuid-exam",
                "file_url": null
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

### قيم مقترحة لـ `group.type` و `item.type`

| `type` | معنى تقريبي | ملاحظات للموبايل |
|--------|-------------|------------------|
| `summary` | تلخيص | فتح PDF عبر `file_url` عند الفتح |
| `book` | كتاب / PDF | نفس السلوك |
| `file` | ملف عام | PDF أو رابط حسب ما ترجعون |
| `video` | فيديو | `file_url` أو `stream_url` (وثّقوا المفتاح) |
| `assignment` | واجب | قد يكون ملف أو رابط |
| `quiz` أو `exam` | اختبار | `exam_id` مطلوب عند `is_unlocked` للبدء من التطبيق |
| `other` | غير مصنف | عرض عنوان + سلوك افتراضي |

---

## 2) قواعد القفل (مهم)

1. **`is_unlocked`** على مستوى **العنصر** (`items[]`) فقط (إلزامي للموبايل).
2. عند `is_unlocked: false`:
   - لا ترجعوا **`file_url`** صالح (أو `null`) للملفات.
   - للاختبار: لا يبدأ الطالب الامتحان؛ يظهر قفل في القائمة.
3. **لا** تعتمدوا على قفل كارت الرئيسية؛ الرئيسية تفتح الشجرة دائماً.
4. (اختياري) `is_unlocked` على مستوى `group` أو `subject`: إن وُجد، عرّفوا الأولوية (مثلاً: `subject` locked ⇒ كل المجموعات تعرض مقفولة بدون ما تغيّروا كل item).

---

## 3) فلترة من جهة التطبيق (مرجع للـ backend)

- من كارت **الكتب** في الرئيسية: التطبيق يعرض المواد ثم المجموعات التي **ليست** نوع اختبار فقط (`quiz` / `exam`) — أي تلخيصات وكتب وملفات…
- من كارت **الاختبارات والواجبات**: يعرض المواد ثم المجموعات من نوع **`quiz` / `exam` / `assignment`** (حسب ما تضيفون في الـ CMS).

لو مادة ما فيها مجموعات بعد الفلترة، تختفي من ذلك المسار أو تظهر فارغة حسب تنفيذكم.

---

## 4) لوحة الأدمن

تفاصيل شاشات الـ dashboard ومسارات الـ admin المقترحة: [`ADMIN_DASHBOARD_COHORT_LIBRARY_HIERARCHICAL.md`](./ADMIN_DASHBOARD_COHORT_LIBRARY_HIERARCHICAL.md).

باختصار: إنشاء/تعديل **مواد** ضمن cohort → **مجموعات** (نوع + عنوان) → **عناصر** مع **`is_unlocked`** لكل عنصر (`PATCH` على `item.id` أو مسار `.../items/{id}`).

---

## 5) توافق الخلف (legacy)

إذا لم يكن `subjects` جاهزاً بعد:

- الإبقاء على `books` و `quizzes` كمصفوات مسطحة كما في الوثيقة القديمة؛ الموبايل يعرض شجرة مبسطة (مادة افتراضية واحدة + مجموعتين: كتب / اختبارات).

---

## 6) Checklist

- [ ] `subjects[].groups[].items[]` كلها فيها `id`, `title` أو `title_ar`, `type`, `is_unlocked`.
- [ ] ملفات مقفولة بدون `file_url` فعّال.
- [ ] عنصر quiz مقفول مع `exam_id` اختياري أو null حتى الفتح.
- [ ] بعد فتح عنصر من الأدمن، نفس `GET` يعكس `is_unlocked: true`.
- [ ] طالب خارج الـ cohort لا يرى مواد غيره.

---

## 7) اتصال بالموبايل

- الشاشة: `CohortLibraryScreen` — `GET` عبر `HomeService.getCohortLibrary()`.
- عند اكتمال الـ API بالشكل أعلاه، الشجرة تظهر كاملة بدون تعديل مسار جديد (ما لم تغيّروا الـ URL؛ إن غيّرتم حدّثوا `ApiEndpoints.studentCohortLibrary`).
