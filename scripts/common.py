"""Shared helpers for the dataset generators and validator."""

from __future__ import annotations

import argparse
import random
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_DATA_DIR = REPO_ROOT / "datasets"
DEFAULT_SEED = 42


def base_parser(description: str, default_rows: int | None = None) -> argparse.ArgumentParser:
    """CLI shared by every generator: --rows, --seed and --output-dir."""
    parser = argparse.ArgumentParser(description=description)
    if default_rows is not None:
        parser.add_argument("--rows", type=int, default=default_rows, help="rows to generate")
    parser.add_argument("--seed", type=int, default=DEFAULT_SEED, help="random seed")
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=DEFAULT_DATA_DIR,
        help="directory holding the CSV files (default: ./datasets)",
    )
    return parser


def seed_everything(seed: int) -> None:
    """Make Python's random module and Faker deterministic for a given seed."""
    from faker import Faker

    random.seed(seed)
    Faker.seed(seed)


def read_customer_ids(data_dir: Path) -> list[str]:
    import pandas as pd

    path = data_dir / "customers.csv"
    if not path.exists():
        raise SystemExit(f"{path} not found - run generate_customers.py first.")
    return pd.read_csv(path, usecols=["customer_id"])["customer_id"].tolist()
