"""Validate the CSV datasets before they are loaded by Airbyte.

Exit code 0 = no errors (warnings are allowed); 1 = at least one error.

    python scripts/validate_datasets.py [--data-dir datasets] [--strict]
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

import pandas as pd
from common import DEFAULT_DATA_DIR

SCHEMAS = {
    "customers": ["customer_id", "name", "email", "country", "industry", "company_size", "signup_date"],
    "subscriptions": ["subscription_id", "customer_id", "plan_name", "monthly_price", "status", "start_date", "end_date"],
    "payments": ["payment_id", "customer_id", "amount", "payment_method", "currency", "payment_date"],
    "events": ["event_id", "customer_id", "event_type", "event_time"],
    "tickets": ["ticket_id", "customer_id", "priority", "status", "created_at", "resolved_at"],
    "feature_usage": ["feature_id", "customer_id", "feature_name", "usage_count", "usage_date"],
}  # fmt: skip
PRIMARY_KEYS = {
    "customers": "customer_id",
    "subscriptions": "subscription_id",
    "payments": "payment_id",
    "events": "event_id",
    "tickets": "ticket_id",
    "feature_usage": "feature_id",
}
NOT_NULL = {
    "customers": ["customer_id", "email", "signup_date"],
    "subscriptions": ["customer_id", "plan_name", "monthly_price", "status", "start_date"],
    "payments": ["customer_id", "amount", "currency", "payment_date"],
    "events": ["customer_id", "event_type", "event_time"],
    "tickets": ["customer_id", "priority", "status", "created_at"],
    "feature_usage": ["customer_id", "feature_name", "usage_count", "usage_date"],
}
PLAN_PRICES = {"Free": 0, "Starter": 29, "Professional": 99, "Enterprise": 499}


def validate(data_dir: Path) -> tuple[list[str], list[str]]:
    errors: list[str] = []
    warnings: list[str] = []
    frames: dict[str, pd.DataFrame] = {}

    for name, columns in SCHEMAS.items():
        path = data_dir / f"{name}.csv"
        if not path.exists():
            errors.append(f"{name}: file {path} is missing")
            continue
        df = pd.read_csv(path)
        frames[name] = df
        if list(df.columns) != columns:
            errors.append(f"{name}: columns {list(df.columns)} != expected {columns}")
            continue
        if df.empty:
            errors.append(f"{name}: file has no rows")
            continue
        pk = PRIMARY_KEYS[name]
        if df[pk].duplicated().any():
            errors.append(f"{name}: duplicate {pk} values ({int(df[pk].duplicated().sum())})")
        for col in NOT_NULL[name]:
            nulls = int(df[col].isna().sum())
            if nulls:
                errors.append(f"{name}: {nulls} null values in {col}")

    if "customers" not in frames:
        return errors, warnings
    known = set(frames["customers"]["customer_id"])
    for name, df in frames.items():
        if name == "customers" or "customer_id" not in df:
            continue
        orphans = int((~df["customer_id"].isin(known)).sum())
        if orphans:
            errors.append(f"{name}: {orphans} rows reference unknown customer_id")

    subs = frames.get("subscriptions")
    if subs is not None and "plan_name" in subs:
        bad_price = subs[subs["plan_name"].map(PLAN_PRICES) != subs["monthly_price"]]
        if len(bad_price):
            errors.append(f"subscriptions: {len(bad_price)} rows where price does not match plan")
        bad_status = ~subs["status"].isin(["ACTIVE", "CANCELLED", "PAUSED"])
        if bad_status.any():
            errors.append(f"subscriptions: {int(bad_status.sum())} rows with unknown status")
        start = pd.to_datetime(subs["start_date"], errors="coerce")
        end = pd.to_datetime(subs["end_date"], errors="coerce")
        if (end < start).any():
            errors.append("subscriptions: end_date earlier than start_date")
        missing_end = int(((subs["status"] == "CANCELLED") & subs["end_date"].isna()).sum())
        if missing_end:
            warnings.append(f"subscriptions: {missing_end} CANCELLED rows have no end_date")

    pay = frames.get("payments")
    if pay is not None and "amount" in pay:
        if (pay["amount"] <= 0).any():
            errors.append("payments: non-positive amounts found")
        currencies = pay["currency"].nunique()
        if currencies > 1:
            warnings.append(
                f"payments: {currencies} currencies present - amounts must be converted to USD "
                "before they are summed (done by dbt model int_payments_usd)"
            )

    tickets = frames.get("tickets")
    if tickets is not None and "created_at" in tickets:
        created = pd.to_datetime(tickets["created_at"], errors="coerce")
        resolved = pd.to_datetime(tickets["resolved_at"], errors="coerce")
        if (resolved < created).any():
            errors.append("tickets: resolved_at earlier than created_at")
        if ((tickets["status"] == "Closed") & tickets["resolved_at"].isna()).any():
            errors.append("tickets: Closed tickets without resolved_at")

    return errors, warnings


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--data-dir", type=Path, default=DEFAULT_DATA_DIR)
    parser.add_argument("--strict", action="store_true", help="treat warnings as errors")
    args = parser.parse_args()

    errors, warnings = validate(args.data_dir)
    for message in warnings:
        print(f"WARNING: {message}")
    for message in errors:
        print(f"ERROR:   {message}")
    failed = bool(errors) or (args.strict and bool(warnings))
    print("FAILED" if failed else "OK", f"({len(errors)} errors, {len(warnings)} warnings)")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
