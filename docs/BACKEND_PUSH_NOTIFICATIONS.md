# Push notifications — backend integration (A Plus mobile app)

This document is for the **backend team**. The Flutter app already uses **Firebase Cloud Messaging (FCM)** and **local notifications**.

## What the mobile app does today (client-only)

- When the user **leaves the app** (app goes to **background**: Home, recents, switch to another app), the client may show a **local** reminder notification (copy is localized EN/AR). This is **throttled** (default: at most once every **6 hours**) so users are not spammed.
- When the app is **force-stopped** or **killed**, the OS does **not** let the app run code. **Only the server** can deliver a notification in that state, via **FCM** (or the user opens the app again).

So: **marketing / transactional / “we miss you” after days away** requires **your** push pipeline + registered device tokens.

---

## 1. FCM device token (required from backend)

On launch, the app obtains an FCM registration token (see client logs: `FCM Token: ...`).

**Backend should:**

1. Expose an authenticated API for logged-in users to **register** (and refresh) their token.
2. Store tokens **per user** and **per device** (one user can have phone + tablet).
3. On **logout**, optionally **delete** that device’s token(s) so you do not notify a signed-out device.

### Suggested REST contract (example)

Base URL (current app): `https://a-plus.anmka.com/api`

| Method   | Path (example)                                     | Auth                | Body (JSON)                                                                           |
| -------- | -------------------------------------------------- | ------------------- | ------------------------------------------------------------------------------------- |
| `POST`   | `/auth/device-tokens` or `/users/me/device-tokens` | Bearer access token | `{ "fcm_token": "<string>", "platform": "android" \| "ios", "locale": "ar" \| "en" }` |
| `DELETE` | `/auth/device-tokens` or `/users/me/device-tokens` | Bearer              | `{ "fcm_token": "<string>" }` or delete all for session                               |

**Validation**

- `fcm_token`: non-empty string, max reasonable length (~400).
- `platform`: enum `android` | `ios` (helps debug and platform-specific payloads).

**Idempotency:** Upsert on `(user_id, fcm_token)` so repeated posts from the app are safe.

---

## 2. When the mobile app should call register (for frontend team / contract)

The backend should assume the client will call the register endpoint:

- After **login** / **register** success, once `FirebaseMessaging.instance.getToken()` resolves.
- On **`onTokenRefresh`** (token rotation).
- Optionally on **locale change** if you store locale for message language.

_(The app does not yet POST the token to your API automatically; wiring that is a small client change once this endpoint exists.)_

---

## 3. Sending pushes (FCM HTTP v1)

Use **Firebase Cloud Messaging API (HTTP v1)** with a **service account** JSON from the same Firebase project as the mobile app.

### 3.1 Notification vs data

- **`notification`**: OS shows a tray notification when app is in background/killed (typical marketing).
- **`data`**: key–value payload; useful for in-app routing when user taps. The Flutter app already has a background handler that can show a local notification when needed.

**Recommended** for most cases: send **both** `notification` (title/body) and `data` (deep link ids).

### 3.2 Example payload (illustrative)

```json
{
  "message": {
    "token": "<DEVICE_FCM_TOKEN>",
    "notification": {
      "title": "A Plus",
      "body": "You have a new assignment."
    },
    "data": {
      "type": "homework",
      "homework_id": "uuid-here",
      "click_action": "FLUTTER_NOTIFICATION_CLICK"
    },
    "android": {
      "priority": "HIGH"
    },
    "apns": {
      "headers": {
        "apns-priority": "10"
      },
      "payload": {
        "aps": {
          "sound": "default",
          "badge": 1
        }
      }
    }
  }
}
```

Adjust `type` / ids to match your product (course, lesson, exam, etc.).

### 3.3 iOS

- APNs key / certificates must be configured in Firebase Console.
- For rich features, follow FCM + APNs documentation.

### 3.4 Android

- Default channel: the app uses a high-importance channel for FCM-displayed notifications when handled in background; align with client if you add custom channels.

---

## 4. In-app notification list (existing API)

The app already has HTTP APIs for **in-app** notifications (list, mark read). Push is **additional**: it drives the system tray; the in-app inbox can stay the source of truth for history if you mirror events server-side.

---

## 5. Security & privacy

- Only send pushes to tokens bound to **your** `user_id` after authentication.
- Do not put secrets or PII in `data` fields that logs might capture; use opaque ids.
- Respect user preference if you add `push_notifications: false` (profile already has related fields in the client service — confirm with API spec).

---

## 6. Testing checklist for backend

1. Register token via new endpoint with a real device token from QA.
2. Send a test message via FCM v1 to that token.
3. Verify: **foreground**, **background**, and **terminated** (swipe away) behavior on Android and iOS.
4. Logout: token removed or ignored; no further pushes to that device for that user.

---

## 7. Contact

Coordinate **Firebase project ID** and **package name / bundle ID** with the mobile lead so FCM tokens match the same Firebase app used in `google-services.json` / `GoogleService-Info.plist`.
