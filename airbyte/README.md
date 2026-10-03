# Airbyte ingestion

Airbyte moves the six CSV exports in `datasets/` into Snowflake `NIMBUSIQ.RAW`.
dbt reads from there and never writes to it.

```text
datasets/*.csv  ->  Airbyte (6 sources, 1 destination, 6 streams)  ->  NIMBUSIQ.RAW.<TABLE>
```

| Doc | Contents |
|---|---|
| [`sources.md`](./sources.md) | The six file sources and their settings |
| [`destination.md`](./destination.md) | Snowflake destination, role and key-pair auth |
| [`architecture.md`](./architecture.md) | Data-flow diagram and table names |

## Connection settings

| Setting | Value | Why |
|---|---|---|
| Sync mode (initial) | Full refresh &#124; Overwrite | The CSVs are complete snapshots |
| Sync mode (later, real feed) | Incremental &#124; Append + Deduped | Needs a source with a cursor (see below) |
| Schedule | Manual (static CSVs) / every 24 h (real feed) | No point re-syncing unchanged files |
| Destination namespace | Custom: `RAW` | Keeps tables out of `PUBLIC` |
| Stream prefix | none | Table names must stay `CUSTOMERS`, `EVENTS`, ... (dbt `sources` rely on them) |

## Resulting tables (all in `NIMBUSIQ.RAW`)

`CUSTOMERS`, `SUBSCRIPTIONS`, `PAYMENTS`, `EVENTS`, `TICKETS`, `FEATURE_USAGE`.

Airbyte's Snowflake destination (v2 and later) adds the metadata columns
`_AIRBYTE_RAW_ID`, `_AIRBYTE_EXTRACTED_AT` and `_AIRBYTE_META` to each table.
dbt's source freshness check uses `_AIRBYTE_EXTRACTED_AT`. If your destination
version does not write it, remove `loaded_at_field` from
`nimbusiq/models/staging/_sources.yml`.

> Earlier drafts of these docs listed `RAW_CUSTOMERS`-style names. The dbt
> project has always read `RAW.CUSTOMERS`, so the docs now match the code.

## Incremental sync caveat

Airbyte's File source reads a whole file and has no cursor, so it can only do
full refresh. To get incremental loads, point Airbyte at the same files in an
object store (S3/GCS/Azure) with the file-based source, or at the real
application database, and use *Incremental | Append + Deduped* with these keys:

| Stream | Primary key | Cursor |
|---|---|---|
| customers | `customer_id` | `signup_date` |
| subscriptions | `subscription_id` | - (full refresh) |
| payments | `payment_id` | `payment_date` |
| events | `event_id` | `event_time` |
| tickets | `ticket_id` | `created_at` |
| feature_usage | `feature_id` | `usage_date` |

The dbt layer is already prepared for this: `int_events_incremental` merges on
`event_id` and picks up late-arriving events.

## Operating Airbyte

* Run Airbyte itself with [`abctl`](https://docs.airbyte.com/using-airbyte/getting-started/oss-quickstart)
  locally, or Airbyte Cloud / Kubernetes for production.
* Use the **`LOADER_ROLE` + `AIRBYTE_USER`** created by `snowflake/setup.sql`
  with key-pair auth. Never run the connector as `ACCOUNTADMIN`.
* After a successful sync, run `dbt build --target prod` (the scheduled
  GitHub Action does this daily at 02:00 UTC - align your Airbyte schedule to
  finish before then).
