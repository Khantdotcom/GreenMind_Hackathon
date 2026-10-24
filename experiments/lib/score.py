#!/usr/bin/env python3
"""Compute a Final-track score from operator-supplied measurements.

The formula matches scoring_criteria.md. Missing measurements are an error.
This tool does not invent graded scores and does not call the grader.

    S = 100 · A · sE^0.6 · sT^0.2 · sL^0.2

Final constants (not interchangeable with Validation):
    eta_base = 0.00163
    K = 3
    reference macro-accuracy = 0.878
    full A at R >= 0.98 (macro about 86.0%)
    TTFT SLO = 0.5 s + 0.25 s per 1k input tokens
    TPOT SLO = 50 ms
"""

from __future__ import annotations

import argparse
import json
import math
import sys

ETA_BASE = 0.00163
ENERGY_K = 3.0
REF_MACRO = 0.878
TPOT_SLO_MS = 50.0


def smoothstep(x: float) -> float:
    x = min(1.0, max(0.0, x))
    return (3.0 * x * x) - (2.0 * x * x * x)


def clip(value: float, low: float, high: float) -> float:
    return min(high, max(low, value))


def as_fraction(macro: float) -> float:
    if macro > 1.5:
        return macro / 100.0
    return macro


def accuracy_factor(macro: float, min_family_retention: float | None) -> dict[str, float | bool]:
    macro_f = as_fraction(macro)
    if macro_f <= 0:
        raise SystemExit("macro-accuracy must be positive")
    retention = macro_f / REF_MACRO
    x = clip((retention - 0.85) / 0.13, 0.0, 1.0)
    main = smoothstep(x)
    family_applied = min_family_retention is not None
    if min_family_retention is None:
        class_factor = 1.0
    else:
        class_factor = smoothstep(clip((min_family_retention - 0.50) / 0.25, 0.0, 1.0))
    factor = max(0.05, main * class_factor)
    return {
        "macro_accuracy": macro_f,
        "accuracy_retention_R": retention,
        "accuracy_main": main,
        "class_factor_cf": class_factor,
        "family_penalty_applied": family_applied and class_factor < 1.0,
        "accuracy_factor_A": factor,
    }


def energy_score(slo_met: int, gpu_joules: float) -> dict[str, float]:
    if slo_met < 0:
        raise SystemExit("slo-met must be >= 0")
    if gpu_joules <= 0:
        raise SystemExit("gpu joules must be > 0")
    eta = slo_met / gpu_joules
    if eta <= 0:
        se = 0.0
    else:
        se = clip(math.log(eta / ETA_BASE) / math.log(ENERGY_K), 0.0, 1.0)
    return {
        "gpu_joules": gpu_joules,
        "requests_slo_met": slo_met,
        "eta_requests_per_joule": eta,
        "eta_over_base": eta / ETA_BASE,
        "full_energy_eta": ETA_BASE * ENERGY_K,
        "sE": se,
    }


def throughput_score(peak_slo_met: int, peak_requests: int) -> float:
    if peak_requests <= 0:
        raise SystemExit("peak-requests must be > 0")
    if peak_slo_met < 0 or peak_slo_met > peak_requests:
        raise SystemExit("peak-slo-met must be between 0 and peak-requests")
    return peak_slo_met / peak_requests


def latency_score(p95_ttft_over_slo: float, p95_tpot_ms: float) -> dict[str, float]:
    if p95_ttft_over_slo <= 0:
        raise SystemExit("p95 TTFT/SLO must be > 0")
    if p95_tpot_ms <= 0:
        raise SystemExit("p95 TPOT must be > 0 milliseconds")
    ttft = min(1.0, 1.0 / p95_ttft_over_slo)
    tpot = min(1.0, TPOT_SLO_MS / p95_tpot_ms)
    return {
        "p95_ttft_over_slo": p95_ttft_over_slo,
        "p95_tpot_ms": p95_tpot_ms,
        "sL_ttft": ttft,
        "sL_tpot": tpot,
        "sL": math.sqrt(ttft * tpot),
    }


def total_score(factor_a: float, se: float, st: float, sl: float) -> float:
    return 100.0 * factor_a * (se ** 0.6) * (st ** 0.2) * (sl ** 0.2)


