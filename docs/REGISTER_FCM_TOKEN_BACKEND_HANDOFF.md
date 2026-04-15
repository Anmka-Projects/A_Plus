# Register Flow FCM Token Handoff

This document explains how the app sends the device FCM token to backend after **successful register**.

## Goal

After a user registers and receives auth tokens, the mobile app immediately registers the device FCM token using:

- `POST /api/auth/fcm-token`

This allows the backend to send push notifications to that newly registered user.

---

## Current Mobile Behavior (Implemented)

### 1) Register succeeds

Mobile calls:

- `POST /api/auth/register`

When response is successful and includes access token, app stores:

- `accessToken`
- `refreshToken`

### 2) Immediate FCM token sync

Right after saving auth token, app calls:

- `FirebaseNotification.syncFcmTokenWithBackend()`

which sends:

- `POST /api/auth/fcm-token`
- `Authorization: Bearer <accessToken>`

with body:

```json
{
  "token": "<firebase_device_token>",
  "platform": "android",
  "device_id": "<stable_device_id>",
  "app_version": "<app_version>"
}
```

### 3) Auto-resend on token refresh

If Firebase refreshes token later, app sends the same endpoint again with updated token.

---

## Backend Requirements

Please ensure `POST /api/auth/fcm-token` supports:

- Authenticated user (Bearer token)
- Upsert behavior (same user/device can update token)
- Reactivation of old inactive tokens when re-registered
- Idempotent response (calling multiple times should not break state)

Validation rules expected by mobile:

- `token`: required, string
- `platform`: optional (`android`, `ios`, `web`)
- `device_id`: optional string
- `app_version`: optional string

---

## Notes About Pending Accounts

If register returns `PENDING` and no access token is issued yet, mobile cannot call `/auth/fcm-token` at that moment.

In that case token sync happens at first successful authenticated session (login or approved flow).

---

## Suggested Backend QA

1. Register a new user from app.
2. Confirm `/api/auth/fcm-token` is hit immediately after register success.
3. Verify DB row links token to the same user.
4. Send test push from admin endpoint and confirm delivery.
5. Reinstall app / refresh token and verify token record updates (not duplicates unless intended by design).

---

## Reference

- `docs/FIREBASE_NOTIFICATION_ENDPOINTS.md`
