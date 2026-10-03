-- =============================================================================
-- NimbusIQ - Snowflake bootstrap (idempotent: safe to re-run)
--
-- Run once as ACCOUNTADMIN (or a role holding the same grants).
-- Creates: warehouse + resource monitor, database + schemas, three
-- least-privilege roles, two key-pair service users, and all grants.
--
--   LOADER_ROLE       Airbyte. Writes to RAW (+ its internal staging schema).
--   TRANSFORMER_ROLE  dbt. Reads RAW; owns STAGING/INTERMEDIATE/ANALYTICS/SNAPSHOTS.
--   REPORTER_ROLE     BI users. Read-only on ANALYTICS.
--
-- No passwords live in this file. Service users authenticate with RSA key
-- pairs; paste each PUBLIC key into the ALTER USER statements at the bottom.
-- =============================================================================

USE ROLE ACCOUNTADMIN;

-- ---------------------------------------------------------------------------
-- 1. Compute + cost guard rail
-- ---------------------------------------------------------------------------
CREATE WAREHOUSE IF NOT EXISTS NIMBUSIQ_WH
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'NimbusIQ ingestion + dbt + BI';

-- Adjust the quota to your budget. Notifies at 80 %, suspends at 100 %.
CREATE RESOURCE MONITOR IF NOT EXISTS NIMBUSIQ_RM
    WITH CREDIT_QUOTA = 20
    FREQUENCY = MONTHLY
    START_TIMESTAMP = IMMEDIATELY
    TRIGGERS
        ON 80 PERCENT DO NOTIFY
        ON 100 PERCENT DO SUSPEND;

ALTER WAREHOUSE NIMBUSIQ_WH SET RESOURCE_MONITOR = NIMBUSIQ_RM;

-- ---------------------------------------------------------------------------
-- 2. Database and schemas
-- ---------------------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS NIMBUSIQ;

CREATE SCHEMA IF NOT EXISTS NIMBUSIQ.RAW COMMENT = 'Airbyte landing zone (read-only for dbt)';
CREATE SCHEMA IF NOT EXISTS NIMBUSIQ.AIRBYTE_INTERNAL COMMENT = 'Airbyte raw/staging tables';
CREATE SCHEMA IF NOT EXISTS NIMBUSIQ.STAGING COMMENT = 'dbt staging views + seeds';
CREATE SCHEMA IF NOT EXISTS NIMBUSIQ.INTERMEDIATE COMMENT = 'dbt intermediate models';
CREATE SCHEMA IF NOT EXISTS NIMBUSIQ.ANALYTICS COMMENT = 'dbt marts: dimensions, facts, KPIs';
CREATE SCHEMA IF NOT EXISTS NIMBUSIQ.SNAPSHOTS COMMENT = 'dbt SCD Type 2 snapshots';

-- ---------------------------------------------------------------------------
-- 3. Roles
-- ---------------------------------------------------------------------------
CREATE ROLE IF NOT EXISTS LOADER_ROLE COMMENT = 'Airbyte';
CREATE ROLE IF NOT EXISTS TRANSFORMER_ROLE COMMENT = 'dbt';
CREATE ROLE IF NOT EXISTS REPORTER_ROLE COMMENT = 'BI / read-only consumers';

-- Keep the hierarchy under SYSADMIN so admins can see everything.
GRANT ROLE LOADER_ROLE TO ROLE SYSADMIN;
GRANT ROLE TRANSFORMER_ROLE TO ROLE SYSADMIN;
GRANT ROLE REPORTER_ROLE TO ROLE SYSADMIN;

-- ---------------------------------------------------------------------------
-- 4. Warehouse access
-- ---------------------------------------------------------------------------
GRANT USAGE, OPERATE ON WAREHOUSE NIMBUSIQ_WH TO ROLE LOADER_ROLE;
GRANT USAGE, OPERATE ON WAREHOUSE NIMBUSIQ_WH TO ROLE TRANSFORMER_ROLE;
GRANT USAGE ON WAREHOUSE NIMBUSIQ_WH TO ROLE REPORTER_ROLE;

-- ---------------------------------------------------------------------------
-- 5. LOADER_ROLE (Airbyte)
-- ---------------------------------------------------------------------------
GRANT USAGE ON DATABASE NIMBUSIQ TO ROLE LOADER_ROLE;
GRANT CREATE SCHEMA ON DATABASE NIMBUSIQ TO ROLE LOADER_ROLE;
GRANT ALL PRIVILEGES ON SCHEMA NIMBUSIQ.RAW TO ROLE LOADER_ROLE;
GRANT ALL PRIVILEGES ON SCHEMA NIMBUSIQ.AIRBYTE_INTERNAL TO ROLE LOADER_ROLE;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA NIMBUSIQ.RAW TO ROLE LOADER_ROLE;
GRANT ALL PRIVILEGES ON FUTURE TABLES IN SCHEMA NIMBUSIQ.RAW TO ROLE LOADER_ROLE;

-- ---------------------------------------------------------------------------
-- 6. TRANSFORMER_ROLE (dbt)
-- ---------------------------------------------------------------------------
GRANT USAGE ON DATABASE NIMBUSIQ TO ROLE TRANSFORMER_ROLE;
-- CREATE SCHEMA lets dbt create per-developer (DBT_<NAME>_*) and CI (CI_PR_*) schemas.
GRANT CREATE SCHEMA ON DATABASE NIMBUSIQ TO ROLE TRANSFORMER_ROLE;

