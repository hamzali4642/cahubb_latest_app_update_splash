# Car Inspection and Sell It for Me — Backend API and Database Specification

This document defines the backend/database work required for the following mobile app flows:

1. Car Inspection
2. Sell It for Me

The two flows collect nearly identical information. The recommended implementation is one shared `service_requests` table and one shared create endpoint. The `service_type` field identifies the flow.

## 1. Database requirements

### New table: `service_requests`

| Column | Suggested type | Null | Rules / purpose |
|---|---|---:|---|
| `id` | BIGINT UNSIGNED, primary key | No | Auto-increment request ID. |
| `user_id` | BIGINT UNSIGNED, foreign key | Yes | Authenticated user who created the request. Keep nullable so a guest request can still be accepted using name and phone. This value must come from the authenticated token/session, not from the request body. |
| `service_type` | VARCHAR(30) or ENUM | No | Allowed values: `car_inspection`, `sell_for_me`. |
| `service_package_id` | BIGINT UNSIGNED, foreign key | No | Selected package from the existing service packages table. |
| `full_name` | VARCHAR(150) | No | Customer's full name. |
| `phone_number` | VARCHAR(30) | No | Store as text, not a number, so `+`, leading zeroes, and country codes are preserved. |
| `city_id` | BIGINT UNSIGNED, foreign key | No | Customer's living city from the existing cities table. |
| `car_model_id` | BIGINT UNSIGNED, foreign key | No | Selected car from the existing car models table. The related car model already provides model and brand names. |
| `model_year` | SMALLINT UNSIGNED | No | Vehicle model year. Current app choices range from 1990 through the current year. |
| `car_variant` | VARCHAR(150) | No | User-entered trim/variant, for example `Grande 1.8 CVT`. |
| `car_condition` | VARCHAR(10) or ENUM | No | Allowed values: `used`, `new`. |
| `registration_area` | VARCHAR(30) or ENUM | Yes | Required only for `sell_for_me`; must be null for `car_inspection`. Allowed values: `Punjab`, `KPK`, `Sindh`, `Balochistan`, `AJK`. |
| `visit_area` | VARCHAR(255) | No | User-entered area/address description where the team should visit. |
| `visit_date` | DATE | No | Requested visit date in `YYYY-MM-DD` format. |
| `visit_start_time` | TIME | No | Beginning of the selected one-hour slot, for example `10:00:00`. |
| `visit_end_time` | TIME | No | End of the selected slot, for example `11:00:00`. |
| `status` | VARCHAR(30) or ENUM | No | Default `pending`. Suggested values: `pending`, `confirmed`, `in_progress`, `completed`, `cancelled`. |
| `created_at` | TIMESTAMP | No | Created by the backend. |
| `updated_at` | TIMESTAMP | No | Updated by the backend. |

### Foreign keys

- `user_id` references the existing users table.
- `service_package_id` references the existing service packages table.
- `city_id` references the existing cities table.
- `car_model_id` references the existing car models table.
- Choose an appropriate delete policy for historical requests. `RESTRICT` or nullable foreign keys with `SET NULL` are preferable to deleting service request history.

### Recommended indexes

- Index `user_id`.
- Index `service_type`.
- Index `status`.
- Index `visit_date`.
- Composite index on (`service_type`, `status`, `visit_date`) for administration queues.
- Index all foreign-key columns if the database does not create these indexes automatically.

### Important database rules

- If `service_type = sell_for_me`, `registration_area` is required.
- If `service_type = car_inspection`, `registration_area` must be null.
- `visit_end_time` must be later than `visit_start_time`.
- The selected package must exist and its package `type` must match `service_type`.
- Do not accept `user_id`, `status`, `created_at`, or `updated_at` from the mobile request.
- Store dates/times consistently using the application's Pakistan timezone (`Asia/Karachi`) unless the backend has an existing UTC convention. Return the timezone or unambiguous date/time values in the response.

No separate inspection and selling tables are necessary because all shared fields describe the same kind of service lead. If the backend architecture requires separate tables, both tables still need all columns above; only `registration_area` differs.

## 2. Create service request API

### Endpoint

`POST /api/service-requests`

### Headers

- `Accept: application/json`
- `Content-Type: multipart/form-data` (the current Flutter API helper posts form data)
- `Authorization: Bearer <token>` when the user is logged in
- `Content-Language: <language-code>` may also be sent by the app

The endpoint should support an authenticated request. Guest support is recommended because the form itself collects contact information and currently does not enforce login. If backend policy requires authentication, return a normal `401` JSON response and state that requirement in the backend handoff document.

## 3. Fields sent by both app sections

| Request field | Type | Required | App source / accepted value |
|---|---|---:|---|
| `service_type` | string | Yes | `car_inspection` or `sell_for_me`. |
| `service_package_id` | integer | Yes | `ServicePackageModel.id` from the selected service package. |
| `full_name` | string | Yes | Trimmed user input; may initially be populated from the logged-in profile. |
| `phone_number` | string | Yes | Trimmed user input. Must remain a string. |
| `city_id` | integer | Yes | `City.id` selected from the existing cities API. |
| `car_model_id` | integer | Yes | `CarModelModel.id` selected from the existing car models API. |
| `model_year` | integer | Yes | Selected year, from 1990 through the current year. |
| `car_variant` | string | Yes | Trimmed user input. |
| `car_condition` | string | Yes | `used` when Used Car is selected; otherwise `new`. |
| `visit_area` | string | Yes | Trimmed user input from the Area field. |
| `visit_date` | string/date | Yes | Local calendar date formatted as `YYYY-MM-DD`. |
| `visit_start_time` | string/time | Yes | Selected slot start formatted as `HH:mm:ss`. Current starts are hourly from `10:00:00` to `16:00:00`. |
| `visit_end_time` | string/time | Yes | One hour after the start, formatted as `HH:mm:ss`; current values range from `11:00:00` to `17:00:00`. |

