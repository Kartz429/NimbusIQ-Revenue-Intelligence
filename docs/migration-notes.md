# Migration notes (v1.0 -> v1.1)

Read this before the first production run.

## Behaviour changes

| Change | Impact | Action |
|---|---|---|
| Models write to per-layer schemas: staging `STAGING`, intermediate `INTERMEDIATE`, marts `ANALYTICS` (previously everything was in `STAGING`) | BI queries pointing at `STAGING.MRR` etc. break | Repoint BI to `ANALYTICS`; drop the old mart tables from `STAGING` after the first good prod run |
| Staging reads `source('raw', ...)` instead of hard-coded `NIMBUSIQ.RAW.*` | None for results | Database/schema overridable via `raw_database` / `raw_schema` vars |
| Revenue is converted to USD (`int_payments_usd`) | `total_revenue`, `avg_payment`, `arpu`, `estimated_ltv` change (the old values summed USD, EUR, GBP and INR as if equal) | Expected; replace the static FX seed with a real feed |
| `PAUSED` subscriptions get `lifecycle_status = 'PAUSED'` (was `UNKNOWN`) | Downstream filters on `UNKNOWN` | Update if used |
| `fact_subscription` gains `subscription_id`, `start_date`, `end_date`; `int_support_metrics` gains `in_progress_tickets`, `avg_resolution_hours` | Additive | None |
| Example models (`my_first_dbt_model`, ...) removed | None | Drop leftover `MY_FIRST_DBT_MODEL` / `MY_SECOND_DBT_MODEL` objects if they exist |
| Snapshot schema depends on target: prod -> `SNAPSHOTS`; others -> `<schema>_SNAPSHOTS` | Dev runs no longer write into production history | Run snapshots from `--target prod` only. Snapshot name, `unique_key` and `check_cols` are unchanged, so existing history carries on |
| Roles: dbt/Airbyte use `TRANSFORMER_ROLE` / `LOADER_ROLE` (was `ACCOUNTADMIN`) | Existing objects owned by `ACCOUNTADMIN` | Run the ownership block (section 9) of `snowflake/setup.sql` |
| Repo hygiene: `target/`, `logs/` and the nested `airbyte.zip` removed from version control; `requirements.txt` converted from UTF-16 to UTF-8 | Smaller repo; no local usernames or paths committed | Regenerate with `dbt docs generate` |

## Known limitations (data / business, not code)

* `subscriptions.csv` has no `end_date` for any of its ~33k `CANCELLED` rows (the old generator never set one). A `warn`-level test flags it. The fixed generator sets one; the committed CSV was left untouched so it still matches what you loaded into Snowflake. Regenerate with `python scripts/generate_all.py` and re-sync when you want consistent data.
* Customers can hold several subscriptions in the sample data, so subscription-level KPIs count subscriptions, not customers.
* MRR/ARR are snapshots in time; a monthly MRR history needs plan-change events that the sample data does not contain.
* ARPU is lifetime revenue per payer, so LTV (= ARPU x 24) is illustrative only.
