# NimbusIQ dbt project

Transforms `NIMBUSIQ.RAW` (loaded by Airbyte) into staging, intermediate and
analytics models. See the [repository README](../README.md) for the full picture.

```text
models/
  staging/        _sources.yml, stg_*  (typed, cleaned 1:1 with RAW)
  intermediate/   int_*                (USD payments, aggregates, incremental events)
  marts/          dimensions/, facts/, KPI tables (mrr, arr, arpu, ltv, ...)
seeds/            currency_rates.csv    (illustrative FX rates)
snapshots/        subscription_snapshot (SCD2 on plan_name + status)
macros/           generate_schema_name, drop_ci_schemas
tests/            singular data tests (reconciliation, date ordering, ...)
profiles/         credential-free profiles.yml (env-var driven)
```

## Run it

```bash
export DBT_PROFILES_DIR=profiles      # + the SNOWFLAKE_* variables from ../.env.example
dbt deps && dbt debug
dbt seed
dbt build                              # run + test + snapshot in DAG order
dbt build --select +fact_revenue       # one model and everything it depends on
dbt test --select test_type:unit       # unit tests only
dbt source freshness
dbt run --full-refresh --select int_events_incremental   # rebuild the incremental model
```

## Conventions

* Every model and column is described in a `_*.yml` file next to it; keys have `unique` + `not_null`; foreign keys have `relationships` tests.
* Categorical drift (`accepted_values`) is a **warning**; broken keys, null keys and negative amounts are **errors**.
* Business assumptions are `vars` in `dbt_project.yml`, never hard-coded in SQL.
* `target.name == 'prod'` is the only target that writes to `STAGING`, `INTERMEDIATE`, `ANALYTICS` and `SNAPSHOTS`.
* Staging parsing uses `try_to_*` functions so a malformed value becomes `NULL` and is then caught by a `not_null` test, instead of crashing the whole run.
