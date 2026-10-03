# Security

* Never commit credentials, private keys or `.env` files (git-ignored; gitleaks runs in pre-commit).
* Production and CI authenticate with Snowflake key pairs held in GitHub secrets.
* `ACCOUNTADMIN` is used only to run `snowflake/setup.sql`.
* `dim_customer` / `stg_customers` contain email addresses (PII); grant `REPORTER_ROLE` deliberately.

Report a vulnerability privately via GitHub *Security -> Report a vulnerability*, not a public issue.
