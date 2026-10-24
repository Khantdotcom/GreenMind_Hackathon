#!/usr/bin/env python3
"""Split a profile.args file into vLLM argv tokens and check the run contract.

Tokens are split on the first whitespace of each line. Values are not passed
through a shell, so a JSON value keeps its double quotes.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

MODEL_ID = "CMKL/MANGO1.5-Qwen3.5-9B-AWQ-W4A16-mtp"
SERVED_MODEL_NAME = "mango1.5-awq-w4a16"

REQUIRED_VALUES = {
    "--host": "0.0.0.0",
    "--port": "8000",
    "--served-model-name": SERVED_MODEL_NAME,
    "--max-model-len": "40960",
    "--tool-call-parser": "qwen3_coder",
    "--reasoning-parser": "qwen3",
}

# Ladder arms and final-combined stay at 0.90; final-combined-v2 uses 0.95 for KV headroom.
ALLOWED_GPU_MEMORY = frozenset({"0.90", "0.92", "0.95"})

REQUIRED_FLAGS = (
    "--trust-remote-code",
    "--enable-auto-tool-choice",
)


def tokens(path: Path) -> list[str]:
    out: list[str] = []
    for lineno, raw in enumerate(path.read_text().splitlines(), start=1):
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith("--"):
            flag, _, rest = line.partition(" ")
            rest = rest.strip()
            if not flag.startswith("--"):
                raise SystemExit(f"{path}:{lineno}: bad flag {flag!r}")
            out.append(flag)
            if rest:
                out.append(rest)
            continue
        if any(ch.isspace() for ch in line):
            raise SystemExit(f"{path}:{lineno}: positional token contains whitespace")
        out.append(line)
    if not out:
        raise SystemExit(f"{path}: profile has no arguments")
    return out


def pairs(argv: list[str]) -> dict[str, str | None]:
    found: dict[str, str | None] = {}
    i = 1 if argv and not argv[0].startswith("--") else 0
    while i < len(argv):
        token = argv[i]
        if not token.startswith("--"):
            raise SystemExit(f"unexpected positional after the model id: {token}")
        if i + 1 < len(argv) and not argv[i + 1].startswith("--"):
            found[token] = argv[i + 1]
            i += 2
        else:
            found[token] = None
            i += 1
    return found


def check_contract(path: Path) -> list[str]:
    argv = tokens(path)
    if argv[0] != MODEL_ID:
        raise SystemExit(f"{path}: model id must be {MODEL_ID}, got {argv[0]!r}")
    found = pairs(argv)
    for flag, value in REQUIRED_VALUES.items():
        if found.get(flag) != value:
            raise SystemExit(f"{path}: {flag} must be {value!r}, got {found.get(flag)!r}")
    gpu_mem = found.get("--gpu-memory-utilization")
    if gpu_mem not in ALLOWED_GPU_MEMORY:
        raise SystemExit(
            f"{path}: --gpu-memory-utilization must be one of "
            f"{sorted(ALLOWED_GPU_MEMORY)}, got {gpu_mem!r}"
        )
    for flag in REQUIRED_FLAGS:
        if flag not in found:
            raise SystemExit(f"{path}: missing {flag}")
    if "--enable-prefix-caching" in found and "--disable-prefix-caching" in found:
        raise SystemExit(f"{path}: prefix caching is both enabled and disabled")
    if "--speculative-config" in found:
        raw = found["--speculative-config"]
        if not raw:
            raise SystemExit(f"{path}: --speculative-config needs a JSON value")
        try:
            spec = json.loads(raw)
        except json.JSONDecodeError as exc:
            raise SystemExit(f"{path}: speculative-config is not JSON: {exc}") from exc
        if spec.get("method") != "mtp":
            raise SystemExit(f"{path}: speculative method must be mtp")
        if spec.get("model") != MODEL_ID:
            raise SystemExit(f"{path}: speculative model must be {MODEL_ID}")
        k = spec.get("num_speculative_tokens")
        if not isinstance(k, int) or isinstance(k, bool) or k < 1:
            raise SystemExit(f"{path}: num_speculative_tokens must be a positive integer")
    if "--enable-prefix-caching" in found and found.get("--mamba-cache-mode") != "align":
        raise SystemExit(
            f"{path}: prefix caching on requires --mamba-cache-mode align "
            "(same line as run5; this image warns that the flag has no effect)"
        )
    return argv


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        print("Usage: parse_profile.py [--check-contract] profile.args", file=sys.stderr)
        return 2
    check = False
    path_arg = argv[1]
    if argv[1] == "--check-contract":
        check = True
        if len(argv) != 3:
            print("Usage: parse_profile.py --check-contract profile.args", file=sys.stderr)
            return 2
        path_arg = argv[2]
    path = Path(path_arg)
    got = check_contract(path) if check else tokens(path)
    for token in got:
        print(token)
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
