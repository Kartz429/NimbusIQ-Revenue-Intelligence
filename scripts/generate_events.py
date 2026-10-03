"""Generate datasets/events.csv."""

import random

import pandas as pd
from common import base_parser, read_customer_ids, seed_everything
from faker import Faker

EVENT_TYPES = [
    "Login", "Create Workspace", "Create Project", "Invite Member",
    "Create Dashboard", "Generate Report", "Export Report", "API Call",
]  # fmt: skip


def main() -> None:
    args = base_parser("Generate events", default_rows=100_000).parse_args()
    seed_everything(args.seed)
    fake = Faker()
    customer_ids = read_customer_ids(args.output_dir)

    rows = [
        {
            "event_id": f"E{i:08}",
            "customer_id": random.choice(customer_ids),
            "event_type": random.choice(EVENT_TYPES),
            "event_time": fake.date_time_between(start_date="-2y", end_date="now"),
        }
        for i in range(1, args.rows + 1)
    ]

    pd.DataFrame(rows).to_csv(args.output_dir / "events.csv", index=False)
    print(f"{args.rows} events generated.")


if __name__ == "__main__":
    main()
