# Changelog

## 1.1.0 - Production readiness

### Added
- `source()` definitions with freshness, env-var driven `profiles.yml` (dev/ci/prod), `packages.yml` (dbt_utils)
- `int_payments_usd` + `currency_rates` seed for multi-currency revenue
- Tests: relationships, accepted values, ranges, reconciliation, date ordering; two dbt unit tests
- GitHub Actions CI and scheduled production deploy; Dependabot; PR template
- Least-privilege Snowflake roles, key-pair service users, resource monitor in `snowflake/setup.sql`
- Dockerfile, Makefile, pre-commit, sqlfluff, ruff, yamllint, editorconfig, pytest suite
- Seeded dataset generators, `generate_all.py`, `validate_datasets.py`
- Runbook, architecture, migration notes, GitHub setup guide

### Changed
- Models now build into `STAGING` / `INTERMEDIATE` / `ANALYTICS`; non-prod targets use prefixed schemas
- Revenue metrics use USD-converted amounts; `PAUSED` lifecycle status; assumptions moved to `vars`
- Snapshot isolated per environment and invalidates hard deletes
- Documentation corrected (table names, roles, schema layout)

### Removed
- dbt example models, `target/`, `logs/`, nested `airbyte.zip`, empty folders, `validate_customers.py` / `validate_payments.py` (superseded by `validate_datasets.py`)
