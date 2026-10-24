#!/usr/bin/env python3
"""Contract tests for the experiment suite. No Docker daemon and no graded score."""

from __future__ import annotations

import json
import math
import os
import subprocess
import sys
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
EXP = REPO / "experiments"
sys.path.insert(0, str(EXP / "lib"))

import parse_profile  # noqa: E402
import score  # noqa: E402

PIN = "vllm/vllm-openai@sha256:cb12c3016938a4ee98ed176ac833984089460689a0982cff4b5a60bb45b3cded"
PUBLIC = "http://103.153.118.56:8000/v1"
MODEL = "CMKL/MANGO1.5-Qwen3.5-9B-AWQ-W4A16-mtp"

LAUNCH = [
    "a-awq-control",
    "b-apc-off",
    "b-apc-on",
    "c0-mtp-off",
    "c1-mtp-k1",
    "c2-mtp-k2",
    "c3-mtp-k3",
    "c-isolate-mtp-cache",
    "d1-batched-4096",
    "d2-batched-8192",
    "d3-batched-16384",
    "e-seqs-16",
    "e-seqs-32",
    "e-seqs-64",
    "final-combined",
    "final-g0-prefix-match-16",
    "final-combined-v2",
    "final-a-budget-1536",
    "final-b-budget-3072",
    "final-c-mtp-default-apc",
    "final-d-active-seqs-80",
    "final-e-active-seqs-96",
    "final-rounded",
    "final-sa-active-64",
    "final-sa-active-72",
    "final-sa-active-80",
    "final-sa-active-88",
    "final-sa-active-96",
]

STAGE_A = (
    "final-sa-active-64",
    "final-sa-active-72",
    "final-sa-active-80",
    "final-sa-active-88",
    "final-sa-active-96",
)


def fail(message: str) -> None:
    raise SystemExit(message)


def argv_of(exp_id: str) -> list[str]:
    return parse_profile.check_contract(EXP / exp_id / "profile.args")


def flag_map(argv: list[str]) -> dict[str, str | None]:
    return parse_profile.pairs(argv)


def assert_true(cond: bool, message: str) -> None:
    if not cond:
        fail(message)


