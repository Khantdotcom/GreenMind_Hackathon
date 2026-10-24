# Experiment B — prefix caching off

## Hypothesis

Explicit cache disable is the APC control. Shared-prefix requests (the ~20k-token cohort, plus agentic and RAG repeats) should show an empty prefix-hit metric and should pay full prefill cost. Unique prompts should look like the APC-on row.

## Knobs

Under test: `--disable-prefix-caching`. MTP stays off so this comparison does not mix in the measured MTP+cache collapse.

Pair this directory with `b-apc-on`. The server command matches `a-awq-control` and `c0-mtp-off`.

Held fixed: weights, served name, `--gpu-memory-utilization 0.90`, `--max-model-len 40960`, tool-call parser `qwen3_coder`, reasoning parser `qwen3`, chunked prefill on, `--max-num-batched-tokens 8192`, `--max-num-seqs 32`, card-default power. GPU memory stays at the run default `0.90` (the plan's `0.92` is not introduced here).

## Accuracy

Accuracy should match Experiment A. Prefix caching does not change temperature-0 tokens when the cache is correct. A mismatch is a failed cache, not a win.

## Energy (`sE`)

Expect more GPU joules than `b-apc-on` on any cohort that repeats a prefix, because those prompts are prefilled again. Idle joules inside the window still count.

## Latency (`sL`) and throughput (`sT`)

Expect higher TTFT on shared prefixes than `b-apc-on`. TPOT should stay close to the APC-on row if the only change is prefill reuse.

Peak SLO share (`sT`) can fall if long repeated prefills push TTFT past `0.5 s + 0.25 s` per 1k input tokens.

## How to run

From the repo root. These commands do not request `http://103.153.118.56:8000/v1`.

```bash
export VLLM_IMAGE=vllm/vllm-openai@sha256:cb12c3016938a4ee98ed176ac833984089460689a0982cff4b5a60bb45b3cded
export CONTAINER_NAME=mango-vllm
export PORT=8000
export BIND=0.0.0.0
./lib/flag-check.sh experiments/b-apc-off/profile.args
./experiments/b-apc-off/run.sh
./experiments/b-apc-off/run.sh --check
```

On the GPU VM, after flag-check prints `RESULT: FLAG CHECK PASSED`:

```bash
GREENMIND_CONFIRM_LAUNCH=1 ./experiments/b-apc-off/run.sh --launch
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
| `b-apc-off` | | | | | | | | | |
