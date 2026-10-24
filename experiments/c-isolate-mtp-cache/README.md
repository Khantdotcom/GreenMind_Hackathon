# Isolation — MTP k=1 plus prefix caching

## Hypothesis

This is the measured failure mode, not a candidate. MTP k=1 with explicit prefix caching collapsed prefix hits to about 1% and left Final `η` under baseline (about 0.92×, and about 0.80× when a power cap was added). Draft acceptance on that shape was high (about 91.5%) and the Final score was still 0 because `sE` clipped at 0. Launch this only to reproduce that collapse.

## Knobs

Under test, together: `--speculative-config` with `num_speculative_tokens=1` and `--enable-prefix-caching` (plus the deprecated `--mamba-cache-mode align` line).

Section 4 of `experimentation_steps.md` also pairs MTP, at k=3, with prefix caching. That pairing is the same failure class and is not given a second launch profile. k=1 is the width that was actually measured.

No `GREENMIND_POWER_W`. The cap-plus-MTP loss is a separate measured failure and is not turned back on here.

Held fixed: weights, served name, `--gpu-memory-utilization 0.90`, `--max-model-len 40960`, tool-call parser `qwen3_coder`, reasoning parser `qwen3`, chunked prefill on, `--max-num-batched-tokens 8192`, `--max-num-seqs 32`, card-default power. GPU memory stays at the run default `0.90` (the plan's `0.92` is not introduced here). Launch requires `--isolate-failure`.

## Accuracy

Accuracy may still look fine. A fine accuracy number does not rescue `sE` when `η` is under `0.00163`.

## Energy (`sE`)

Expect prefix-cache hit rate near the measured ~1%, `η` at or under `0.00163`, and `sE = 0`. Do not submit this configuration as a Final candidate.

## Latency (`sL`) and throughput (`sT`)

TTFT should lose the cache win and can land in the multi-second range seen on the failed Finals (p95 TTFT 3.59 s and 7.82 s are priors, not predictions for this launch).

Peak SLO share is expected to suffer with TTFT. Record it so the isolation is comparable, then discard the config.

## How to run

From the repo root. These commands do not request `http://103.153.118.56:8000/v1`.

```bash
export VLLM_IMAGE=vllm/vllm-openai@sha256:cb12c3016938a4ee98ed176ac833984089460689a0982cff4b5a60bb45b3cded
export CONTAINER_NAME=mango-vllm
export PORT=8000
export BIND=0.0.0.0
./lib/flag-check.sh experiments/c-isolate-mtp-cache/profile.args
./experiments/c-isolate-mtp-cache/run.sh
./experiments/c-isolate-mtp-cache/run.sh --check
```

On the GPU VM, after flag-check prints `RESULT: FLAG CHECK PASSED`:

```bash
GREENMIND_CONFIRM_LAUNCH=1 ./experiments/c-isolate-mtp-cache/run.sh --launch --isolate-failure
```

`GREENMIND_POWER_W` must be unset. The runner refuses a power cap.
Container name `mango-vllm`, bind `0.0.0.0:8000`, image digest above, Hugging Face cache mount `$HOME/.cache/huggingface:/root/.cache/huggingface`, and labels `greenmind.run`, `greenmind.tier`, `greenmind.bind` match `docs/ops/docker-defaults.md`.
Served name `mango1.5-awq-w4a16`. Weights `CMKL/MANGO1.5-Qwen3.5-9B-AWQ-W4A16-mtp`.
The runner does not remove an existing `mango-vllm` container and does not call `lib/start.sh`.

## Score context

`S = 100 · A · sE^0.6 · sT^0.2 · sL^0.2` on the Final track.
`η_base = 0.00163`, `K = 3`, full energy at `η = 0.00489` (about 204 J per SLO-met request).
Reference macro-accuracy `87.8%`. Full accuracy gate at `R ≥ 0.98` (macro about `86.0%`).
TTFT SLO is `0.5 s + 0.25 s` per 1k input tokens. TPOT SLO is `50 ms`.
Copy the grader History row into `experiments/ledger.template.csv`. Turn that row into factors with `python3 experiments/lib/score.py` and the measured fields. This README does not claim an `S`.

## Blank measurement row

| run_id | macro | SLO-met | joules | p95 TTFT | p95 TPOT | prefix hits | MTP accept | preemptions | S |
|---|---|---|---|---|---|---|---|---|---|
| `c-isolate-mtp-cache` | | | | | | | | | |