def check_profiles() -> None:
    commands = {exp_id: argv_of(exp_id) for exp_id in LAUNCH}
    assert_true(commands["a-awq-control"] == commands["b-apc-off"] == commands["c0-mtp-off"],
                "A, B-off, and C0 must share the control command")
    assert_true(commands["b-apc-on"] == commands["d2-batched-8192"] == commands["e-seqs-32"],
                "B-on, D2, and E32 must share the APC-on control command")

    gate0 = {
        "final-combined",
        "final-g0-prefix-match-16",
        "final-combined-v2",
        "final-a-budget-1536",
        "final-b-budget-3072",
        "final-c-mtp-default-apc",
        "final-d-active-seqs-80",
        "final-e-active-seqs-96",
        "final-rounded",
    }
    high_mem = gate0 | set(STAGE_A)
    gate0_apc_no_spec = {
        "final-combined",
        "final-g0-prefix-match-16",
        "final-combined-v2",
        "final-a-budget-1536",
        "final-b-budget-3072",
        "final-d-active-seqs-80",
        "final-e-active-seqs-96",
        "final-rounded",
    } | set(STAGE_A)
    for exp_id, argv in commands.items():
        flags = flag_map(argv)
        text = (EXP / exp_id / "profile.args").read_text()
        if exp_id in high_mem:
            assert_true(flags.get("--gpu-memory-utilization") == "0.95", f"{exp_id} gpu memory")
        else:
            assert_true(flags.get("--gpu-memory-utilization") == "0.90", f"{exp_id} gpu memory")
            assert_true("0.95" not in text, f"{exp_id} drifted to gpu memory 0.95")
        assert_true("mango-awq-mtp" not in text, f"{exp_id} drifted the served name")
        assert_true("FLASHINFER" not in text, f"{exp_id} adds an attention backend")
        assert_true("--enable-chunked-prefill" in flags, f"{exp_id} missing chunked prefill")
        assert_true(flags.get("--max-model-len") == "40960", f"{exp_id} max-model-len")
        has_spec = "--speculative-config" in flags
        has_apc = "--enable-prefix-caching" in flags
        if has_spec and has_apc:
            spec = json.loads(flags["--speculative-config"])
            assert_true(spec.get("method") == "mtp", f"{exp_id} non-MTP speculation with APC")
            assert_true(exp_id == "c-isolate-mtp-cache", f"{exp_id} MTP+cache pairing")
        if exp_id in STAGE_A:
            assert_true(flags.get("--max-num-seqs") == "128", f"{exp_id} runner size")
            assert_true("--max-num-active-seqs" in flags, f"{exp_id} active cap")
            assert_true(flags.get("--max-num-batched-tokens") == "2048", f"{exp_id} budget")
        elif exp_id not in gate0:
            assert_true("--max-num-seqs" in flags, f"{exp_id} should set max-num-seqs")
        else:
            assert_true("--max-num-seqs" not in flags, f"{exp_id} must leave max-num-seqs unset")
        if exp_id in gate0_apc_no_spec:
            assert_true("--speculative-config" not in flags, f"{exp_id} must leave speculation off")
            assert_true("--enable-prefix-caching" in flags, f"{exp_id} must keep APC on")
    assert_true(flag_map(commands["final-combined"])["--max-num-batched-tokens"] == "2048",
                "final-combined budget")
    g0_prefix = flag_map(commands["final-g0-prefix-match-16"])
    assert_true(g0_prefix["--prefix-match-unit"] == "16", "g0 prefix-match unit")
    assert_true(g0_prefix["--max-num-batched-tokens"] == "2048", "g0 prefix-match budget")
    assert_true("--max-num-active-seqs" not in g0_prefix, "g0 prefix-match leaves active seqs unset")
    assert_true("--mamba-ssm-cache-dtype" not in g0_prefix, "g0 prefix-match is not the rounded stack")
    assert_true("--speculative-config" not in g0_prefix, "g0 prefix-match leaves MTP off")
    stripped_prefix: list[str] = []
    skip_value = False
    for token in commands["final-g0-prefix-match-16"]:
        if skip_value:
            skip_value = False
            continue
        if token == "--prefix-match-unit":
            skip_value = True
            continue
        stripped_prefix.append(token)
    assert_true(stripped_prefix == commands["final-combined"],
                "g0 prefix-match differs from Gate 0 only by --prefix-match-unit")
    assert_true(flag_map(commands["final-combined-v2"])["--max-num-batched-tokens"] == "1024",
                "final-combined-v2 budget")
    assert_true(flag_map(commands["final-a-budget-1536"])["--max-num-batched-tokens"] == "1536",
                "final-a budget")
    assert_true(flag_map(commands["final-b-budget-3072"])["--max-num-batched-tokens"] == "3072",
                "final-b budget")
    c_flags = flag_map(commands["final-c-mtp-default-apc"])
    c_spec = json.loads(c_flags["--speculative-config"])
    assert_true(c_spec["method"] == "mtp" and c_spec["num_speculative_tokens"] == 1, "final-c MTP k=1")
    assert_true(c_flags["--max-num-batched-tokens"] == "2048", "final-c keeps Gate 0 budget")
    assert_true("--enable-prefix-caching" not in c_flags, "final-c omits explicit APC enable")
    assert_true("--disable-prefix-caching" not in c_flags, "final-c omits explicit APC disable")
    assert_true("--mamba-cache-mode" not in c_flags, "final-c omits mamba align without APC flag")
    assert_true(flag_map(commands["final-d-active-seqs-80"])["--max-num-active-seqs"] == "80",
                "final-d active seqs")
    assert_true(flag_map(commands["final-e-active-seqs-96"])["--max-num-active-seqs"] == "96",
                "final-e active seqs")
    assert_true(flag_map(commands["final-d-active-seqs-80"])["--max-num-batched-tokens"] == "2048",
                "final-d keeps Gate 0 budget")
    assert_true("--max-num-seqs" not in flag_map(commands["final-d-active-seqs-80"]),
                "final-d must not set max-num-seqs")
    rounded = flag_map(commands["final-rounded"])
    assert_true(rounded["--max-num-batched-tokens"] == "2048", "rounded budget")
    assert_true(rounded["--max-num-active-seqs"] == "80", "rounded active seqs")
    assert_true(rounded["--mamba-ssm-cache-dtype"] == "bfloat16", "rounded mamba dtype")
    assert_true(rounded["--prefix-match-unit"] == "16", "rounded prefix match")
    assert_true("--speculative-config" not in rounded, "rounded leaves MTP off")
    for n, exp_id in ((64, "final-sa-active-64"), (72, "final-sa-active-72"),
                      (80, "final-sa-active-80"), (88, "final-sa-active-88"),
                      (96, "final-sa-active-96")):
        assert_true(flag_map(commands[exp_id])["--max-num-active-seqs"] == str(n),
                    f"{exp_id} active")

    assert_true("--disable-prefix-caching" in commands["a-awq-control"], "A must disable prefix caching")
    assert_true("--speculative-config" not in commands["a-awq-control"], "A must not enable MTP")
    assert_true("--enable-prefix-caching" not in commands["a-awq-control"], "A must not enable APC")

    for k, exp_id in ((1, "c1-mtp-k1"), (2, "c2-mtp-k2"), (3, "c3-mtp-k3")):
        flags = flag_map(commands[exp_id])
        spec = json.loads(flags["--speculative-config"])
        assert_true(spec["num_speculative_tokens"] == k, f"{exp_id} k")
        assert_true(spec["method"] == "mtp", f"{exp_id} method")
        assert_true(spec["model"] == MODEL, f"{exp_id} model")
        assert_true("--disable-prefix-caching" in commands[exp_id], f"{exp_id} cache must be off")
        assert_true("--enable-prefix-caching" not in commands[exp_id], f"{exp_id} cache flag")

    isolate = json.loads(flag_map(commands["c-isolate-mtp-cache"])["--speculative-config"])
    assert_true(isolate["num_speculative_tokens"] == 1, "isolation width is the measured k=1")
    assert_true(flag_map(commands["c-isolate-mtp-cache"]).get("--mamba-cache-mode") == "align",
                "isolation keeps the run5 mamba line")

    assert_true(flag_map(commands["d1-batched-4096"])["--max-num-batched-tokens"] == "4096", "D1")
    assert_true(flag_map(commands["d3-batched-16384"])["--max-num-batched-tokens"] == "16384", "D3")
    assert_true(flag_map(commands["e-seqs-16"])["--max-num-seqs"] == "16", "E16")
    assert_true(flag_map(commands["e-seqs-64"])["--max-num-seqs"] == "64", "E64")
    assert_true("--speculative-config" not in commands["e-seqs-64"], "E64 must not add MTP")
    assert_true("--enable-prefix-caching" in commands["d1-batched-4096"], "D holds APC on")
    assert_true("--speculative-config" not in commands["d3-batched-16384"], "D holds MTP off")


