"""Generate datasets/feature_usage.csv."""

import random

import pandas as pd
from common import base_parser, read_customer_ids, seed_everything
from faker import Faker

FEATURES = [
    "Dashboard Builder", "Reports", "API", "Automation",
    "Notifications", "Analytics", "Export", "Team Collaboration",
]  # fmt: skip


def main() -> None:
    args = base_parser("Generate feature usage", default_rows=300_000).parse_args()
    seed_everything(args.seed)
    fake = Faker()
    customer_ids = read_customer_ids(args.output_dir)

    rows = [
        {
            "feature_id": f"F{i:07}",
            "customer_id": random.choice(customer_ids),
            "feature_name": random.choice(FEATURES),
            "usage_count": random.randint(1, 100),
            "usage_date": fake.date_between(start_date="-2y", end_date="today"),
        }
        for i in range(1, args.rows + 1)
    ]

    pd.DataFrame(rows).to_csv(args.output_dir / "feature_usage.csv", index=False)
    print(f"{args.rows} feature usage rows generated.")


if __name__ == "__main__":
    main()
