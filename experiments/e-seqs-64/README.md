# Experiment E — `--max-num-seqs 64`

## Hypothesis

A cap of 64 already lost a Final: `S=0`, 87/300, `η` about 0.94×, p95 TTFT 6.54 s, p95 TPOT 67 ms. The miss moved from TPOT toward TTFT. This row exists because the plan asks for 64. Expect it to confirm that loss under the 8192 budget, not to win. Stop the sweep if `S` falls. The batched-token budget is pre-registered at 8192, the `final-run3` change, because that History `S` is still missing and 8192 is the middle D row. If D picks a different winner, change this line before launching E.

## Knobs

Under test: `--max-num-seqs 64`.

Held: prefix caching on, MTP off, `--max-num-batched-tokens 8192`, chunked prefill on.

Held fixed: Weights and contract flags, `--gpu-memory-utilization 0.90`, `--max-model-len 40960`, prefix caching on, MTP off, `--max-num-batched-tokens 8192`, chunked prefill on, card-default power.

## Accuracy

No accuracy change is expected. A change means preemption or a bad cache, and the row fails.

## Energy (`sE`)

More sequences amortize a weight read until steps miss the TPOT SLO. Misses still burn joules and add nothing to `η`. `sE` is zero at or below `η = 0.00163`. The 64 cap already landed at about 0.94×.

## Latency (`sL`) and throughput (`sT`)

Record p95 TTFT/SLO and p95 TPOT together. A cap that trades one tail for the other can lower `sL` even when one of the two looks better.

`sT` is the share of the 4 req/s peak that met SLO. Queueing from a tight cap shows up there and in the `η` numerator.

## How to run

From the repo root. These commands do not request `http://103.153.118.56:8000/v1`.

```bash
export VLLM_IMAGE=vllm/vllm-openai@sha256:cb12c3016938a4ee98ed176ac833984089460689a0982cff4b5a60bb45b3cded
export CONTAINER_NAME=mango-vllm
export PORT=8000
export BIND=0.0.0.0
./lib/flag-check.sh experiments/e-seqs-64/profile.args
./experiments/e-seqs-64/run.sh
./experiments/e-seqs-64/run.sh --check
```

On the GPU VM, after flag-check prints `RESULT: FLAG CHECK PASSED`:

```bash
GREENMIND_CONFIRM_LAUNCH=1 ./experiments/e-seqs-64/run.sh --launch
```

`GREENMIND_POWER_W` must be unset. The runner refuses a power cap.
Container name `mango-vllm`, bind `0.0.0.0:8000`, image digest above, Hugging Face cache mount `$HOME/.cache/huggingface:/root/.cache/huggingface`, and labels `greenmind.run`, `greenmind.tier`, `greenmind.bind` match `docs/ops/docker-defaults.md`.
Served name `mango1.5-awq-w4a16`. Weights `CMKL/MANGO1.5-Qwen3.5-9B-AWQ-W4A16-mtp`.
On `--launch`, the runner reuses the name `mango-vllm` (replaces it in place if it already exists) so only one experiment serves `:8000`, then waits on local `http://127.0.0.1:8000/v1/models` and a local chat probe. It does not request `http://103.153.118.56:8000/v1` and does not call `lib/start.sh`. Final: 2 submissions/hour.

## Score context

`S = 100 · A · sE^0.6 · sT^0.2 · sL^0.2` on the Final track.
`η_base = 0.00163`, `K = 3`, full energy at `η = 0.00489` (about 204 J per SLO-met request).
Reference macro-accuracy `87.8%`. Full accuracy gate at `R ≥ 0.98` (macro about `86.0%`).
TTFT SLO is `0.5 s + 0.25 s` per 1k input tokens. TPOT SLO is `50 ms`.
Copy the grader History row into `experiments/ledger.template.csv`. Turn that row into factors with `python3 experiments/lib/score.py` and the measured fields. This README does not claim an `S`.

## Blank measurement row

| run_id | macro | SLO-met | joules | p95 TTFT | p95 TPOT | prefix hits | MTP accept | preemptions | S |
|---|---|---|---|---|---|---|---|---|---|
| `e-seqs-64` | | | | | | | | | |