def check_static_text() -> None:
    defaults = (EXP / "defaults.env").read_text()
    for needle in (PIN, PUBLIC, "mango-vllm", MODEL, "mango1.5-awq-w4a16", "0.00163", "0.0.0.0"):
        assert_true(needle in defaults, f"defaults.env missing {needle}")
    entry = (EXP / "lib" / "entry.sh").read_text()
    assert_true('"$REPO/lib/flag-check.sh"' in entry, "entry.sh must call lib/flag-check.sh")
    executable = "\n".join(line.split("#", 1)[0] for line in entry.splitlines())
    assert_true("start.sh" not in executable, "entry.sh must not invoke a start.sh launcher")
    assert_true("preflight" not in executable, "entry.sh must not invoke preflight")
    assert_true("docker rm -f" in executable, "entry.sh must replace mango-vllm in place")
    assert_true("Replacing existing" in entry, "entry.sh must describe replace-in-place")
    assert_true("LOCAL_BASE_URL" in entry and "/models" in entry, "entry.sh must wait on local /models")
    assert_true("103.153.118.56" not in executable, "entry.sh must not request the public grader URL")
    assert_true(
        'curl -fsS --max-time 5 "${LOCAL_BASE_URL}/models"' in entry,
        "entry.sh must curl local /models only",
    )
    for path in EXP.rglob("*.sh"):
        if path.name == "entry.sh":
            continue
        body = "\n".join(line.split("#", 1)[0] for line in path.read_text().splitlines())
        assert_true("curl " not in body, f"{path} must not curl")
        assert_true("docker rm" not in body, f"{path} must not remove containers")
    plan = (EXP / "04-candidate-integrated" / "plan-command.args").read_text()
    assert_true("mango-awq-mtp" in plan and "0.92" in plan and "FLASHINFER" in plan, "plan citation drifted")
    assert_true("--enable-prefix-caching" in plan and "--speculative-config" in plan, "plan citation lost the pair")
    assert_true(not (EXP / "04-candidate-integrated" / "profile.args").exists(),
                "section 4 must not grow a launchable profile.args")


