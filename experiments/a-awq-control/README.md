# Experiment A — AWQ control, no APC, no MTP

## Hypothesis

The AWQ W4A16 checkpoint, with prefix caching and MTP both off, is the candidate-model control. It separates quantization from the serving knobs in later rows. Macro-accuracy should stay near the Final reference `87.8%`, and decode joules should fall versus the untuned BF16 baseline because the A100 decode path is memory-bound.

## Knobs

Under test: AWQ weights `CMKL/MANGO1.5-Qwen3.5-9B-AWQ-W4A16-mtp`, `--disable-prefix-caching`, no `--speculative-config`.

Same command as `b-apc-off` and `c0-mtp-off`. Those rows are the controls of the next factors, not extra server shapes.

Held fixed: weights, served name, `--gpu-memory-utilization 0.90`, `--max-model-len 40960`, tool-call parser `qwen3_coder`, reasoning parser `qwen3`, chunked prefill on, `--max-num-batched-tokens 8192`, `--max-num-seqs 32`, card-default power. GPU memory stays at the run default `0.90` (the plan's `0.92` is not introduced here).

## Accuracy

Expect the accuracy factor near 1. Measured AWQ Finals stayed in about 85.6–88.4% macro (`A` about 0.98–1.00). Full `A` needs `R ≥ 0.98`, about 86.0% macro. If a family with at least 20 items keeps under 75% of its own baseline, stop and diagnose accuracy before reading energy.

## Energy (`sE`)

Expect `η` above `0.00163` when SLO-met does not collapse. Quantization is the adopted energy lever. No watt cap: a cap before the TPOT SLO has headroom has not cleared the Final energy cliff.

## Latency (`sL`) and throughput (`sT`)

TPOT can still miss 50 ms at the 4 req/s peak, because prefill and decode still share steps. TTFT gets no prefix reuse, including on the 50-request shared ~20k prefix cohort.

Do not expect `sT` or `sL` to saturate. This row is the control those later factors are judged against.

## How to run

From the repo root. These commands do not request `http://103.153.118.56:8000/v1`.

```bash
export VLLM_IMAGE=vllm/vllm-openai@sha256:cb12c3016938a4ee98ed176ac833984089460689a0982cff4b5a60bb45b3cded
export CONTAINER_NAME=mango-vllm
export PORT=8000
export BIND=0.0.0.0
./lib/flag-check.sh experiments/a-awq-control/profile.args
./experiments/a-awq-control/run.sh
./experiments/a-awq-control/run.sh --check
```

On the GPU VM, after flag-check prints `RESULT: FLAG CHECK PASSED`:

```bash
GREENMIND_CONFIRM_LAUNCH=1 ./experiments/a-awq-control/run.sh --launch
```

`GREENMIND_POWER_W` must be unset. The runner refuses a power cap.
Container name `mango-vllm`, bind `0.0.0.0:8000`, image digest above, Hugging Face cache mount `$HOME/.cache/huggingface:/root/.cache/huggingface`, and labels `greenmind.run`, `greenmind.tier`, `greenmind.bind` match `docs/ops/docker-defaults.md`.
Served name `mango1.5-awq-w4a16`. Weights `CMKL/MANGO1.5-Qwen3.5-9B-AWQ-W4A16-mtp`.
On `--launch`, the runner removes any existing `mango-vllm` first and creates a new container. It does not attach to a previous server and does not call `lib/start.sh`.

## Score context

`S = 100 · A · sE^0.6 · sT^0.2 · sL^0.2` on the Final track.
`η_base = 0.00163`, `K = 3`, full energy at `η = 0.00489` (about 204 J per SLO-met request).
Reference macro-accuracy `87.8%`. Full accuracy gate at `R ≥ 0.98` (macro about `86.0%`).
TTFT SLO is `0.5 s + 0.25 s` per 1k input tokens. TPOT SLO is `50 ms`.
Copy the grader History row into `experiments/ledger.template.csv`. Turn that row into factors with `python3 experiments/lib/score.py` and the measured fields. This README does not claim an `S`.

## Blank measurement row

| run_id | macro | SLO-met | joules | p95 TTFT | p95 TPOT | prefix hits | MTP accept | preemptions | S |
|---|---|---|---|---|---|---|---|---|---|
| `a-awq-control` | | | | | | | | | |
