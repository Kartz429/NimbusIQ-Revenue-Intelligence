# Runbook

## Daily operation
1. Airbyte sync completes (manual for the static CSVs).
2. `Deploy` workflow runs at 02:00 UTC (or trigger it from the Actions tab).
3. Review the run summary; download `dbt-artifacts-*` for `run_results.json` / docs.

## Common tasks

| Task | Command |
|---|---|
| Local connection check | `cd nimbusiq && dbt debug` |
| Full build | `dbt build` |
| Rebuild incremental events | `dbt run --full-refresh --select int_events_incremental` (or the *full_refresh_events* input on the Deploy workflow) |
| Re-run only failures | `dbt build --select result:error+ result:fail+ --state target` (needs the previous `target/`) |
| Regenerate sample data | `python scripts/generate_all.py` then `python scripts/validate_datasets.py` |
| Change an assumption | `dbt build --vars '{ltv_lifetime_months: 36}'` or edit `vars` in `dbt_project.yml` |

PowerShell: load `.env` with
`Get-Content .env | Where-Object { $_ -match '^\s*[^#].*=' } | ForEach-Object { $k,$v = $_ -split '=',2; [Environment]::SetEnvironmentVariable($k.Trim(), ($v -split '\s+#')[0].Trim()) }`
and set `$env:DBT_PROFILES_DIR = "profiles"`.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `Object 'NIMBUSIQ.RAW.X' does not exist or not authorized` | Airbyte has not loaded the table, or the role lacks `SELECT` | Re-run the sync; re-run section 6 of `snowflake/setup.sql` |
| `unique`/`not_null` fails on a staging key | Duplicate or empty keys in the source | Fix the CSV, re-sync with *Overwrite*; confirm with `validate_datasets.py` |
| `relationships` fails on `currency` | New currency without an FX rate | Add a row to `seeds/currency_rates.csv`, then `dbt seed` |
| `assert_revenue_reconciles` fails | Customers with payments missing from the fact, or a join dropped rows | Inspect `int_customer_revenue` vs `int_payments_usd` |
| Source freshness error on `_airbyte_extracted_at` | Destination version does not write that column, or data is genuinely stale | Re-sync, or remove `loaded_at_field` |
| Key-pair login fails in CI | Wrong/encrypted key or missing passphrase secret | Re-paste the PEM (including header/footer lines); set `SNOWFLAKE_PRIVATE_KEY_PASSPHRASE` |
| Snapshot rows duplicated after the move | Old snapshot lives in a different schema | See `docs/migration-notes.md` |

## Rotating credentials
1. Generate a new key pair; `ALTER USER DBT_USER SET RSA_PUBLIC_KEY_2 = '...'`.
2. Update the `SNOWFLAKE_PRIVATE_KEY` GitHub secret; verify a CI run.
3. `ALTER USER DBT_USER UNSET RSA_PUBLIC_KEY;` after swapping keys.

## Cost control
`NIMBUSIQ_WH` is X-Small with 60-second auto-suspend and a monthly resource monitor
(`NIMBUSIQ_RM`, notify at 80 %, suspend at 100 %). Adjust the credit quota in `snowflake/setup.sql`.