def run_script(
    script: Path,
    args: list[str],
    stub_bin: Path,
    log: Path,
    extra_env: dict[str, str] | None = None,
) -> subprocess.CompletedProcess[str]:
    env = os.environ.copy()
    env.pop("VLLM_IMAGE", None)
    env.pop("GREENMIND_POWER_W", None)
    env.pop("GREENMIND_CONFIRM_LAUNCH", None)
    env["PATH"] = str(stub_bin) + os.pathsep + env.get("PATH", "")
    env["DOCKER_STUB_LOG"] = str(log)
    if extra_env:
        env.update(extra_env)
    return subprocess.run(
        ["bash", str(script), *args],
        cwd=REPO,
        env=env,
        text=True,
        capture_output=True,
        check=False,
    )


def check_scripts() -> None:
    bin_dir = Path(tempfile.mkdtemp(prefix="gm-docker-stub-"))
    docker_stub = bin_dir / "docker"
    docker_stub.write_text(
        "#!/bin/sh\n"
        "echo \"docker invoked: $*\" >> \"${DOCKER_STUB_LOG:?}\"\n"
        "exit 99\n"
    )
    docker_stub.chmod(0o755)
    log = bin_dir / "docker.log"
    for exp_id in LAUNCH:
        log.write_text("")
        result = run_script(EXP / exp_id / "run.sh", [], bin_dir, log)
        assert_true(result.returncode == 0, f"{exp_id} print failed\n{result.stderr}")
        assert_true(PIN in result.stdout, f"{exp_id} print dropped the image digest")
        assert_true(PUBLIC in result.stdout, f"{exp_id} print dropped the public endpoint")
        assert_true("mango-vllm" in result.stdout, f"{exp_id} print dropped the container name")
        assert_true(
            "wait on" in result.stdout and "models" in result.stdout,
            f"{exp_id} print must say launch waits on local /models",
        )
        assert_true(
            "replace in place" in result.stdout or "reuse name" in result.stdout,
            f"{exp_id} print must say launch reuses/replaces mango-vllm in place",
        )
        assert_true(log.read_text() == "", f"{exp_id} print invoked docker\n{log.read_text()}")
        refused = run_script(EXP / exp_id / "run.sh", ["--launch"], bin_dir, log)
        assert_true(refused.returncode != 0, f"{exp_id} launch without confirm succeeded")
        assert_true(log.read_text() == "", f"{exp_id} refused launch still called docker")

    log.write_text("")
    isolate = run_script(
        EXP / "c-isolate-mtp-cache" / "run.sh",
        ["--launch"],
        bin_dir,
        log,
        {"GREENMIND_CONFIRM_LAUNCH": "1"},
    )
    assert_true(isolate.returncode != 0, "isolation launch without --isolate-failure succeeded")
    assert_true("docker invoked" not in log.read_text(), "isolation refusal called docker")

    log.write_text("")
    powered = run_script(
        EXP / "a-awq-control" / "run.sh",
        [],
        bin_dir,
        log,
        {"GREENMIND_POWER_W": "250"},
    )
    assert_true(powered.returncode != 0, "power cap was accepted")

    for script in (
        EXP / "03-reference-baseline" / "run.sh",
        EXP / "04-candidate-integrated" / "run.sh",
    ):
        log.write_text("")
        result = run_script(script, [], bin_dir, log)
        assert_true(result.returncode == 0, f"{script.name} failed\n{result.stderr}\n{result.stdout}")
        assert_true(log.read_text() == "", f"{script.parent.name} invoked docker")
        refused = run_script(script, ["--launch"], bin_dir, log)
        assert_true(refused.returncode != 0, f"{script.parent.name} launch was accepted")


