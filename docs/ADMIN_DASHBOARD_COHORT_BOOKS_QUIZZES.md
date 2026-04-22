# Admin dashboard: cohort books & quizzes (unlock for class)

This document is for **whoever builds the admin web dashboard** (and overlaps with backend). It pairs with the student/mobile contract in [`BACKEND_HOME_COHORT_BOOKS_QUIZZES.md`](./BACKEND_HOME_COHORT_BOOKS_QUIZZES.md) and the **hierarchical tree** spec in [`BACKEND_COHORT_LIBRARY_HIERARCHICAL.md`](./BACKEND_COHORT_LIBRARY_HIERARCHICAL.md).

**Admin UX for the tree (subjects → groups → items):** use [`ADMIN_DASHBOARD_COHORT_LIBRARY_HIERARCHICAL.md`](./ADMIN_DASHBOARD_COHORT_LIBRARY_HIERARCHICAL.md).

---

## 1) Product summary

| Concept | Meaning |
|--------|---------|
| **Cohort** | Same **faculty + section + grade** as used in student registration (`registration/faculties → sections → grades`). |
| **Books** | PDFs / files (or links) attached to a cohort; all students in that cohort see the **same list** on the app home. |
| **Quizzes** | Exams tied to a cohort; same list for everyone in the cohort. |
| **Locked** | `is_unlocked: false` → mobile shows a **locked** state and blocks opening until an admin unlocks. |
| **Unlocked** | `is_unlocked: true` → mobile allows navigation / download / start exam (per mobile implementation). |

**Goal for the dashboard:** admins can **see** cohorts (or pick faculty → section → grade), **attach or seed** books/quizzes, and **toggle unlock** (per item or bulk). Changes must appear on the next `GET /api/student/cohort-library` call (after refresh on the app).

---

## 2) Suggested admin UX (pages)

You can merge these into existing menus (e.g. “Academic content”, “Cohort library”).

### A) Cohort picker

- Cascading selects: **Faculty → Section → Grade** (same IDs as registration APIs).
- “View library” loads books + quizzes for that cohort.

### B) Library table (two tabs or one merged list)

Columns useful for support:

- Type: `book` | `quiz`
- Title
- `is_unlocked` (toggle or row action)
- Optional: `updated_at`, last editor (`updated_by`)
- For quizzes: `exam_id` (link to existing exam editor if you have one)

### C) Actions

- **Unlock / Lock** single row (PATCH).
- **Unlock all books** / **Unlock all quizzes** for this cohort (bulk POST — optional but saves time).
- **Add book to cohort** / **Add quiz to cohort** (POST create link — if content is created from dashboard).
- Confirm destructive actions (“Lock again?”) if students may lose access mid-term.

### D) Permissions

- Restrict “unlock” to roles such as `super_admin` / `content_admin`; read-only for support if needed.
- Optional: **audit log** (who unlocked what, when, which cohort).

---

## 3) Admin API contract (align with backend)

Base path examples — **normalize names** with your backend team; shapes matter more than exact URLs.

### List library for one cohort (for the dashboard table)

`GET /api/admin/cohorts/library?faculty_id=...&section_id=...&grade_id=...`

- **Auth:** admin Bearer.
- **Response:** same structure as student payload is ideal (reuse DTO), e.g. `data.books[]`, `data.quizzes[]`, each with `id`, `title`, `is_unlocked`, plus admin-only fields if useful (`created_at`, `sort_order`).

### Toggle unlock (single resource)

Examples (pick one style):

- `PATCH /api/admin/cohort-resources/books/{id}`  
  Body: `{ "is_unlocked": true }` or `{ "is_unlocked": false }`
- `PATCH /api/admin/cohort-resources/quizzes/{id}`  
  Body: same

`id` = stable id of the **cohort–resource link** row (not only the raw file/exam id), so the same PDF can exist in multiple cohorts with different lock states.

### Bulk unlock (optional)

- `POST /api/admin/cohorts/{facultyId}/{sectionId}/{gradeId}/unlock`  
  Body: `{ "type": "books" | "quizzes" | "all" }`

### Create / delete cohort attachment (optional)

- `POST /api/admin/cohorts/library/items` — attach book or quiz to a cohort.  
- `DELETE /api/admin/cohort-resources/{type}/{id}` — remove from cohort (define soft vs hard delete).

**Invariant:** after any mutation, the student endpoint  
`GET /api/student/cohort-library`  
must return updated `is_unlocked`, `books_has_access`, and `quizzes_has_access` (see backend doc).

---

## 4) Field rules (same as mobile)

| Field | Admin responsibility |
|--------|----------------------|
| `books[].is_unlocked` | When `false`, backend should not expose a usable `file_url` to students. |
| `quizzes[].is_unlocked` | When `false`, students must not start the exam; when `true`, `exam_id` must match a valid exam the app can open. |
| `books_has_access` / `quizzes_has_access` | Backend-derived flags for convenience; dashboard can show “Class has book access: yes/no”. |

---

## 5) Validation & edge cases

- Do not allow attaching a resource to a cohort with **missing** `faculty_id` / `section_id` / `grade_id`.
- If a student’s profile is missing academic triplet, the app may not gate correctly; dashboard can show a **warning** when viewing “all students” for a cohort (backend returns 422 for student API — document message for support).
- **Default for new items:** `is_unlocked: false` until an admin explicitly unlocks (matches mobile QA checklist in backend doc).

---

## 6) QA checklist (dashboard + API)

- [ ] Library list matches what a test student sees on the phone for the same cohort.
- [ ] Unlock book → student `cohort-library` shows `is_unlocked: true` and `books_has_access: true` if at least one book unlocked.
- [ ] Lock book again → student loses access after refresh.
- [ ] Unlock quiz → student can open quizzes flow; lock → blocked on home.
- [ ] Non-admin token cannot PATCH/POST admin cohort routes.
- [ ] (Optional) Audit entry written on each unlock/lock.

---

## 7) References

- Student/mobile API & JSON shape: [`BACKEND_HOME_COHORT_BOOKS_QUIZZES.md`](./BACKEND_HOME_COHORT_BOOKS_QUIZZES.md)
- Flutter calls: `GET /api/student/cohort-library` (see `ApiEndpoints.studentCohortLibrary` in the mobile repo).

When admin routes are finalized, add their **exact paths** to this file and to the backend doc so web and mobile stay in sync.
