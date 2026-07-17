# Auction Sheet Verification — Backend API and Database Specification

This document defines the backend and database work required for the mobile app's **Auction Sheet Verification** flow.

The current app flow is:

1. The customer enters a Japanese vehicle chassis/frame number.
2. The customer taps **Verify Auction Sheet**.
3. The app opens a notification sheet and asks for a phone number.
4. The customer taps **Notify Me**.
5. The app submits the chassis number and phone number to the backend.
6. The backend stores the request so the team can find the auction sheet and notify the customer.

The first button only opens the phone-number sheet. The create API should be called only after both values are available and the customer taps **Notify Me**.

## 1. Database requirements

### New table: `auction_sheet_verification_requests`

| Column | Suggested type | Null | Rules / purpose |
|---|---|---:|---|
| `id` | BIGINT UNSIGNED, primary key | No | Auto-increment request ID. |
| `user_id` | BIGINT UNSIGNED, foreign key | Yes | The authenticated user who submitted the request. Keep nullable for guest requests. Resolve this value from the Bearer token; never accept it from the request body. |
| `chassis_number` | VARCHAR(50) | No | Japanese vehicle chassis/frame number, for example `NCP165-1234567`. Store a normalized uppercase value. |
| `phone_number` | VARCHAR(30) | No | Customer contact number. Store as text so `+`, country codes, and leading zeroes are preserved. |
| `status` | VARCHAR(30) or ENUM | No | Default `pending`. Suggested values: `pending`, `in_progress`, `completed`, `not_found`, `cancelled`. |
| `report_url` | TEXT | Yes | Private or signed URL/path for the verified auction-sheet report when available. This is managed by the backend/admin, not sent by the mobile create request. |
| `admin_notes` | TEXT | Yes | Internal processing notes. Never expose this field to an ordinary customer unless explicitly intended. |
| `notification_status` | VARCHAR(20) or ENUM | No | Default `pending`. Suggested values: `pending`, `sent`, `failed`. |
| `notified_at` | TIMESTAMP | Yes | Set when the customer notification is successfully sent. |
| `completed_at` | TIMESTAMP | Yes | Set when verification processing is completed. |
| `created_at` | TIMESTAMP | No | Created by the backend. |
| `updated_at` | TIMESTAMP | No | Updated by the backend. |

### Optional server-owned pricing columns

The current UI displays **PKR 2,950**, but it does not collect payment information and must not be trusted as the authoritative price source.

If the backend needs to snapshot pricing for each request, add:

| Column | Suggested type | Null | Rules / purpose |
|---|---|---:|---|
| `price_amount` | DECIMAL(12,2) | Yes | Server-calculated price at request creation. Do not accept it from the mobile request. |
| `currency_code` | CHAR(3) | Yes | For example `PKR`; assigned by the backend. |
| `payment_status` | VARCHAR(20) or ENUM | Yes | Only add if a payment workflow exists. Suggested values: `unpaid`, `pending`, `paid`, `failed`, `refunded`. |

This create API must not require payment fields unless a separate payment API contract is provided to the mobile project.

### Foreign key

- `user_id` references the existing users table.
- Prefer preserving request history. Use `SET NULL` if users may be deleted, or the project's established historical-data policy.

### Recommended indexes

- Index `user_id`.
- Index `chassis_number`.
- Index `phone_number`.
- Index `status`.
- Index `notification_status`.
- Composite index on (`status`, `created_at`) for the administration work queue.
- Composite index on (`chassis_number`, `phone_number`, `status`) for duplicate detection.

### Important database rules

- `user_id`, `status`, report fields, notification fields, pricing fields, and timestamps are server-owned.
- Normalize `chassis_number` before storing and comparing it.
- Preserve the customer's phone number as text.
- When `status` becomes `completed`, set `completed_at`.
- When a notification is successfully delivered, set `notification_status = sent` and `notified_at`.
- Report files must not be stored at a permanently public URL if they contain private or paid information. Prefer authorized downloads or expiring signed URLs.

## 2. Chassis-number normalization

The backend should apply the same normalization before validation, duplicate checks, and storage:

