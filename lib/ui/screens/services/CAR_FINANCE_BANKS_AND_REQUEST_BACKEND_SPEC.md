# Car Finance Banks and Application Request — Backend Specification

This document defines the database and API requirements for:

1. Loading active car-finance banks, rates, and fees.
2. Submitting a customer's selected car-finance application/request.

The backend must become the authoritative source for bank rates, insurance rates, processing fees, and final calculation snapshots. The mobile app may calculate values for immediate display, but the backend must independently recalculate and store them when an application is submitted.

## 1. Current mobile flow

The current app collects:

- Finance type: new car or used car.
- Customer's city.
- Selected car model.
- Used-car model year, variant, and entered price when the used-car flow is selected.
- Tenure in years.
- Down-payment percentage.
- Selected finance bank.

The current finance form does **not** collect full name or phone number.

### Authentication decision

The recommended first implementation requires authentication for finance-request submission so every request has a contactable user account:

- The banks API is public.
- The finance-request API requires `Authorization: Bearer <token>`.
- The backend resolves `user_id` from the token. The app must not send `user_id`.

If guest finance applications are required, the mobile form and backend contract must both be extended with required `full_name` and `phone_number` fields. Do not accept anonymous finance requests without any way to contact the customer.

## 2. New-car price rule

For a new car, the authoritative calculation price is resolved from the selected existing car model:

1. Use the selected car model's `price` returned by `GET /api/get-car-models` when it is non-null and greater than zero.
2. If that price is null, zero, or otherwise unavailable, temporarily use **PKR 5,000,000** (50 lacs).

Mobile calculation rule:

```text
new_car_price = selectedCar.price ?? 5000000
```

The mobile implementation should also treat a non-positive value as unavailable and use PKR 5,000,000.

Backend submission rule:

- Do not trust or require a client-provided new-car price.
- Resolve the current `car_models.price` using `car_model_id`.
- Use PKR 5,000,000 when the database price is null or non-positive.
- Store the resolved amount in the finance request as `vehicle_price`.
- Store `price_source = car_model` when the database price is used.
- Store `price_source = temporary_fallback` when PKR 5,000,000 is used.

The fallback is temporary. Prefer moving it to an existing system-settings mechanism later so it can be changed without publishing a new mobile build.

For a used car, use the price entered by the customer and sent as `used_car_price`. Store `price_source = customer_input`.

## 3. Database: finance banks

### New table: `car_finance_banks`

| Column | Suggested type | Null | Rules / purpose |
|---|---|---:|---|
| `id` | BIGINT UNSIGNED, primary key | No | Auto-increment bank/plan ID sent by the app as `bank_id`. |
| `code` | VARCHAR(50), unique | No | Stable code, for example `faysal`, `micar`, or `dib`. Do not use the display name as an identifier. |
| `name` | VARCHAR(150) | No | Customer-facing finance plan/bank name. |
| `finance_rate` | DECIMAL(7,4) | No | Annual finance rate percentage, for example `15.6400`. |
| `insurance_rate` | DECIMAL(7,4) | No | First-year insurance percentage, for example `1.5000`. |
| `processing_fee` | BIGINT UNSIGNED | No | Processing fee in PKR whole units. |
| `logo_url` | TEXT | Yes | Optional bank/plan logo URL. |
| `accent_color` | CHAR(7) | Yes | Optional UI color in `#RRGGBB` format. |
| `is_active` | BOOLEAN | No | Default true. Only active records are returned publicly. |
| `display_order` | INTEGER UNSIGNED | No | Default zero; controls bank-list ordering. |
| `created_at` | TIMESTAMP | No | Created by the backend. |
| `updated_at` | TIMESTAMP | No | Updated by the backend. |

### Recommended constraints and indexes

- Unique index on `code`.
- Index (`is_active`, `display_order`).
- All rate values must be greater than or equal to zero.
- `processing_fee` must be greater than or equal to zero.
- Validate `accent_color` as a six-digit hex color when supplied.
- Prefer deactivating a bank instead of deleting it because finance requests retain a foreign-key reference and calculation snapshot.

### Initial bank records

Create initial database records matching the plans currently displayed by the app:

| Code | Name | Finance rate | Insurance rate | Processing fee | Accent color |
|---|---|---:|---:|---:|---|
| `faysal` | Faysal Car Finance | 15.64% | 1.50% | 12000 | `#1B6B9A` |
| `micar` | MI Car | 14.64% | 1.29% | 8000 | `#1F7A3E` |
| `dib` | DIB Auto Finance | 14.64% | 1.75% | 8350 | `#0E8D6A` |
| `mcb` | MCB Car4U | 15.64% | 1.75% | 12000 | `#1D8E49` |
| `albaraka` | Al Baraka Carsaaz | 15.72% | 1.50% | 8120 | `#C84B31` |
| `alfalah` | Alfalah Car Financing | 14.95% | 1.60% | 10000 | `#D62828` |

