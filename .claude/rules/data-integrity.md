# Data Integrity Rules

## Fitness Data Validation
- Weight values: must be positive, < 2000 lbs / 900 kg
- Rep counts: must be positive integers, < 200
- Set counts: must be positive integers, < 50
- Duration: must be positive, < 1440 minutes (24 hours)
- Calories: must be non-negative, daily totals < 15,000 kcal
- Body weight: must be positive, 50–700 lbs / 23–320 kg range (flag outliers, don't reject)

## Schema Contract Rules
- Never drop columns from an existing table without a migration + data preservation plan
- Never rename fields in the API response without a versioning plan
- Workout logs are append-only — edits create correction records, not overwrites
- User body metrics are time-series — never update in place, always insert with timestamp

## Calculation Precision
- Store weights to 1 decimal place (e.g., 135.5 lbs)
- Store body metrics to 1 decimal place
- Display calories as integers
- Display percentages to 1 decimal place

## User Privacy
- All user data is private by default
- No data sharing without explicit opt-in per feature
- Never log personal health metrics to application logs
- Anonymize any data used for aggregate analytics

## Failure Mode Policy
- Fail loudly on data integrity errors — raise exceptions, surface to user
- Never silently swallow a failed workout save — the user's effort must be preserved
- On calculation error, show "—" not "0" — zero is a valid value, unknown is not
