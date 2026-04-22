# لوحة الأدمن: مكتبة الـ cohort الهرمية (مادة ← مجموعة نوع ← عناصر)

هذا الملف لمطوّر **لوحة التحكم (Admin dashboard)** — يصف شاشات وإجراءات إدارة المحتوى الهرمي الذي يظهر للطالب داخل التطبيق بعد اختيار **الكتب** أو **الاختبارات والواجبات** من الرئيسية.

**مرجع الـ API (طالب + شكل JSON):** [`BACKEND_COHORT_LIBRARY_HIERARCHICAL.md`](./BACKEND_COHORT_LIBRARY_HIERARCHICAL.md)  
**مرجع قديم (قوائم مسطحة + unlock):** [`ADMIN_DASHBOARD_COHORT_BOOKS_QUIZZES.md`](./ADMIN_DASHBOARD_COHORT_BOOKS_QUIZZES.md)

---

## 1) المطلوب من المنتج (بالعربي)

| المستوى | الوصف |
|---------|--------|
| **Cohort** | نفس ثلاثي التسجيل: كلية + قسم + فرقة. |
| **مادة (Subject)** | مثال: علم النفس — تظهر للطالب كأول مستوى في الـ accordion. |
| **مجموعة (Group)** | نوع محتوى تحت المادة: تلخيصات، كتب، ملفات، اختبارات، … (`type` + عناوين `label` / `label_ar`). |
| **عنصر (Item)** | ملف PDF، رابط، أو اختبار مربوط بـ `exam_id` — **القفل هنا فقط** (`is_unlocked` لكل عنصر). |

- الطالب **يشوف الشجرة** حتى لو كل العناصر مقفولة؛ الفتح/التحميل/بدء الاختبار يتم فقط للعناصر المفتوحة من الأدمن.
- أي تعديل من الـ dashboard يجب أن يظهر في **`GET /api/student/cohort-library`** بعد الحفظ (الطالب يعمل سحب للتحديث في التطبيق).

---

## 2) تدفق شاشات مقترح (UX)

### أ) اختيار الـ cohort (كما في الوثائق السابقة)

1. **Faculty → Section → Grade** (نفس IDs مسار التسجيل).
2. زر **«مكتبة الفرقة»** أو **«محتوى الطلاب»** يفتح محرر الشجرة لهذا الـ cohort فقط.

### ب) قائمة المواد (Subjects)

جدول أو بطاقات:

| عمود | ملاحظة |
|------|--------|
| الاسم (`title` / `title_ar`) | إلزامي واحد على الأقل للعرض. |
| ترتيب (`sort_order`) | سحب وإفلات أو أرقام. |
| عدد المجموعات / العناصر | للقراءة فقط. |
| إجراءات | تعديل، حذف (مع تأكيد)، **إضافة مادة**. |

### ج) داخل مادة واحدة: المجموعات (Groups)

- قائمة مجموعات مرتبة بـ `sort_order`.
- **إضافة مجموعة:** اختيار **`type`** من قائمة ثابتة (`summary`, `book`, `file`, `video`, `assignment`, `quiz`, `exam`, `other`) + حقول **`label` / `label_ar`**.
- تعديل / حذف مجموعة (تحذير: يحذف أو ينقل العناصر حسب سياسة المنتج).

### د) داخل مجموعة: العناصر (Items)

جدول أو قائمة:

| حقل | لوحة الأدمن |
|-----|-------------|
| عنوان (`title` / `title_ar`) | نص |
| **`is_unlocked`** | **Toggle** واضح (افتراضي للمحتوى الجديد: مقفول). |
| ملف / رابط | رفع PDF أو تخزين مسار؛ لا تعرض للطالب رابط تحميل فعّال إلا بعد الفتح (يتماشى مع الـ backend). |
| اختبار | اختيار **`exam_id`** من امتحانات موجودة في النظام (إن وُجدت). |
| `type` على العنصر | اختياري؛ إن غاب يُورث من المجموعة. |

**إجراءات جماعية (اختياري):** «فتح كل العناصر في هذه المجموعة»، «قفل الكل».

---

## 3) صلاحيات وأمان

- من له حق **تعديل الشجرة** ومن له حق **فتح/قفل العناصر** فقط (مثلاً `content_admin` vs `support_readonly`).
- **سجل تدقيق (Audit):** من فتح/قفل أي `item.id`، متى، وأي cohort.
- التحقق من أن المادة/المجموعة/العنصر مربوطة بـ `faculty_id, section_id, grade_id` الصحيحة — لا تسمح بتسريب محتوى cohort لآخر عبر الـ UI.

---

## 4) عقد الـ API من جهة الأدمن (يتماشى مع الـ backend)

الأسماء أمثلة — وحّدوها مع فريق الـ backend:

| إجراء | مقترح |
|--------|--------|
| قائمة المواد لـ cohort | `GET /api/admin/cohorts/{facultyId}/{sectionId}/{gradeId}/subjects` |
| إنشاء مادة | `POST .../subjects` body: `title`, `title_ar`, `sort_order` |
| تعديل مادة | `PATCH /api/admin/cohort-subjects/{subjectId}` |
| حذف مادة | `DELETE .../subjects/{subjectId}` |
| إنشاء مجموعة تحت مادة | `POST .../subjects/{subjectId}/groups` body: `type`, `label`, `label_ar`, `sort_order` |
| تعديل مجموعة | `PATCH /api/admin/cohort-groups/{groupId}` |
| إنشاء عنصر | `POST .../groups/{groupId}/items` body: حقول العنصر + `is_unlocked` |
| **فتح/قفل عنصر** | `PATCH /api/admin/cohort-items/{itemId}` body: `{ "is_unlocked": true \| false }` |
| رفع ملف | نفس مسار الرفع الحالي عندكم ثم تمرير `file_url` في الـ item |

بعد أي `PATCH`/`POST`/`DELETE`، استجابة الـ student **`GET /api/student/cohort-library`** يجب أن تعكس التغيير (نفس شكل [`BACKEND_COHORT_LIBRARY_HIERARCHICAL.md`](./BACKEND_COHORT_LIBRARY_HIERARCHICAL.md)).

---

## 5) اختبار من منظور الطالب (QA)

- [ ] إنشاء مادة + مجموعة «تلخيصات» + عنصر مقفول → الطالب يرى العنوان في التطبيق ولا يفتح الملف.
- [ ] فتح العنصر من الأدمن → الطالب يفتح PDF بعد التحديث.
- [ ] مجموعة من نوع `quiz` + `exam_id` + عنصر مفتوح → التطبيق يوجّه لشاشة الاختبار (حسب تنفيذ الموبايل).
- [ ] طالب من cohort آخر لا يرى مواد هذا الـ cohort.
- [ ] ترتيب `sort_order` للمواد والمجموعات يطابق العرض في التطبيق.

---

## 6) مرجع التطبيق (Flutter)

- شاشة الطالب: `CohortLibraryScreen` — مسار `RouteNames.cohortLibrary` مع `extra: { 'root': 'materials' | 'quizzes' }`.
- الكود: `lib/screens/secondary/cohort_library_screen.dart` و `HomeService.getCohortLibrary()`.

عند تثبيت مسارات الـ admin النهائية، حدّثوا هذا الملف + [`BACKEND_COHORT_LIBRARY_HIERARCHICAL.md`](./BACKEND_COHORT_LIBRARY_HIERARCHICAL.md) بروابط الـ OpenAPI أو Postman إن وُجدت.
