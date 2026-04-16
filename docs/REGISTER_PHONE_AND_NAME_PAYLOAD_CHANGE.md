# Register Payload Change (Name + Phone)

This handoff documents a breaking update in the mobile register request payload.

## What Changed in Mobile

Mobile register form now uses:

- One text field for full name (instead of 4 separate name parts)
- Phone number input without country code (local digits only)

## Updated Request Body (`POST /api/auth/register`)

```json
{
  "name": "محمد أحمد علي حسن",
  "national_id": "12345678901234",
  "code": "A12345",
  "phone": "01012345678",
  "faculty_id": "1",
  "section_id": "2",
  "grade_id": "3",
  "device_id": "device-uuid",
  "fcm_token": "firebase-token-if-available"
}
```

## Removed Fields

These fields are no longer sent by the app:

- `name_first`
- `name_father`
- `name_grandfather`
- `name_family`

## Required Backend Update

Please update register endpoint validation and DTO/model mapping to:

1. Accept and use `name` as the canonical full name.
2. Stop requiring `name_first`, `name_father`, `name_grandfather`, `name_family`.
3. Accept `phone` as local number only (no `+` country code), e.g. `01012345678`.
4. If E.164 is required internally, normalize on backend using default country policy.

## Backward Compatibility (Recommended)

To avoid temporary breakage during deployment:

- Keep support for old payload for a short transition window.
- Prefer `name` if present; fallback to joining old name-part fields if needed.

## App-Side Status

Already implemented in mobile:

- Register screen UI uses one full-name field.
- Phone field no longer has country code selector.
- Register API call now sends local `phone` digits and full `name` only.
