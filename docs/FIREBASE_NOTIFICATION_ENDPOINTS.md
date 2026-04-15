# Firebase Notification Endpoints

This file documents the Firebase-related notification endpoints currently available in the LMS backend.

## Base URL

- Backend base: `/api`
- Admin routes require admin auth (`Authorization: Bearer <token>`)
- User token registration requires authenticated user (`Authorization: Bearer <token>`)

## Standard Success Envelope

All endpoints use the same success shape:

```json
{
  "data": {},
  "success": true,
  "message": "..."
}
```

Validation and other errors return `success: false` with an error message.

---

## 1) Register/Update User FCM Token

Registers a device token for the currently logged-in user. This token is later used for Firebase push delivery.

- **Method:** `POST`
- **Endpoint:** `/api/auth/fcm-token`
- **Auth:** Required (any authenticated user)

### Request Body

```json
{
  "token": "fcm_device_token_here",
  "platform": "android",
  "device_id": "device-123",
  "app_version": "1.0.0"
}
```

### Body Fields

| Field | Type | Required | Notes |
|---|---|---:|---|
| `token` | string | Yes | Min length 10 |
| `platform` | string | No | `android` \| `ios` \| `web` |
| `device_id` | string | No | Max 200 chars |
| `app_version` | string | No | Max 50 chars |

### Success Response (200)

```json
{
  "data": {
    "id": "2f9f5d88-8f42-4f45-9a1c-8c3f9d5f4e31",
    "token": "fcm_device_token_here",
    "platform": "android",
    "deviceId": "device-123",
    "appVersion": "1.0.0",
    "isActive": true
  },
  "success": true,
  "message": "تم تحديث FCM token بنجاح"
}
```

### Example Validation Error (400)

```json
{
  "success": false,
  "message": "خطأ في البيانات المدخلة",
  "errors": {
    "token": "FCM token مطلوب"
  }
}
```

---

## 2) Send Firebase Push To Students (Direct)

Sends a push notification immediately to:
- all active students (bulk), or
- specific students by `userIds` (single or multi-send).

Also stores the notification in DB and creates recipient records.

- **Method:** `POST`
- **Endpoint:** `/api/admin/notifications/push/students`
- **Auth:** Required (admin)

### Request Body (Bulk to all students)

```json
{
  "title": "تنبيه مهم",
  "body": "يرجى فتح التطبيق للاطلاع على الجديد",
  "deepLink": "app://dashboard"
}
```

### Request Body (Specific students)

```json
{
  "title": "تنبيه خاص",
  "body": "هذه رسالة موجهة لمجموعة محددة",
  "userIds": [
    "student-user-id-1",
    "student-user-id-2"
  ],
  "deepLink": "app://courses/123",
  "data": {
    "type": "announcement",
    "priority": "high"
  }
}
```

### Body Fields

| Field | Type | Required | Notes |
|---|---|---:|---|
| `title` | string | Yes | Max 255 chars |
| `body` | string | Yes | Notification message |
| `deepLink` | string | No | Max 500 chars |
| `userIds` | string[] | No | If omitted, sends to all active students |
| `data` | object | No | Key/value payload (`string/number/boolean`) |

### Success Response (200)

```json
{
  "data": {
    "id": "notification-id",
    "title": "تنبيه خاص",
    "body": "هذه رسالة موجهة لمجموعة محددة",
    "targetAudience": "specific",
    "sentAt": "2026-04-15T09:00:00.000Z",
    "pushStats": {
      "targetedUsers": 2,
      "targetedTokens": 2,
      "sentCount": 2,
      "failedCount": 0,
      "skipped": false,
      "reason": null
    }
  },
  "success": true,
  "message": "تم إرسال إشعار Firebase للطلاب بنجاح"
}
```

### Example Validation Error (400)

```json
{
  "success": false,
  "message": "خطأ في البيانات المدخلة",
  "errors": {
    "title": "عنوان الإشعار مطلوب"
  }
}
```

---

## 3) Send Existing Notification By ID (Firebase + In-app)

If you already created a notification draft/scheduled notification, you can send it now.

- **Method:** `POST`
- **Endpoint:** `/api/admin/notifications/:id/send`
- **Auth:** Required (admin)

### Request Body

No body required.

### Success Response (200)

```json
{
  "data": {
    "id": "notification-id",
    "status": "sent",
    "sentAt": "2026-04-15T09:00:00.000Z",
    "pushStats": {
      "targetedUsers": 150,
      "targetedTokens": 120,
      "sentCount": 118,
      "failedCount": 2,
      "skipped": false,
      "reason": null
    }
  },
  "success": true,
  "message": "تم إرسال الإشعار بنجاح"
}
```

### Common Error (404)

```json
{
  "success": false,
  "message": "الإشعار غير موجود"
}
```

---

## Notes

- Firebase delivery depends on server env configuration (e.g. valid `FIREBASE_SERVER_KEY`).
- Invalid/unregistered device tokens are automatically marked inactive during send attempts.
- Frontend proxy route for admin direct push is available at:
  - `/api/admin/notifications/push/students` (Next.js API route, proxied to backend).
