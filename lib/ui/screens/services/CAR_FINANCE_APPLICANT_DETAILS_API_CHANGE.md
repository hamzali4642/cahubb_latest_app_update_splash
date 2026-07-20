# MOBILE API CHANGE HANDOFF

## Car Finance Applicant Details

This document describes the changes required to the **existing car-finance request API** for the mobile application's new applicant-details screen.

The existing bank/configuration API remains unchanged:

```text
GET /api/car-finance-banks
```

Only the existing request endpoint must be extended:

```text
POST /api/car-finance-requests
```

Authentication remains required for submitting a finance request. The mobile app sends its existing Bearer token.

## New required request fields

Keep all existing finance fields (`finance_type`, `city_id`, `car_model_id`, `bank_id`, `tenure_years`, `down_payment_percent`, plus used-car fields where applicable). Add the following fields to every request.

| Field | Type | Validation / accepted values |
| --- | --- | --- |
| `full_name` | string | Required, trimmed, maximum 150 characters. |
| `phone_number` | string | Required, trimmed, maximum 30 characters. Allow digits, spaces, parentheses, hyphens, and an optional leading `+`. Store as text. |
| `email` | string | Required, valid email address, maximum 150 characters. Normalize by trimming and lowercasing. |
| `cnic` | string | Required. Exactly `12345-1234567-1` format after trimming: five digits, hyphen, seven digits, hyphen, one digit. |
| `income_source` | enum string | Required: `salaried` or `self_employed`. |
| `monthly_income` | enum string | Required: `above_80000`. Keep this enum extensible for future ranges. |
| `current_bank` | string | Required, trimmed, maximum 150 characters. It is free text; there is no bank dropdown or bank ID for this field. It is separate from the selected financing `bank_id`. |
| `has_credit_cards_or_loans` | boolean | Required. Accept JSON `true` / `false` and multipart `1` / `0`. |
| `processing_time` | enum string | Required: `next_2_weeks`, `next_month`, or `just_information`. |

`city_id` already exists in the request API. The applicant screen repeats the city picker, so the submitted `city_id` must always reflect its currently selected city.

## New-car example

```json
{
  "finance_type": "new_car",
  "city_id": 8,
  "car_model_id": 12,
  "bank_id": 3,
  "tenure_years": 5,
  "down_payment_percent": 30,
  "full_name": "Hamza Ali",
  "phone_number": "+92 300 1234567",
  "email": "hamza@example.com",
  "cnic": "35202-1234567-1",
  "income_source": "salaried",
  "monthly_income": "above_80000",
  "current_bank": "Meezan Bank",
  "has_credit_cards_or_loans": 0,
  "processing_time": "next_2_weeks"
}
```

For a new car, the mobile application still does **not** send `vehicle_price`. The backend uses the car model price, or its configured fallback price when the model has no usable price.

## Used-car example

```json
{
  "finance_type": "used_car",
  "city_id": 8,
  "car_model_id": 12,
  "model_year": 2021,
  "car_variant": "GLi Automatic",
  "used_car_price": 4200000,
  "bank_id": 3,
  "tenure_years": 5,
  "down_payment_percent": 30,
  "full_name": "Hamza Ali",
  "phone_number": "+92 300 1234567",
  "email": "hamza@example.com",
  "cnic": "35202-1234567-1",
  "income_source": "self_employed",
  "monthly_income": "above_80000",
  "current_bank": "HBL",
  "has_credit_cards_or_loans": true,
  "processing_time": "next_month"
}
```

## Database migration

Extend the existing `car_finance_requests` table. Do not create a second request table.

| Column | Suggested database type | Notes |
| --- | --- | --- |
| `full_name` | varchar(150) | Required. |
| `phone_number` | varchar(30) | Required. |
| `email` | varchar(150) | Required. |
| `cnic` | varchar(255) | Required; encrypt at rest if application encryption is available. |
| `income_source` | varchar(30) | Required enum value. |
| `monthly_income` | varchar(50) | Required enum value. |
| `current_bank` | varchar(150) | Required free-text field. |
| `has_credit_cards_or_loans` | boolean | Required. |
| `processing_time` | varchar(50) | Required enum value. |

The CNIC is sensitive personal information:

- Restrict it to authorized admin users.
- Mask it in list views and audit logs (for example `35202-*******-1`).
- Do not expose the raw CNIC in public/mobile API responses.

For a staged deployment, add the columns as nullable first, backfill only when applicable, then enforce `NOT NULL` for new submissions at the request-validation layer. Existing historic requests must remain readable.

## Validation failure response

Return HTTP `422 Unprocessable Entity` using the existing API error structure.

```json
{
  "error": true,
  "message": "The given data was invalid.",
  "errors": {
    "cnic": ["Please enter CNIC in 12345-1234567-1 format."],
    "income_source": ["Please select a valid source of income."],
    "has_credit_cards_or_loans": ["Please select whether you have credit cards or loans."]
  }
}
```

## Successful response change

Keep the current success structure and server-authoritative quote snapshot. Include the new non-sensitive applicant fields in `data` if the existing endpoint returns request details. Return `cnic_masked`, never raw `cnic`.

```json
{
  "error": false,
  "message": "Car finance request submitted successfully.",
  "data": {
    "id": 73,
    "status": "pending",
    "full_name": "Hamza Ali",
    "phone_number": "+92 300 1234567",
    "email": "hamza@example.com",
    "cnic_masked": "35202-*******-1",
    "income_source": "salaried",
    "monthly_income": "above_80000",
    "current_bank": "Meezan Bank",
    "has_credit_cards_or_loans": false,
    "processing_time": "next_2_weeks",
    "vehicle_price": 4500000,
    "monthly_installment": 89123,
    "total_initial_deposit": 1510000
  }
}
```

## Duplicate behavior

Keep the existing duplicate-active-request behavior and its HTTP `200` response. The existing request should be returned; do not create a second row. The mobile application treats both HTTP `200` and `201` as successful.

## Backend checklist

1. Add the nine columns above to `car_finance_requests`.
2. Add request validation and normalization for all nine fields.
3. Persist the supplied applicant details with the existing finance request and its server-calculated quote snapshot.
4. Protect and mask the CNIC in all responses, logs, and admin listings.
5. Leave `GET /api/car-finance-banks` unchanged.