def check_score_and_manifest() -> None:
    ratios = score.check_formula()
    assert_true(abs(ratios["1.25x"] - (math.log(1.25) / math.log(3))) < 1e-12, "sE 1.25x")
    proc = subprocess.run(
        [sys.executable, str(EXP / "lib" / "score.py"), "--check-formula"],
        text=True,
        capture_output=True,
        check=False,
    )
    assert_true(proc.returncode == 0, proc.stderr)
    payload = json.loads(proc.stdout)
    assert_true(payload["graded_score"] is False, "formula check must not look graded")
    assert_true(payload["track"] == "final", "track")

    missing = subprocess.run(
        [sys.executable, str(EXP / "lib" / "score.py"), "--macro", "0.878"],
        text=True,
        capture_output=True,
        check=False,
    )
    assert_true(missing.returncode != 0, "partial measurements must not produce S")

    se = math.log(1.25) / math.log(3)
    st = 0.4
    sl = 0.5
    expected = 100.0 * (se ** 0.6) * (st ** 0.2) * (sl ** 0.2)
    # eta = 1.25 * 0.00163 with 125 SLO-met => joules = 125 / eta
    joules = 125 / (1.25 * score.ETA_BASE)
    proc = subprocess.run(
        [
            sys.executable,
            str(EXP / "lib" / "score.py"),
            "--macro", "0.878",
            "--slo-met", "125",
            "--joules", str(joules),
            "--peak-requests", "100",
            "--peak-slo-met", "40",
            "--p95-ttft-over-slo", "2",
            "--p95-tpot-ms", "100",
        ],
        text=True,
        capture_output=True,
        check=False,
    )
    assert_true(proc.returncode == 0, proc.stderr)
    got = json.loads(proc.stdout)
    assert_true(got["graded_score"] is False, "computed row must say it is not graded")
    assert_true(abs(got["S"] - expected) < 1e-9, f"S {got['S']} != {expected}")
    assert_true(abs(got["sL"] - 0.5) < 1e-12, "sL")

    manifest = EXP / "workload" / "check_manifest.py"
    template = subprocess.run(
        [sys.executable, str(manifest), str(EXP / "workload" / "manifest.template.csv")],
        text=True,
        capture_output=True,
        check=False,
    )
    assert_true(template.returncode == 0, template.stderr)
    with tempfile.TemporaryDirectory() as tmp:
        bad = Path(tmp) / "bad.csv"
        bad.write_text(
            "request_id,family,prompt_hash,input_tokens,max_output_tokens,arrival_time,peak_phase,expected_answer_or_evaluator_id,stress_slice\n"
            "r1,chat,abc,40000,5000,0,1,eval,\n"
        )
        rejected = subprocess.run(
            [sys.executable, str(manifest), str(bad)],
            text=True,
            capture_output=True,
            check=False,
        )
        assert_true(rejected.returncode != 0, "over-long manifest row was accepted")


def main() -> int:
    check_profiles()
    check_static_text()
    check_scripts()
    check_score_and_manifest()
    print(f"ok: {len(LAUNCH)} launch profiles, baseline, section 4, formula")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
