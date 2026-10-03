"""Generate every dataset in dependency order (customers first).

    python scripts/generate_all.py                # full size
    python scripts/generate_all.py --scale 0.01   # 1% sample for quick tests
"""

import subprocess
import sys
from pathlib import Path

from common import base_parser

HERE = Path(__file__).resolve().parent
FULL_SIZE = {
    "generate_customers.py": 50_000,
    "generate_subscriptions.py": 100_000,
    "generate_payments.py": 500_000,
    "generate_events.py": 100_000,
    "generate_tickets.py": 100_000,
    "generate_feature_usage.py": 300_000,
}


def main() -> None:
    parser = base_parser("Generate all NimbusIQ datasets")
    parser.add_argument("--scale", type=float, default=1.0, help="fraction of full size")
    args = parser.parse_args()

    for script, rows in FULL_SIZE.items():
        cmd = [
            sys.executable, str(HERE / script),
            "--rows", str(max(int(rows * args.scale), 1)),
            "--seed", str(args.seed),
            "--output-dir", str(args.output_dir),
        ]  # fmt: skip
        subprocess.run(cmd, check=True)


if __name__ == "__main__":
    main()
