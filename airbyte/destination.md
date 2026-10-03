# Snowflake destination

| Setting | Value |
|---|---|
| Destination name | `snowflake_destination` |
| Host | `<account>.snowflakecomputing.com` |
| Role | **`LOADER_ROLE`** (not `ACCOUNTADMIN`) |
| Warehouse | `NIMBUSIQ_WH` |
| Database | `NIMBUSIQ` |
| Default schema | `RAW` |
| Username | `AIRBYTE_USER` |
| Authentication | Key pair (RSA). Paste the private key into Airbyte's secret field |
| Raw tables schema | `AIRBYTE_INTERNAL` |
| Disable final tables | off |

Create the role, user and grants with [`snowflake/setup.sql`](../snowflake/setup.sql).
Credentials are stored in Airbyte's secret manager and never in this repository.

```text
CSV -> Airbyte -> Snowflake NIMBUSIQ.RAW
```