1. Trim leading and trailing whitespace.
2. Convert letters to uppercase.
3. Remove spaces inside the value.
4. Normalize Unicode dash variants to the ASCII hyphen `-`.
5. Do not remove the hyphen because it is a meaningful and common part of Japanese chassis/frame numbers.

Example:

` ncp165 - 1234567 ` becomes `NCP165-1234567`.

Recommended accepted characters after normalization are uppercase letters `A-Z`, digits `0-9`, and hyphens. Do not apply a strict 17-character VIN rule: Japanese chassis/frame numbers may not use the standard 17-character VIN format.

## 3. Create verification request API

### Endpoint

`POST /api/auction-sheet-verification-requests`

### Request content type

`multipart/form-data`

This matches the existing Flutter API helper.

### Headers

- `Accept: application/json`
- `Content-Type: multipart/form-data`
- `Content-Language: <language-code>`
- `Authorization: Bearer <token>` when the customer is logged in

Authentication should be optional, matching the other service-request APIs:

- With a valid token, connect the request to the authenticated user.
- Without a token, create a guest request using the submitted phone number.
- Do not accept `user_id` from the mobile app.

## 4. Request fields sent by the mobile app

| Request field | Type | Required | Source / accepted value |
|---|---|---:|---|
| `chassis_number` | string | Yes | Customer input from the **Enter chassis number** field. Trimmed and normalized by both client and backend. Maximum 50 characters after normalization. |
| `phone_number` | string | Yes | Customer input from the **Phone number** field. It may initially be populated from the logged-in profile. Maximum 30 characters. |

The mobile app must not send:

- `user_id`
- `status`
- `report_url`
- `admin_notes`
- `notification_status`
- `notified_at`
- `completed_at`
- `price_amount`
- `currency_code`
- `payment_status`
- `created_at`
- `updated_at`

Example multipart values represented as JSON for readability:

```json
{
  "chassis_number": "NCP165-1234567",
  "phone_number": "+923001234567"
}
```

## 5. Backend validation

### `chassis_number`

- Required.
- Must be a string.
- Normalize it before applying the remaining validation rules.
- Maximum 50 characters after normalization.
- Must contain only uppercase letters, digits, and hyphens after normalization.
- Must contain at least one letter and at least one digit.
- Must not consist only of separators.
- Do not enforce a standard 17-character VIN rule.

Suggested validation expression after normalization:

`^[A-Z0-9]+(?:-[A-Z0-9]+)*$`

### `phone_number`

- Required.
- Must be treated as a string.
- Maximum 30 characters.
- Trim leading and trailing whitespace.
- Permit an optional leading `+` and commonly used phone separators if that matches the project's existing phone-number policy.
- Do not convert it to an integer.

The backend must validate all values independently and must not rely only on mobile-side validation.

## 6. Duplicate request handling

Repeated taps or network retries must not create many identical active requests.

Recommended rule:

- Before inserting, look for an active request with the same normalized `chassis_number` and normalized `phone_number` whose status is `pending` or `in_progress`.
- If found, return that existing request with HTTP `200 OK`, `error: false`, and a message explaining that an active request already exists.
- Otherwise create a new request and return HTTP `201 Created`.

Do not use a permanent unique constraint across chassis and phone because the same customer may legitimately request verification again after an older request is completed, not found, or cancelled.

## 7. Successful create response

Recommended HTTP status: `201 Created`

```json
{
  "error": false,
  "message": "Auction sheet verification request submitted successfully.",
  "data": {
    "id": 73,
    "chassis_number": "NCP165-1234567",
    "phone_number": "+923001234567",
    "status": "pending",
    "notification_status": "pending",
    "report_url": null,
    "created_at": "2026-07-17T12:00:00+05:00"
  }
}
```

The response must at minimum return:

- `data.id`
- `data.chassis_number`
- `data.status`
- `message`

## 8. Existing active request response

Recommended HTTP status: `200 OK`

```json
{
  "error": false,
  "message": "An active verification request already exists for this chassis number and phone number.",
  "data": {
    "id": 73,
    "chassis_number": "NCP165-1234567",
    "phone_number": "+923001234567",
    "status": "in_progress",
    "notification_status": "pending",
    "report_url": null,
    "created_at": "2026-07-17T12:00:00+05:00"
  }
}
```

