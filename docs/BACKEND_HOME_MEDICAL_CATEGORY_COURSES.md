# Backend: Home medical tracks → courses by category

The student **home** screen shows six medical category tiles (Doctor, Dentist, Physiotherapist, Pharmacist, Nurse, Scientist). Tapping a tile must open the courses list **filtered to that category only**.

This document defines what the mobile app sends and what the API should support so the backend and app stay aligned.

---

## 1. Category identifiers (contract with the app)

The app uses a **stable slug** per tile (English snake_case, lowercase). These values must be resolvable on the server to exactly one category (or equivalent filter).

| Slug (`category_slug`) | Meaning (EN) | Notes for CMS |
|------------------------|--------------|----------------|
| `doctor` | Doctor | e.g. internal medicine / general doctor track |
| `dentist` | Dentist | dental sciences |
| `physiotherapist` | Physiotherapist | physical therapy |
| `pharmacist` | Pharmacist | pharmacy |
| `nurse` | Nurse | nursing |
| `scientist` | Scientist | lab / research / basic sciences (align with product) |

**Requirement:** Each slug must map to **one** category record (or one fixed filter rule) so `GET /courses?...` returns only courses belonging to that track.

---

## 2. Recommended API behavior

### Option A — Extend existing courses index (preferred for the app)

The app already calls:

`GET /api/courses?...`

Today it supports (among others) `category_id`. **Add** optional:

| Query parameter | Type | Description |
|-----------------|------|-------------|
| `category_slug` | string | Exact match to slug in the table below (e.g. `doctor`). Mutually exclusive with `category_id` is fine; if both are sent, define precedence (recommend: **`category_id` wins**). |

**When `category_slug` is present and valid:**

- Return only courses linked to the category that owns that slug.
- Same response shape as the unfiltered list: pagination, `data.courses` (or array in `data`, as you already return), `meta.total`, etc.
- If slug is unknown: `400` with a clear message, or `200` with empty list — **pick one and document it** (app treats empty list as “no courses”).

**When `category_slug` is absent:**

- Behavior unchanged (full catalog with other filters).

### Option B — Resolve slug via categories API

Expose slugs on categories:

`GET /api/categories`

Each item should include at least:

- `id`
- `slug` (required for the six values above)
- `name` or `name_ar` / `name_en` (for admin / future UI)

The app could resolve `slug → id` then call `GET /api/courses?category_id=...`. This works but adds latency and duplication; **Option A is preferred** so one request from the courses screen is enough.

### Option C — Existing nested route

You already have:

`GET /api/categories/{id}/courses`

If you add **`GET /api/categories/by-slug/{slug}/courses`** (or resolve slug to `id` internally), the app can call that instead. Still document slug values and response parity with the main courses list.

---

## 3. Data model (backend)

- Categories used for these six tiles **must** have a unique `slug` column (or equivalent) matching the table in §1.
- Courses must be associated to categories in the way you already use for `category_id` (pivot, `category_id` on `courses`, etc.).
- Seeding: ensure the six slugs exist in production/staging so QA can verify each tile.

---

## 4. Auth & pagination

- Same **authentication** rules as `GET /api/courses` today (e.g. Bearer token if required).
- Same **pagination** query params (`page`, `per_page`) and `meta` structure so the app does not need a separate code path.

---

## 5. What the mobile app sends today

After integration, the app will call the courses endpoint with:

- `category_slug=<one of: doctor | dentist | physiotherapist | pharmacist | nurse | scientist>`
- Plus existing params: `page`, `per_page`, `search`, `price`, `sort`, `level`, `duration`, etc.

Example:

```http
GET /api/courses?page=1&per_page=50&search=&category_id=&category_slug=doctor&price=all&level=all&sort=newest&duration=all
```

(Exact query string matches your current client builder; `category_id` may be empty when using slug.)

If you only implement **`category_id`**, publish the **numeric (or UUID) ids** for the six categories and the app can be switched to send `category_id` instead — but slugs are safer across environments.

---

## 6. Acceptance checklist

- [ ] Six categories exist with slugs: `doctor`, `dentist`, `physiotherapist`, `pharmacist`, `nurse`, `scientist`.
- [ ] `GET /api/courses` filters correctly when `category_slug` is set.
- [ ] Unknown slug behavior is defined and consistent.
- [ ] Pagination and response shape match unfiltered courses list.
- [ ] At least one course per category in staging for manual testing from the app.

---

## 7. Contact / versioning

- **App feature:** Home → tap medical tile → “All courses” pre-filtered by that track.
- Update this doc if you change slug names or prefer only `category_id` with a published mapping table.