Display-only values such as package name/price, city name, car brand name, car model name, and the formatted time-slot label must not be sent as authoritative data. The backend should resolve them using the supplied IDs and times.

## 4. Car Inspection request

The app sends the common fields only. It does not send a registration area.

Example multipart form values represented as JSON for readability:

```json
{
  "service_type": "car_inspection",
  "service_package_id": 12,
  "full_name": "Ali Khan",
  "phone_number": "+923001234567",
  "city_id": 4,
  "car_model_id": 27,
  "model_year": 2022,
  "car_variant": "Grande 1.8 CVT",
  "car_condition": "used",
  "visit_area": "DHA Phase 6",
  "visit_date": "2026-07-18",
  "visit_start_time": "10:00:00",
  "visit_end_time": "11:00:00"
}
```

## 5. Sell It for Me request

The app sends all common fields plus `registration_area`.

| Additional request field | Type | Required | Accepted values |
|---|---|---:|---|
| `registration_area` | string | Yes | `Punjab`, `KPK`, `Sindh`, `Balochistan`, or `AJK`. |

Example multipart form values represented as JSON for readability:

```json
{
  "service_type": "sell_for_me",
  "service_package_id": 18,
  "full_name": "Ali Khan",
  "phone_number": "+923001234567",
  "city_id": 4,
  "car_model_id": 27,
  "model_year": 2022,
  "car_variant": "Grande 1.8 CVT",
  "car_condition": "used",
  "registration_area": "Punjab",
  "visit_area": "DHA Phase 6",
  "visit_date": "2026-07-18",
  "visit_start_time": "14:00:00",
  "visit_end_time": "15:00:00"
}
```

## 6. Backend validation

- `service_type`: required; one of `car_inspection`, `sell_for_me`.
- `service_package_id`: required integer; must exist; package type must equal `service_type`.
- `full_name`: required trimmed string; recommended maximum 150 characters.
- `phone_number`: required string; recommended maximum 30 characters; validate using the backend's existing phone rules without converting it to a number.
- `city_id`: required integer; must exist.
- `car_model_id`: required integer; must exist.
- `model_year`: required integer; minimum 1990; maximum current calendar year.
- `car_variant`: required trimmed string; recommended maximum 150 characters.
- `car_condition`: required; one of `used`, `new`.
- `registration_area`: required when `service_type` is `sell_for_me`; prohibited or ignored when it is `car_inspection`; must use an allowed value.
- `visit_area`: required trimmed string; recommended maximum 255 characters.
- `visit_date`: required valid `YYYY-MM-DD` date; must not be earlier than the current date in the agreed timezone.
- `visit_start_time` and `visit_end_time`: required valid times; end must be after start. Currently the app offers one-hour slots between 10:00 and 17:00.

The backend must validate all values independently; it must not depend on mobile-side validation.

## 7. Success response

Use the project's existing API envelope so the Flutter client can consume it consistently.

Recommended HTTP status: `201 Created`

```json
{
  "error": false,
  "message": "Service request submitted successfully.",
  "data": {
    "id": 101,
    "service_type": "car_inspection",
    "service_package_id": 12,
    "full_name": "Ali Khan",
    "phone_number": "+923001234567",
    "city_id": 4,
    "car_model_id": 27,
    "model_year": 2022,
    "car_variant": "Grande 1.8 CVT",
    "car_condition": "used",
    "registration_area": null,
    "visit_area": "DHA Phase 6",
    "visit_date": "2026-07-18",
    "visit_start_time": "10:00:00",
    "visit_end_time": "11:00:00",
    "status": "pending",
    "created_at": "2026-07-16T12:00:00+05:00"
  }
}
```

The response must at minimum return the new request `id`, `service_type`, `status`, and `message`.

## 8. Validation error response

Recommended HTTP status: `422 Unprocessable Entity`

```json
{
  "error": true,
  "message": "The given data was invalid.",
  "errors": {
    "phone_number": ["The phone number field is required."],
    "visit_date": ["The visit date must not be in the past."]
  }
}
```

Also use standard status codes where appropriate:

- `401` for a missing/invalid token if authentication is mandatory.
- `403` when the authenticated user cannot perform the action.
- `404` only for a genuinely missing referenced resource outside normal validation handling.
- `500` for an unexpected server failure without exposing stack traces or internal details.

## 9. Optional administration APIs

These are useful for managing the newly stored requests, but the mobile submission integration only requires the POST endpoint above.

- `GET /api/service-requests` — authenticated user's requests, or an admin-filtered list.
- `GET /api/service-requests/{id}` — request detail with package, city, car model, and user relations.
- `PATCH /api/service-requests/{id}/status` — admin updates status.

List APIs should support filtering by `service_type`, `status`, and visit-date range, and should use the project's normal pagination format.

## 10. Backend handoff checklist

When returning the completed backend documentation to the Flutter project, include:

- Final migration/table and column names.
- Final endpoint path and HTTP method.
- Whether authentication is required or guest requests are allowed.
- Exact request content type.
- Exact request field names and validation rules.
- Exact success and error response examples.
- Any field names or allowed values changed from this proposal.
- Whether package type matching is enforced.
- Date/time and timezone behavior.
- Any admin/list/detail endpoints that were also implemented.

