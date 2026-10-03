"""Generate datasets/customers.csv."""

import random

import pandas as pd
from common import base_parser, seed_everything
from faker import Faker

INDUSTRIES = [
    "Fintech", "Healthcare", "SaaS", "EdTech", "Ecommerce",
    "Retail", "Manufacturing", "Gaming", "Logistics", "Marketing",
]  # fmt: skip


def main() -> None:
    args = base_parser("Generate customers", default_rows=50_000).parse_args()
    seed_everything(args.seed)
    fake = Faker()

    rows = [
        {
            "customer_id": f"C{i:06}",
            "name": fake.name(),
            "email": fake.email(),
            "country": fake.country(),
            "industry": random.choice(INDUSTRIES),
            "company_size": random.randint(1, 5000),
            "signup_date": fake.date_between(start_date="-3y", end_date="today"),
        }
        for i in range(1, args.rows + 1)
    ]

    args.output_dir.mkdir(parents=True, exist_ok=True)
    pd.DataFrame(rows).to_csv(args.output_dir / "customers.csv", index=False)
    print(f"{args.rows} customers generated.")


if __name__ == "__main__":
    main()
