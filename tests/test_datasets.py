"""Smoke tests for the dataset generators and the validator."""

import subprocess
import sys
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).resolve().parent.parent
SCRIPTS = REPO_ROOT / "scripts"
sys.path.insert(0, str(SCRIPTS))

from validate_datasets import validate  # noqa: E402


@pytest.fixture(scope="module")
def small_dataset(tmp_path_factory) -> Path:
    out = tmp_path_factory.mktemp("datasets")
    subprocess.run(
        [sys.executable, str(SCRIPTS / "generate_all.py"), "--scale", "0.004",
         "--seed", "7", "--output-dir", str(out)],
        check=True,
    )  # fmt: skip
    return out


def test_generated_data_has_no_validation_errors(small_dataset):
    errors, _ = validate(small_dataset)
    assert errors == []


def test_generation_is_reproducible(tmp_path_factory, small_dataset):
    other = tmp_path_factory.mktemp("datasets_again")
    subprocess.run(
        [sys.executable, str(SCRIPTS / "generate_customers.py"), "--rows", "200",
         "--seed", "7", "--output-dir", str(other)],
        check=True,
    )  # fmt: skip
    first = (small_dataset / "customers.csv").read_text().splitlines()[:50]
    second = (other / "customers.csv").read_text().splitlines()[:50]
    assert first[1:] == second[1:50]


def test_cancelled_subscriptions_have_end_dates(small_dataset):
    import pandas as pd

    subs = pd.read_csv(small_dataset / "subscriptions.csv")
    cancelled = subs[subs["status"] == "CANCELLED"]
    assert cancelled["end_date"].notna().all()
    assert subs[subs["status"] != "CANCELLED"]["end_date"].isna().all()


def test_validator_catches_orphan_customer(small_dataset, tmp_path):
    import shutil

    broken = tmp_path / "broken"
    shutil.copytree(small_dataset, broken)
    payments = (broken / "payments.csv").read_text().replace("C000001", "C999999")
    (broken / "payments.csv").write_text(payments)
    errors, _ = validate(broken)
    assert any("unknown customer_id" in e for e in errors)


def test_committed_datasets_pass_validation():
    errors, _ = validate(REPO_ROOT / "datasets")
    assert errors == []