These values must be editable by authorized admin users. After the API integration, the mobile app must not keep these rates and fees as authoritative hardcoded values.

## 4. API 1 — Get finance banks

### Endpoint

`GET /api/car-finance-banks`

### Authentication

Public; no token is required.

### Recommended headers

- `Accept: application/json`
- `Content-Language: <language-code>`

### Successful response

HTTP status: `200 OK`

```json
{
  "error": false,
  "message": "Car finance banks fetched successfully.",
  "data": {
    "banks": [
      {
        "id": 1,
        "code": "faysal",
        "name": "Faysal Car Finance",
        "finance_rate": "15.6400",
        "insurance_rate": "1.5000",
        "processing_fee": 12000,
        "logo_url": null,
        "accent_color": "#1B6B9A"
      },
      {
        "id": 2,
        "code": "micar",
        "name": "MI Car",
        "finance_rate": "14.6400",
        "insurance_rate": "1.2900",
        "processing_fee": 8000,
        "logo_url": null,
        "accent_color": "#1F7A3E"
      }
    ],
    "tenure_options": [1, 2, 3, 4, 5],
    "down_payment_options": [40, 45, 50, 55, 60, 65, 70],
    "new_car_fallback_price": 5000000,
    "currency_code": "PKR"
  }
}
```

### Response requirements

- Return only active banks.
- Order by `display_order`, then by `id`.
- Rates may be returned as numeric strings or JSON numbers; document the final choice. The mobile app will parse either form as decimal values.
- `processing_fee` and `new_car_fallback_price` are PKR amounts.
- `tenure_options` currently support 1 through 5 years.
- `down_payment_options` currently support 40% through 70% in 5% increments.
- The API must return at least one bank to enable quote comparison and application submission.

### Empty or unavailable banks

If no active bank exists, return a successful empty list with a useful message, or the project's standard no-data response. The mobile app must show that finance plans are currently unavailable and must not continue to application submission.

## 5. Database: finance requests

### New table: `car_finance_requests`

| Column | Suggested type | Null | Rules / purpose |
|---|---|---:|---|
| `id` | BIGINT UNSIGNED, primary key | No | Auto-increment request ID. |
| `user_id` | BIGINT UNSIGNED, foreign key | No | Authenticated applicant, resolved from the Bearer token. |
| `car_finance_bank_id` | BIGINT UNSIGNED, foreign key | No | Selected active finance bank/plan. |
| `city_id` | BIGINT UNSIGNED, foreign key | No | Customer's selected city. |
| `car_model_id` | BIGINT UNSIGNED, foreign key | No | Selected existing car model. |
| `finance_type` | VARCHAR(20) or ENUM | No | Allowed values: `new_car`, `used_car`. |
| `model_year` | SMALLINT UNSIGNED | Yes | Required for `used_car`; null for `new_car` unless later collected. |
| `car_variant` | VARCHAR(150) | Yes | Required for `used_car`; null for `new_car` unless later collected. |
| `used_car_price` | BIGINT UNSIGNED | Yes | Required only for `used_car`; null for `new_car`. |
| `vehicle_price` | BIGINT UNSIGNED | No | Server-resolved price used for calculations. |
| `price_source` | VARCHAR(30) or ENUM | No | `car_model`, `temporary_fallback`, or `customer_input`. |
| `tenure_years` | SMALLINT UNSIGNED | No | Selected allowed tenure. |
| `down_payment_percent` | DECIMAL(5,2) | No | Selected allowed down-payment percentage. |
| `finance_rate` | DECIMAL(7,4) | No | Snapshot of the selected bank's rate at submission time. |
| `insurance_rate` | DECIMAL(7,4) | No | Snapshot of the selected bank's insurance rate. |
| `processing_fee` | BIGINT UNSIGNED | No | Snapshot of the selected bank's fee. |
| `down_payment_amount` | BIGINT UNSIGNED | No | Server-calculated snapshot. |
| `bank_loan` | BIGINT UNSIGNED | No | Server-calculated snapshot. |
| `first_year_insurance` | BIGINT UNSIGNED | No | Server-calculated snapshot. |
| `monthly_installment` | BIGINT UNSIGNED | No | Server-calculated estimated monthly installment. |
| `total_initial_deposit` | BIGINT UNSIGNED | No | Down payment + processing fee + first-year insurance. |
| `status` | VARCHAR(30) or ENUM | No | Default `pending`. Suggested values: `pending`, `in_progress`, `approved`, `rejected`, `completed`, `cancelled`. |
| `admin_notes` | TEXT | Yes | Internal notes not exposed to the customer. |
| `created_at` | TIMESTAMP | No | Created by the backend. |
| `updated_at` | TIMESTAMP | No | Updated by the backend. |