def check_formula() -> dict[str, float]:
    """Check the published sE ratio table and the accuracy gate. Not a graded score."""
    ratios = {
        "1.00x": 1.00,
        "1.25x": 1.25,
        "1.50x": 1.50,
        "2.00x": 2.00,
        "2.50x": 2.50,
        "3.00x": 3.00,
    }
    expected = {
        "1.00x": 0.00,
        "1.25x": 0.20,
        "1.50x": 0.37,
        "2.00x": 0.63,
        "2.50x": 0.83,
        "3.00x": 1.00,
    }
    got: dict[str, float] = {}
    for name, mult in ratios.items():
        se = energy_score(slo_met=1_000_000, gpu_joules=1_000_000 / (ETA_BASE * mult))["sE"]
        got[name] = se
        if abs(se - expected[name]) > 0.015:
            raise SystemExit(f"sE formula drifted for {name}: {se} vs table {expected[name]}")
    full = accuracy_factor(0.98 * REF_MACRO, None)
    if full["accuracy_factor_A"] != 1.0:
        raise SystemExit("R = 0.98 must give A = 1 before a family penalty")
    floor = accuracy_factor(0.85 * REF_MACRO, None)
    if abs(float(floor["accuracy_factor_A"]) - 0.05) > 1e-12:
        raise SystemExit("R = 0.85 must give A = 0.05")
    at_75 = accuracy_factor(REF_MACRO, 0.75)
    if float(at_75["class_factor_cf"]) != 1.0:
        raise SystemExit("family retention 0.75 must keep the class factor at 1")
    at_50 = accuracy_factor(REF_MACRO, 0.50)
    if float(at_50["accuracy_factor_A"]) != 0.05:
        raise SystemExit("family retention 0.50 must hit the 0.05 accuracy floor")
    if abs((0.98 * REF_MACRO) - 0.86044) > 1e-9:
        raise SystemExit("full-A macro threshold drifted from 0.98 * 0.878")
    saturated = energy_score(10, 10 / (ETA_BASE * 3))["sE"]
    if saturated != 1.0:
        raise SystemExit("eta at 3x baseline must saturate sE at 1")
    under = energy_score(10, 10 / (ETA_BASE * 0.94))["sE"]
    if under != 0.0:
        raise SystemExit("eta under the Final baseline must score sE = 0")
    return got


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Final-track score from measured inputs.")
    parser.add_argument("--check-formula", action="store_true", help="check the formula only")
    parser.add_argument("--macro", type=float, help="macro-accuracy, fraction or percent")
    parser.add_argument("--slo-met", type=int, help="SLO-met requests in the timed window")
    parser.add_argument("--joules", type=float, help="GPU joules over the timed window")
    parser.add_argument("--peak-requests", type=int, help="requests that arrived in the peak phase")
    parser.add_argument("--peak-slo-met", type=int, help="peak-phase requests that met SLO")
    parser.add_argument(
        "--p95-ttft-over-slo",
        type=float,
        help="p95 of (TTFT / that request's TTFT SLO), dimensionless",
    )
    parser.add_argument("--p95-tpot-ms", type=float, help="p95 TPOT in milliseconds")
    parser.add_argument(
        "--min-family-retention",
        type=float,
        default=None,
        help="weakest family accuracy / that family's baseline (omit if unknown)",
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    if args.check_formula:
        ratios = check_formula()
        print(json.dumps({
            "kind": "formula-check",
            "graded_score": False,
            "track": "final",
            "eta_base": ETA_BASE,
            "K": ENERGY_K,
            "reference_macro_accuracy": REF_MACRO,
            "full_A_macro_accuracy": 0.98 * REF_MACRO,
            "sE_ratio_table": ratios,
        }, indent=2))
        return 0

    required = {
        "--macro": args.macro,
        "--slo-met": args.slo_met,
        "--joules": args.joules,
        "--peak-requests": args.peak_requests,
        "--peak-slo-met": args.peak_slo_met,
        "--p95-ttft-over-slo": args.p95_ttft_over_slo,
        "--p95-tpot-ms": args.p95_tpot_ms,
    }
    missing = [name for name, value in required.items() if value is None]
    if missing:
        raise SystemExit(
            "refusing to score: missing "
            + ", ".join(missing)
            + ". Pass measured History fields, or --check-formula."
        )

    acc = accuracy_factor(args.macro, args.min_family_retention)
    energy = energy_score(args.slo_met, args.joules)
    st = throughput_score(args.peak_slo_met, args.peak_requests)
    latency = latency_score(args.p95_ttft_over_slo, args.p95_tpot_ms)
    score = total_score(
        float(acc["accuracy_factor_A"]),
        float(energy["sE"]),
        st,
        float(latency["sL"]),
    )
    print(json.dumps({
        "kind": "computed-from-inputs",
        "graded_score": False,
        "track": "final",
        "tie_break": "higher R, then lower p95 TTFT",
        **acc,
        **energy,
        "sT": st,
        **latency,
        "S": score,
    }, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
