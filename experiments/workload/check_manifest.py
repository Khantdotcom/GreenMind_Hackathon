#!/usr/bin/env python3
"""Check a fixed 300-request manifest. A header-only file is the template.

The checker does not invent request rows. Stress tags describe overlaps on
the official 300; they are not extra requests.
"""

from __future__ import annotations

import argparse
import csv
import sys
from collections import Counter
from pathlib import Path

COLUMNS = (
    "request_id",
    "family",
    "prompt_hash",
    "input_tokens",
    "max_output_tokens",
    "arrival_time",
    "peak_phase",
    "expected_answer_or_evaluator_id",
    "stress_slice",
)

MAX_MODEL_LEN = 40960
STRESS = {
    "shared_prefix": 50,
    "long_output": 20,
    "burst_long_prompt": 10,
    "math": 30,
    "code": 30,
    "thai": 30,
}

# Official Final class mix recorded in the project plan. Not a second workload.
OFFICIAL_MIX = {
    "chat": 90,
    "rag": 60,
    "agentic": 60,
    "math_code": 45,
    "thai": 30,
    "longctx": 15,
}


def check(path: Path, strict_stress: bool) -> int:
    with path.open(newline="") as handle:
        reader = csv.DictReader(handle)
        if reader.fieldnames is None:
            print(f"{path}: missing header", file=sys.stderr)
            return 1
        missing = [name for name in COLUMNS if name not in reader.fieldnames]
        if missing:
            print(f"{path}: missing columns {missing}", file=sys.stderr)
            return 1
        rows = list(reader)
    if not rows:
        print(f"{path}: template only, no request rows.")
        print("Fill 300 rows from the benchmark manifest before comparing runs.")
        print(f"Official class mix to preserve: {OFFICIAL_MIX} (sum {sum(OFFICIAL_MIX.values())}).")
        print(
            "Stress minimums are tags on those rows, not added requests: "
            + ", ".join(f"{name}>={count}" for name, count in STRESS.items())
            + "."
        )
        print(
            "30 math + 30 code cannot be added on top of the official math/code "
            "bucket of 45. Tag rows that already belong to that class."
        )
        return 0

    if len(rows) != 300:
        print(f"{path}: expected 300 rows, found {len(rows)}", file=sys.stderr)
        return 1
    ids = [row["request_id"].strip() for row in rows]
    if any(not item for item in ids):
        print(f"{path}: blank request_id", file=sys.stderr)
        return 1
    if len(set(ids)) != len(ids):
        print(f"{path}: duplicate request_id", file=sys.stderr)
        return 1

    stress_counts: Counter[str] = Counter()
    for row in rows:
        try:
            prompt = int(row["input_tokens"])
            output = int(row["max_output_tokens"])
        except ValueError:
            print(f"{path}: non-integer token length on {row['request_id']}", file=sys.stderr)
            return 1
        if prompt < 0 or output < 0 or prompt + output > MAX_MODEL_LEN:
            print(
                f"{path}: {row['request_id']} uses {prompt}+{output} tokens, "
                f"above max-model-len {MAX_MODEL_LEN}",
                file=sys.stderr,
            )
            return 1
        if row["peak_phase"].strip().lower() not in {"0", "1", "true", "false", "yes", "no"}:
            print(f"{path}: bad peak_phase on {row['request_id']}", file=sys.stderr)
            return 1
        tag = row["stress_slice"].strip()
        if tag:
            if tag not in STRESS:
                print(f"{path}: unknown stress_slice {tag!r}", file=sys.stderr)
                return 1
            stress_counts[tag] += 1

    print(f"{path}: 300 rows, token sums fit {MAX_MODEL_LEN}.")
    print(f"Stress tags: {dict(stress_counts)}")
    if strict_stress:
        short = [name for name, count in STRESS.items() if stress_counts[name] < count]
        if short:
            print(f"{path}: stress tags under the plan minimum: {short}", file=sys.stderr)
            return 1
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("manifest", type=Path)
    parser.add_argument("--strict-stress", action="store_true")
    args = parser.parse_args(argv)
    return check(args.manifest, args.strict_stress)


if __name__ == "__main__":
    raise SystemExit(main())
