# FCM Token Request Changes (Backend Handoff)

This document summarizes the **latest mobile changes** related to FCM token delivery, so backend can reliably receive token(s) and send push notifications.

## Why this change

To guarantee push readiness as early as possible, mobile now sends FCM token in **two places**:

1. During `register` request (when token is available)
2. After authentication via dedicated token endpoint (`/auth/fcm-token`)

This dual strategy improves reliability across cold start / delayed Firebase token scenarios.

---

## 1) Register Request Updated

### Endpoint

- `POST /api/auth/register`

### New field in request body

- `fcm_token` (optional, sent when available)

### Example body

```json
{
  "name": "User Full Name",
  "name_first": "User",
  "name_father": "Father",
  "name_grandfather": "Grand",
  "name_family": "Family",
  "national_id": "30309152600222",
  "code": "ZSWTR7JQ",
  "phone": "+2001119975847",
  "faculty_id": "faculty-uuid",
  "section_id": "section-uuid",
  "grade_id": "grade-id",
  "device_id": "android_TKQ1.221114.001",
  "fcm_token": "fcm_device_token_here"
}
```

### Backend expectation

- Accept `fcm_token` in register payload.
- If present, attach/store it for the newly created user.
- If missing, do not fail register; token may arrive in the next step.

---

## 2) Post-Register Token Sync (Still Required)

### Endpoint

- `POST /api/auth/fcm-token`

### Auth

- `Authorization: Bearer <access_token>`

### Body

```json
{
  "token": "fcm_device_token_here",
  "platform": "android",
  "device_id": "android_TKQ1.221114.001",
  "app_version": "1.0.0"
}
```

### Backend expectation

- Upsert token by user/device.
- Mark token active.
- Keep endpoint idempotent (safe for repeated calls).

---

## Recommended Backend Handling Rules

1. **Prefer register token when present**
   - If `fcm_token` exists in register body, store it immediately.

2. **Always allow `/auth/fcm-token` to update same token/device**
   - This call should refresh metadata and ensure latest token state.

3. **Do not reject if duplicate**
   - Treat duplicates as updates (not errors).

4. **Support token rotation**
   - Mobile re-sends on Firebase token refresh; backend should replace old token for that device/user mapping.

---

## QA Checklist for Backend

1. Register new user with `fcm_token` present.
2. Confirm token stored and linked to that user.
3. Confirm `/auth/fcm-token` updates same mapping after login/register.
4. Send test push from backend and verify device receives it.
5. Rotate token (or reinstall app), verify backend updates token and old token is not used.

---

## Notes

- Register endpoint is unauthenticated by design; missing Authorization header there is expected.
- Notification delivery still depends on correct Firebase server-side config and valid stored tokens.
