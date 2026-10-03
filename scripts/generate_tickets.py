"""Generate datasets/tickets.csv."""

import random
from datetime import timedelta

import pandas as pd
from common import base_parser, read_customer_ids, seed_everything
from faker import Faker

PRIORITIES = ["Low", "Medium", "High", "Critical"]
STATUSES = ["Open", "Closed", "In Progress"]


def main() -> None:
    args = base_parser("Generate tickets", default_rows=100_000).parse_args()
    seed_everything(args.seed)
    fake = Faker()
    customer_ids = read_customer_ids(args.output_dir)

    rows = []
    for i in range(1, args.rows + 1):
        created_at = fake.date_time_between(start_date="-2y", end_date="now")
        status = random.choice(STATUSES)
        resolved_at = (
            created_at + timedelta(hours=random.randint(1, 240)) if status == "Closed" else None
        )
        rows.append(
            {
                "ticket_id": f"T{i:07}",
                "customer_id": random.choice(customer_ids),
                "priority": random.choice(PRIORITIES),
                "status": status,
                "created_at": created_at,
                "resolved_at": resolved_at,
            }
        )

    pd.DataFrame(rows).to_csv(args.output_dir / "tickets.csv", index=False)
    print(f"{args.rows} tickets generated.")


if __name__ == "__main__":
    main()
