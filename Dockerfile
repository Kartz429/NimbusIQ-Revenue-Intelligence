FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    DBT_PROFILES_DIR=/app/nimbusiq/profiles

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY nimbusiq/ nimbusiq/

RUN useradd --create-home --uid 10001 dbt && chown -R dbt:dbt /app
USER dbt
WORKDIR /app/nimbusiq
# `dbt deps` only needs the project; dummy values satisfy profile rendering.
RUN SNOWFLAKE_ACCOUNT=x SNOWFLAKE_USER=x SNOWFLAKE_PASSWORD=x dbt deps

# Credentials are injected at runtime as environment variables, never baked in:
#   docker run --rm --env-file .env nimbusiq-dbt build --target prod
ENTRYPOINT ["dbt"]
CMD ["--version"]