-- Read-only on RAW, including tables Airbyte creates later.
GRANT USAGE ON SCHEMA NIMBUSIQ.RAW TO ROLE TRANSFORMER_ROLE;
GRANT SELECT ON ALL TABLES IN SCHEMA NIMBUSIQ.RAW TO ROLE TRANSFORMER_ROLE;
GRANT SELECT ON FUTURE TABLES IN SCHEMA NIMBUSIQ.RAW TO ROLE TRANSFORMER_ROLE;
GRANT SELECT ON ALL VIEWS IN SCHEMA NIMBUSIQ.RAW TO ROLE TRANSFORMER_ROLE;
GRANT SELECT ON FUTURE VIEWS IN SCHEMA NIMBUSIQ.RAW TO ROLE TRANSFORMER_ROLE;

-- Build rights on every dbt-managed schema.
GRANT ALL PRIVILEGES ON SCHEMA NIMBUSIQ.STAGING TO ROLE TRANSFORMER_ROLE;
GRANT ALL PRIVILEGES ON SCHEMA NIMBUSIQ.INTERMEDIATE TO ROLE TRANSFORMER_ROLE;
GRANT ALL PRIVILEGES ON SCHEMA NIMBUSIQ.ANALYTICS TO ROLE TRANSFORMER_ROLE;
GRANT ALL PRIVILEGES ON SCHEMA NIMBUSIQ.SNAPSHOTS TO ROLE TRANSFORMER_ROLE;

-- ---------------------------------------------------------------------------
-- 7. REPORTER_ROLE (BI) - read-only on the marts, including rebuilt tables
-- ---------------------------------------------------------------------------
GRANT USAGE ON DATABASE NIMBUSIQ TO ROLE REPORTER_ROLE;
GRANT USAGE ON SCHEMA NIMBUSIQ.ANALYTICS TO ROLE REPORTER_ROLE;
GRANT SELECT ON ALL TABLES IN SCHEMA NIMBUSIQ.ANALYTICS TO ROLE REPORTER_ROLE;
GRANT SELECT ON FUTURE TABLES IN SCHEMA NIMBUSIQ.ANALYTICS TO ROLE REPORTER_ROLE;
GRANT SELECT ON ALL VIEWS IN SCHEMA NIMBUSIQ.ANALYTICS TO ROLE REPORTER_ROLE;
GRANT SELECT ON FUTURE VIEWS IN SCHEMA NIMBUSIQ.ANALYTICS TO ROLE REPORTER_ROLE;

-- ---------------------------------------------------------------------------
-- 8. Service users (key-pair auth, no passwords)
-- ---------------------------------------------------------------------------
CREATE USER IF NOT EXISTS AIRBYTE_USER
    TYPE = SERVICE
    DEFAULT_ROLE = LOADER_ROLE
    DEFAULT_WAREHOUSE = NIMBUSIQ_WH
    COMMENT = 'Airbyte service account';

CREATE USER IF NOT EXISTS DBT_USER
    TYPE = SERVICE
    DEFAULT_ROLE = TRANSFORMER_ROLE
    DEFAULT_WAREHOUSE = NIMBUSIQ_WH
    COMMENT = 'dbt / GitHub Actions service account';

GRANT ROLE LOADER_ROLE TO USER AIRBYTE_USER;
GRANT ROLE TRANSFORMER_ROLE TO USER DBT_USER;

-- Generate a key pair locally (never commit the private key):
--   openssl genrsa 2048 | openssl pkcs8 -topk8 -v2 aes-256-cbc -inform PEM -out dbt_key.p8
--   openssl rsa -in dbt_key.p8 -pubout -out dbt_key.pub
-- Then paste the public key body (without the BEGIN/END lines) below and run:
-- ALTER USER AIRBYTE_USER SET RSA_PUBLIC_KEY = '<airbyte public key body>';
-- ALTER USER DBT_USER     SET RSA_PUBLIC_KEY = '<dbt public key body>';

-- ---------------------------------------------------------------------------
-- 9. ONE-TIME MIGRATION (only if you previously ran everything as ACCOUNTADMIN)
--    Hand existing objects to the right owner so dbt can rebuild them.
-- ---------------------------------------------------------------------------
-- GRANT OWNERSHIP ON ALL TABLES IN SCHEMA NIMBUSIQ.RAW        TO ROLE LOADER_ROLE      COPY CURRENT GRANTS;
-- GRANT OWNERSHIP ON ALL TABLES IN SCHEMA NIMBUSIQ.STAGING    TO ROLE TRANSFORMER_ROLE COPY CURRENT GRANTS;
-- GRANT OWNERSHIP ON ALL VIEWS  IN SCHEMA NIMBUSIQ.STAGING    TO ROLE TRANSFORMER_ROLE COPY CURRENT GRANTS;
-- GRANT OWNERSHIP ON ALL TABLES IN SCHEMA NIMBUSIQ.SNAPSHOTS  TO ROLE TRANSFORMER_ROLE COPY CURRENT GRANTS;
-- Old marts/intermediate objects in STAGING are superseded by INTERMEDIATE/ANALYTICS and can be dropped
-- after the first successful prod run (see docs/migration-notes.md).
