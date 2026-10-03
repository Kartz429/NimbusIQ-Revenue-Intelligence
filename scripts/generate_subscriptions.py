"""Generate datasets/subscriptions.csv.

Cancelled subscriptions get an end_date between their start date and today;
active and paused subscriptions have no end_date.
"""

import random
from datetime import date, timedelta

import pandas as pd
from common import base_parser, read_customer_ids, seed_everything
from faker import Faker

PLANS = {"Free": 0, "Starter": 29, "Professional": 99, "Enterprise": 499}
PLAN_WEIGHTS = [20, 40, 30, 10]
STATUSES = ["ACTIVE", "CANCELLED", "PAUSED"]


def main() -> None:
    args = base_parser("Generate subscriptions", default_rows=100_000).parse_args()
    seed_everything(args.seed)
    fake = Faker()
    customer_ids = read_customer_ids(args.output_dir)
    today = date.today()

    rows = []
    for i in range(1, args.rows + 1):
        plan = random.choices(list(PLANS), weights=PLAN_WEIGHTS)[0]
        status = random.choice(STATUSES)
        start = fake.date_between(start_date="-3y", end_date="today")
        end = None
        if status == "CANCELLED":
            end = start + timedelta(days=random.randint(0, max((today - start).days, 0)))
        rows.append(
            {
                "subscription_id": f"S{i:06}",
                "customer_id": random.choice(customer_ids),
                "plan_name": plan,
                "monthly_price": PLANS[plan],
                "status": status,
                "start_date": start,
                "end_date": end,
            }
        )

    pd.DataFrame(rows).to_csv(args.output_dir / "subscriptions.csv", index=False)
    print(f"{args.rows} subscriptions generated.")


if __name__ == "__main__":
    main()
