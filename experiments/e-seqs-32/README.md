# Experiment E — `--max-num-seqs 32`

## Hypothesis

32 is the plan's initial concurrency and is unmeasured against the uncapped best Final. It may sit between the TTFT damage of 64 and the queueing of 16. If p95 TTFT or p95 TPOT is worse than the uncapped server, do not keep the cap. The batched-token budget is pre-registered at 8192, the `final-run3` change, because that History `S` is still missing and 8192 is the middle D row. If D picks a different winner, change this line before launching E.

## Knobs

Under test: `--max-num-seqs 32`.

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
./lib/flag-check.sh experiments/e-seqs-32/profile.args
./experiments/e-seqs-32/run.sh
./experiments/e-seqs-32/run.sh --check
```

On the GPU VM, after flag-check prints `RESULT: FLAG CHECK PASSED`:

```bash
GREENMIND_CONFIRM_LAUNCH=1 ./experiments/e-seqs-32/run.sh --launch
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
| `e-seqs-32` | | | | | | | | | |