### Foreign keys and deletion behavior

- `user_id` references the existing users table.
- `car_finance_bank_id` references `car_finance_banks`.
- `city_id` references the existing cities table.
- `car_model_id` references the existing car models table.
- Preserve finance-request history. Deactivate banks rather than deleting them. Use the project's established historical-data policy for users, cities, and car models.

### Recommended indexes

- Index `user_id`.
- Index `car_finance_bank_id`.
- Index `city_id`.
- Index `car_model_id`.
- Index `finance_type`.
- Index `status`.
- Composite index (`status`, `created_at`) for the admin queue.
- Composite index (`user_id`, `status`) for a customer's active requests.

## 6. Finance calculation rules

The backend must recalculate all quote values using the selected bank's current database values. Do not accept calculated amounts or rate snapshots from the mobile request.

Given:

- `P` = resolved vehicle price.
- `D` = selected down-payment percentage.
- `Y` = selected tenure in years.
- `F` = selected bank finance-rate percentage.
- `I` = selected bank first-year insurance-rate percentage.
- `processing_fee` = selected bank processing fee.

Use the same formulas as the current mobile calculator:

```text
down_payment_amount = round(P * D / 100)
bank_loan = P - down_payment_amount
first_year_insurance = round(P * I / 100)
total_repayable = bank_loan * (1 + (F / 100 * Y))
monthly_installment = round(total_repayable / (Y * 12))
total_initial_deposit = down_payment_amount + processing_fee + first_year_insurance
```

All calculated PKR values are currently displayed and stored as whole rupees.

These are estimates. The response and UI must retain the disclaimer that final values may vary due to KIBOR or other bank-variable rates.

## 7. API 2 — Submit finance request

### Endpoint

`POST /api/car-finance-requests`

### Authentication

Required for the initial implementation:

`Authorization: Bearer <token>`

Return `401 Unauthorized` when the token is missing or invalid.

### Content type

`multipart/form-data` is preferred to match the current Flutter API helper. `application/json` may also be supported if desired.

### Common request fields

| Field | Type | Required | Rules |
|---|---|---:|---|
| `finance_type` | string | Yes | `new_car` or `used_car`. |
| `city_id` | integer | Yes | Must exist in cities. |
| `car_model_id` | integer | Yes | Must exist in car models. |
| `bank_id` | integer | Yes | Must reference an active `car_finance_banks` record. |
| `tenure_years` | integer | Yes | Must be one of the values returned by the banks API; currently 1–5. |
| `down_payment_percent` | integer/decimal | Yes | Must be one of the returned options; currently 40, 45, 50, 55, 60, 65, or 70. |

### Fields for a new car

- Do not send `used_car_price`.
- Do not send `model_year` or `car_variant` unless those inputs are added to the new-car UI later.
- Do not send `vehicle_price`.
- The backend resolves `vehicle_price` from `car_models.price`, falling back to PKR 5,000,000.

Example new-car request:

```json
{
  "finance_type": "new_car",
  "city_id": 4,
  "car_model_id": 27,
  "bank_id": 1,
  "tenure_years": 3,
  "down_payment_percent": 40
}
```

### Additional required fields for a used car

| Field | Type | Required | Rules |
|---|---|---:|---|
| `model_year` | integer | Yes | Minimum 1990; maximum current year. |
| `car_variant` | string | Yes | Trimmed; maximum 150 characters. |
| `used_car_price` | integer | Yes | Positive PKR whole amount entered by the customer. |

Example used-car request:

```json
{
  "finance_type": "used_car",
  "city_id": 4,
  "car_model_id": 27,
  "model_year": 2022,
  "car_variant": "Grande 1.8 CVT",
  "used_car_price": 7200000,
  "bank_id": 2,
  "tenure_years": 3,
  "down_payment_percent": 45
}
```

### Fields the app must not send

- `user_id`
- New-car `vehicle_price`
- `price_source`
- Bank rates
- Processing fee
- Down-payment amount
- Bank-loan amount
- Insurance amount
- Monthly installment
- Total initial deposit
- Status
- Admin notes
- Timestamps

## 8. Backend validation

