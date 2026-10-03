# Airbyte sources

All six use the **File** source connector reading from the repository's
`datasets/` folder (local file system, or the same files uploaded to object
storage for production). Format: `csv`, reader: `pandas`, header row present.

| Source name | File | Stream / Snowflake table | Primary key |
|---|---|---|---|
| `customers_source` | `customers.csv` | `CUSTOMERS` | `customer_id` |
| `subscriptions_source` | `subscriptions.csv` | `SUBSCRIPTIONS` | `subscription_id` |
| `payments_source` | `payments.csv` | `PAYMENTS` | `payment_id` |
| `events_source` | `events.csv` | `EVENTS` | `event_id` |
| `tickets_source` | `tickets.csv` | `TICKETS` | `ticket_id` |
| `feature_usage_source` | `feature_usage.csv` | `FEATURE_USAGE` | `feature_id` |

Before each load, validate the files:

```bash
python scripts/validate_datasets.py
```

Notes

* `subscriptions.csv` and `tickets.csv` contain legitimately empty `end_date` /
  `resolved_at` values. dbt parses them with `try_to_date` / `try_to_timestamp_ntz`
  so empty strings become `NULL` instead of failing the build.
* Column names are lowercase in the CSV; Snowflake folds them to upper case.
