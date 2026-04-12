# Backend specification: registration (quad name, national ID, faculty → section → grade) & single-device login

This document is for the **A Plus** API (`https://a-plus.anmka.com/api`). The **Flutter app** is already updated to call these contracts. Please implement or align the backend so mobile and server stay in sync.

---

## 1. Registration — `POST /api/auth/register`

### 1.1 Replace course “category / subcategory” with academic hierarchy

The mobile app **no longer sends** `category_id` / `subcategory_id` for student registration. Use **`faculty_id`**, **`section_id`**, and **`grade_id`** instead (all required for the current app build).

### 1.2 Quad name (رباعي)

The full name is split into **four required string fields** (Arabic naming). The app also sends a combined `name` for backward compatibility / admin views.

| JSON field | Type | Required | Description |
|------------|------|----------|-------------|
| `name_first` | string | yes | First name |
| `name_father` | string | yes | Father’s name |
| `name_grandfather` | string | yes | Grandfather’s name |
| `name_family` | string | yes | Family name |
| `name` | string | yes | **Recommended:** space-joined full name (`" ".join` of the four parts), trimmed |

Validation: each part non-empty after trim; optional max length per field (e.g. 100).

### 1.3 National ID

| JSON field | Type | Required | Description |
|------------|------|----------|-------------|
| `national_id` | string | yes | Digits only. App currently enforces **14 digits** (Egypt national ID). |

### 1.4 Existing fields (unchanged semantics)

| JSON field | Type | Required | Description |
|------------|------|----------|-------------|
| `code` | string | yes | Student / activation code (unique learner code) |
| `phone` | string | yes | E.164 recommended (e.g. `+20…`) |

### 1.5 Device binding (single-device policy)

| JSON field | Type | Required | Description |
|------------|------|----------|-------------|
| `device_id` | string | yes | Opaque stable ID from the app (see §5). |

On **successful registration**:

- Persist `device_id` on the user (or on an `user_devices` row) as the **authorized device** for this account.
- If the product rule is “first successful login wins” instead, document it; the app currently sends `device_id` on **both** register and login.

### 1.6 Example request body

```json
{
  "name": "محمد أحمد علي حسن",
  "name_first": "محمد",
  "name_father": "أحمد",
  "name_grandfather": "علي",
  "name_family": "حسن",
  "national_id": "29501010101010",
  "code": "STU-XXXX",
  "phone": "+201234567890",
  "faculty_id": "1",
  "section_id": "12",
  "grade_id": "34",
  "device_id": "android_bp1a.250505.005.b1"
}
```

### 1.7 Success / pending responses

Keep existing behaviour for `success`, `data`, tokens, and `PENDING` approval flow if already in use.

---

## 2. Login — `POST /api/auth/login`

### 2.1 Request body

| JSON field | Type | Required | Description |
|------------|------|----------|-------------|
| `code` | string | yes | Same unique learner code as today |
| `device_id` | string | yes | Same identifier family as registration |

### 2.2 Single-device rule (required behaviour)

When `code` identifies a user who **already has a stored `device_id`**:

- If `device_id` **matches** → proceed as today (issue tokens, etc.).
- If `device_id` **does not match** → **reject** with HTTP **403** (or **409**) and a clear `message`, e.g.  
  **Arabic:** `هذا الحساب مسجل على جهاز آخر. يرجى تسجيل الخروج من الجهاز السابق أو التواصل مع الدعم.`  
  **English:** `This account is linked to another device.`

When the user has **no** `device_id` yet (legacy users):

- **Option A (recommended):** set `device_id` on first successful login to the incoming value (migration).
- **Option B:** reject until admin assigns device (stricter; requires admin tooling).

### 2.3 Optional: admin / support “reset device”

Expose an admin or support endpoint to clear or replace `device_id` for a user so legitimate device changes are possible without deleting the account.

---

## 3. Token refresh — `POST /api/auth/refresh`

The app may send:

```json
{
  "refreshToken": "<refresh_token>",
  "device_id": "<same stable id>"
}
```

**Recommended:** if `device_id` is present, verify it still matches the user’s bound device; if not, invalidate refresh and return **401/403** so the client forces re-login.

(If you prefer not to validate on refresh, ignore `device_id` — but login-time enforcement is still mandatory for the product goal.)

---

## 4. Academic structure — public read-only endpoints for registration UI

These endpoints are **unauthenticated** (`requireAuth: false`). They drive three dependent dropdowns: **Faculty → Section → Grade**.

Base path assumed in app: `/api/registration/…`

### 4.1 List faculties

`GET /api/registration/faculties`

**Response shape (aligned with app parser):**

```json
{
  "success": true,
  "data": [
    { "id": "1", "name": "بشري", "name_ar": "بشري", "name_en": "Medicine" },
    { "id": "2", "name": "أسنان", "name_ar": "أسنان", "name_en": "Dentistry" }
  ]
}
```

**Expected faculties (seed / content):** بشري، أسنان، علاج طبيعي، صيدلة، تمريض — IDs can be numeric or string as long as they are stable in JSON.

### 4.2 Sections for a faculty

`GET /api/registration/faculties/{facultyId}/sections`

Same wrapper: `{ "success": true, "data": [ { "id", "name", "name_ar?", "name_en?" } ] }`.

### 4.3 Grades for a section

`GET /api/registration/sections/{sectionId}/grades`

Same wrapper.

### 4.4 Display names

The app resolves label text in this order: `name` → `name_ar` → `name_en`. Providing at least `name` or `name_ar` is enough.

---

## 5. `device_id` format (client-side)

The Flutter app builds a **stable string per install**, for example:

- Android: `android_<AndroidDeviceInfo.id>` (from `device_info_plus`)
- iOS: `ios_<identifierForVendor>`
- Web (if ever used): fallback string

The value is **cached in app preferences** after first creation. Treat it as an **opaque string** (max length ~200). Do not assume format beyond prefix if you log or index it.

---

## 6. Database / model checklist

- [ ] User (or profile) fields: `name_first`, `name_father`, `name_grandfather`, `name_family`, `national_id`, `faculty_id`, `section_id`, `grade_id` (FKs or string IDs consistent with registration endpoints).
- [ ] `device_id` (string) on user or related table; index for lookups.
- [ ] Tables or static config for **faculties**, **sections** (`faculty_id`), **grades** (`section_id`).
- [ ] Validation: `national_id` unique per policy if required by law/product.
- [ ] Deprecation: stop requiring `category_id` / `subcategory_id` on register for student flow, or map old fields temporarily during migration.

---

## 7. Error handling (suggested)

| Scenario | HTTP | `success` | `message` |
|----------|------|-----------|-----------|
| Wrong code | 401/404 | false | Invalid code |
| Second device login | 403 | false | Account linked to another device |
| Invalid faculty/section/grade IDs | 422 | false | Validation error |
| Duplicate national ID (if unique) | 409 | false | National ID already registered |

---

## 8. Contact

Mobile repo paths for reference:

- Endpoints: `lib/core/api/api_endpoints.dart` (`registrationFaculties`, `registrationSections`, `registrationGrades`)
- Register payload: `lib/services/auth_service.dart` → `register`
- Login payload: `lib/services/auth_service.dart` → `login`

After deployment, confirm:

1. `GET /api/registration/faculties` returns non-empty `data`.
2. Register with real `faculty_id` / `section_id` / `grade_id` succeeds.
3. Login from the **same** device succeeds; from a **different** `device_id` fails with the agreed message.