- `finance_type`: required; one of `new_car`, `used_car`.
- `city_id`: required integer; must exist.
- `car_model_id`: required integer; must exist.
- `bank_id`: required integer; must reference an active bank.
- `tenure_years`: required integer; must be an allowed option.
- `down_payment_percent`: required numeric value; must be an allowed option and must be greater than zero and less than 100.
- `model_year`: required only for `used_car`; prohibited or ignored for `new_car`; minimum 1990; maximum current year.
- `car_variant`: required only for `used_car`; prohibited or ignored for `new_car`; trimmed; maximum 150 characters.
- `used_car_price`: required positive integer for `used_car`; prohibited or ignored for `new_car`.
- The backend must reject unsupported fields that attempt to override calculated values, prices, rates, status, or `user_id`.

The backend must validate all fields independently and perform the create operation and calculation snapshot inside a database transaction.

## 9. Successful response

HTTP status: `201 Created`

```json
{
  "error": false,
  "message": "Car finance request submitted successfully.",
  "data": {
    "id": 81,
    "finance_type": "new_car",
    "city_id": 4,
    "car_model_id": 27,
    "bank": {
      "id": 1,
      "code": "faysal",
      "name": "Faysal Car Finance"
    },
    "vehicle_price": 5000000,
    "price_source": "temporary_fallback",
    "tenure_years": 3,
    "down_payment_percent": 40,
    "finance_rate": "15.6400",
    "insurance_rate": "1.5000",
    "processing_fee": 12000,
    "down_payment_amount": 2000000,
    "bank_loan": 3000000,
    "first_year_insurance": 75000,
    "monthly_installment": 122433,
    "total_initial_deposit": 2087000,
    "status": "pending",
    "created_at": "2026-07-18T12:00:00+05:00"
  }
}
```

The response must at minimum return a valid `data.id`, `data.status`, resolved price, price source, bank identity, and server-calculated quote amounts.

## 10. Validation error response

HTTP status: `422 Unprocessable Entity`

```json
{
  "error": true,
  "message": "The given data was invalid.",
  "errors": {
    "bank_id": [
      "The selected finance bank is unavailable."
    ],
    "used_car_price": [
      "The used car price field is required for used-car finance."
    ]
  }
}
```

The `errors` object must be keyed by field name, with an array of messages. The mobile app will show the first useful field message or the top-level message as a fallback.

## 11. Authentication error response

HTTP status: `401 Unauthorized`

```json
{
  "error": true,
  "message": "Please sign in to submit a car finance request."
}
```

## 12. Server error response

HTTP status: `500 Internal Server Error`

```json
{
  "error": true,
  "message": "Unable to submit the car finance request. Please try again."
}
```

Do not expose database errors, stack traces, credentials, internal paths, or provider details.

## 13. Duplicate active-request handling

Recommended behavior:

- Check for an existing request for the same `user_id`, `car_model_id`, `car_finance_bank_id`, `finance_type`, and active status (`pending` or `in_progress`).
- If the tenure and down-payment choice also match, return the existing request with HTTP `200 OK` and `error: false` instead of creating another row.
- Otherwise allow a distinct application because a user may intentionally compare or apply for different finance terms or banks.
- Allow a new matching request after the older request is approved, rejected, completed, or cancelled.

The mobile app should treat both HTTP `200` and `201` responses with `error: false` and a valid `data.id` as successful.

## 14. Recommended admin APIs

### Finance banks

- `GET /api/admin/car-finance-banks`
- `POST /api/admin/car-finance-banks`
- `PATCH /api/admin/car-finance-banks/{id}`
- Deactivate a bank through update instead of destructive deletion.

### Finance requests

- `GET /api/admin/car-finance-requests`
- `GET /api/admin/car-finance-requests/{id}`
- `PATCH /api/admin/car-finance-requests/{id}`

Recommended request filters:

- `status`
- `user_id`
- `bank_id`
- `city_id`
- `car_model_id`
- `finance_type`
- created-date range

Suggested status transitions:

- `pending` → `in_progress`
- `in_progress` → `approved` or `rejected`
- `approved` → `completed`
- Active requests → `cancelled`

Admin endpoints must enforce existing role and permission rules. Rate changes and finance-request status changes should be auditable.

## 15. Backend handoff checklist

When returning the completed backend documentation to the Flutter project, include:

- Final table and migration names.
- Final bank-list and finance-request endpoint paths.
- Exact bank response model and decimal field formats.
- Final tenure and down-payment options.
- Confirmation of the PKR 5,000,000 temporary new-car fallback.
- Exact new-car and used-car request fields.
- Whether authentication is required or a coordinated guest contact flow was added.
- Exact server calculation formulas and rounding rules.
- Exact success, duplicate, validation, authentication, and server-error responses.
- Final status values and duplicate behavior.
- Admin bank-management and request-management endpoints.
- Any changes from this proposal that the mobile client must follow.

