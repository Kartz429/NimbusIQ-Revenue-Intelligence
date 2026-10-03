"""Generate datasets/payments.csv."""

import random

import pandas as pd
from common import base_parser, read_customer_ids, seed_everything
from faker import Faker

METHODS = ["Credit Card", "Debit Card", "UPI", "PayPal", "Bank Transfer"]
CURRENCIES = ["USD", "EUR", "GBP", "INR"]


def main() -> None:
    args = base_parser("Generate payments", default_rows=500_000).parse_args()
    seed_everything(args.seed)
    fake = Faker()
    customer_ids = read_customer_ids(args.output_dir)

    rows = [
        {
            "payment_id": f"P{i:07}",
            "customer_id": random.choice(customer_ids),
            "amount": round(random.uniform(10, 500), 2),
            "payment_method": random.choice(METHODS),
            "currency": random.choice(CURRENCIES),
            "payment_date": fake.date_between(start_date="-3y", end_date="today"),
        }
        for i in range(1, args.rows + 1)
    ]

    pd.DataFrame(rows).to_csv(args.output_dir / "payments.csv", index=False)
    print(f"{args.rows} payments generated.")


if __name__ == "__main__":
    main()
