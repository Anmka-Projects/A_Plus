# Authentication API changes — Rig Tech mobile app

This document describes what the Flutter app now sends and expects for **login** and **register**, so the backend can stay aligned.

Base URL (app config): `https://rigtech-training-academy.anmka.com/api`  
Endpoints (unchanged paths): `POST /auth/login`, `POST /auth/register`

---

## 1. Login — `POST /auth/login`

### Request body (JSON)

The app sends:

| Field       | Type   | Required | Notes |
|------------|--------|----------|--------|
| `code`     | string | yes      | Unique learner / student code (replaces email + phone as login identifier). |

### Removed from login request (no longer sent)

- `email`
- `phone`
- `password`
- `device_id`

### Expected response

No change required from the previous contract if the shape is still:

- `success`, `message`
- `data` containing tokens (`accessToken` / `token`, `refreshToken`, etc.) and user object

### Recommended user object fields

Include when possible:

| Field              | Type   | Notes |
|-------------------|--------|--------|
| `code`            | string | Same value used to log in; optional alias `student_code` is parsed by the app. |
| `name`            | string | Display name. |
| `phone`           | string | User phone number. |
| `category_id`     | string | Selected category id at registration time. |
| `subcategory_id`  | string | Selected subcategory id when available. |
| `email`           | string | Optional if accounts are code-based only. |
| `id`, `role`, ... | mixed  | Optional extra fields are still tolerated by the app. |

---

## 2. Register — `POST /auth/register`

### Request body (JSON)

The app sends:

| Field             | Type   | Required | Notes |
|------------------|--------|----------|--------|
| `name`           | string | yes      | Display name. |
| `code`           | string | yes      | Unique per user; used for login. |
| `phone`          | string | yes      | E.164 style from the client (e.g. `+2012…`). |
| `category_id`    | string | yes      | UUID of the main category. |
| `subcategory_id` | string | conditional | **Required** when the selected category has subcategories in `GET /categories`. **Omitted or empty** when the category has no subcategories. |

### Removed from register request (no longer sent)

The UI and client **no longer** collect or send:

- `email`
- `category_ids` (array)
- `student_type` / `studentType`
- `gender`
- `country_id`
- `password`
- `role`
- `device_id`

If the backend still requires any of these, either make them optional server-side or notify the mobile team.

### Category / subcategory data

- Categories are loaded from existing **`GET /categories`** (public).
- Subcategories are read from each category object if present under any of:
  - `subcategories`
  - `sub_categories`
  - `children`

If the API stores subcategories elsewhere, expose them on the category payload (or provide a dedicated endpoint) so the app can populate the subcategory picker.

### Expected response

Same as today: `success`, optional `message`, `data` with user and tokens when the account is active.  
If registration returns `PENDING` without tokens, the app already handles that flow.

For the new register flow, the returned user payload should at least include:

- `name`
- `code` (or `student_code`)
- `phone`
- `category_id` (or nested `category.id`)
- `subcategory_id` (or nested `subcategory.id` when present)

---

## 3. Summary for backend checklist

1. **Login** accepts only `code`.  
2. **Register** accepts only `name`, `code`, `phone`, `category_id`, and optional `subcategory_id`.  
3. **`code` is unique** and immutable or changeable only via a dedicated flow.  
4. **User profile JSON** should return `code` (or `student_code`) for display and support.  
5. **Categories API** should include nested subcategories (or document an alternative the app can call).

---

## 4. Files changed on mobile (reference)

- `lib/services/auth_service.dart` — login/register payloads  
- `lib/screens/auth/login_screen.dart` — code-only UI  
- `lib/screens/auth/register_screen.dart` — new field set and category / subcategory pickers  
- `lib/models/user.dart` — optional `code` on user model  
- `lib/l10n/app_en.arb`, `lib/l10n/app_ar.arb` — labels for code / subcategory  

---

*Generated for backend handoff — April 2026.*