The mobile app should treat both `200` and `201` responses with `error: false` and a valid `data.id` as successful submissions.

## 9. Validation error response

Recommended HTTP status: `422 Unprocessable Entity`

```json
{
  "error": true,
  "message": "The given data was invalid.",
  "errors": {
    "chassis_number": [
      "Please enter a valid Japanese chassis number."
    ],
    "phone_number": [
      "The phone number field is required."
    ]
  }
}
```

The `errors` object must be keyed by request field name, with an array of messages for each field. The mobile app will show the first useful field error or the top-level message as a fallback.

## 10. Server error response

Recommended HTTP status: `500 Internal Server Error`

```json
{
  "error": true,
  "message": "Unable to submit the auction sheet verification request. Please try again."
}
```

Do not expose database errors, stack traces, filesystem paths, credentials, or internal exception details.

## 11. Request detail API

This API is recommended so the mobile app or customer-support tooling can check request progress later.

### Endpoint

`GET /api/auction-sheet-verification-requests/{id}`

### Access rules

- An authenticated customer may access only their own request.
- Guest lookup must not expose data using a predictable numeric ID alone. If guest tracking is required, use a separate unguessable public token or an OTP-protected lookup flow.
- Admin users may access requests according to existing role/permission rules.
- `admin_notes` must not be returned to ordinary customers.

Example customer response:

```json
{
  "error": false,
  "message": "Auction sheet verification request fetched successfully.",
  "data": {
    "id": 73,
    "chassis_number": "NCP165-1234567",
    "status": "completed",
    "notification_status": "sent",
    "report_url": "https://example.com/temporary-signed-report-url",
    "notified_at": "2026-07-17T14:15:00+05:00",
    "completed_at": "2026-07-17T14:10:00+05:00",
    "created_at": "2026-07-17T12:00:00+05:00"
  }
}
```

## 12. Recommended administration APIs

These endpoints are useful for processing stored requests. Their authorization must be restricted to admins/staff.

- `GET /api/admin/auction-sheet-verification-requests`
  - Paginated list.
  - Filters: `status`, `notification_status`, `chassis_number`, `phone_number`, and created-date range.
- `GET /api/admin/auction-sheet-verification-requests/{id}`
  - Full request detail, including user relation and internal notes.
- `PATCH /api/admin/auction-sheet-verification-requests/{id}`
  - Update processing status and internal notes.
- `POST /api/admin/auction-sheet-verification-requests/{id}/report`
  - Upload or associate the verified report and mark the request completed according to backend workflow.
- `POST /api/admin/auction-sheet-verification-requests/{id}/notify`
  - Send or retry the customer notification.

### Suggested administration status transitions

- `pending` → `in_progress`
- `in_progress` → `completed`
- `pending` or `in_progress` → `not_found`
- `pending` or `in_progress` → `cancelled`

Prevent invalid transitions unless an authorized administrator explicitly overrides them with an audited reason.

## 13. Notification behavior

When the report becomes available:

1. Store/associate the report securely.
2. Set request `status = completed` and `completed_at`.
3. Send an SMS or the project's supported notification to `phone_number`.
4. If the request belongs to an authenticated user, an in-app notification may also be created.
5. On successful delivery, set `notification_status = sent` and `notified_at`.
6. On failure, set `notification_status = failed` while leaving enough internal information for a retry. Do not expose provider secrets or raw sensitive errors to customers.

Notification sending should be queued so report processing/admin requests do not block on an external SMS provider.

## 14. Backend handoff checklist

When returning the completed backend documentation to the Flutter project, include:

- Final migration/table and column names.
- Final create endpoint path and HTTP method.
- Whether authentication is optional as proposed.
- Exact request content type and field names.
- Exact chassis normalization and validation rules.
- Exact success, duplicate, validation-error, and server-error responses.
- Final status and notification-status values.
- Duplicate active-request behavior.
- Whether price/payment fields were added and how the authoritative price is obtained.
- Whether request detail/history APIs were implemented.
- How report URLs are authorized and how long signed URLs remain valid.
- Admin endpoints and permitted status transitions.
- Notification provider/workflow and retry behavior.

