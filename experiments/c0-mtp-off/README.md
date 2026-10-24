# Experiment C0 — MTP disabled

## Hypothesis

Control row for the speculative-token sweep. Acceptance rate is undefined. Later `k` rows are judged by Final `S`, not by draft acceptance.

## Knobs

Under test: no `--speculative-config`. Prefix caching stays off for the whole C sweep so MTP is not paired with APC.

The plan says to hold the best APC setting. Measured Finals with MTP and explicit prefix caching fell to about 1% cache hits and `η` under the Final baseline, so the APC setting held here is off.

Same server command as `a-awq-control` and `b-apc-off`.

Held fixed: weights, served name, `--gpu-memory-utilization 0.90`, `--max-model-len 40960`, tool-call parser `qwen3_coder`, reasoning parser `qwen3`, chunked prefill on, `--max-num-batched-tokens 8192`, `--max-num-seqs 32`, card-default power. GPU memory stays at the run default `0.90` (the plan's `0.92` is not introduced here). Prefix caching off.

## Accuracy

This is the accuracy reference for C1–C3. Temperature-0 verification should reproduce these tokens. A later `k` that moves macro-accuracy, or a family under the 75% retention line, loses.

## Energy (`sE`)

Joules and SLO-met on this row are the energy baseline for the sweep. A higher acceptance rate on C1–C3 is not an energy win unless `η` rises.

## Latency (`sL`) and throughput (`sT`)

TTFT and TPOT here are the latency baseline. MTP can only help `sL` if p95 TPOT moves toward 50 ms without blowing TTFT.

Peak SLO share is the `sT` baseline. At 4 req/s the batch is large and speculative verification can spend the gain.

## How to run

From the repo root. These commands do not request `http://103.153.118.56:8000/v1`.

```bash
export VLLM_IMAGE=vllm/vllm-openai@sha256:cb12c3016938a4ee98ed176ac833984089460689a0982cff4b5a60bb45b3cded
export CONTAINER_NAME=mango-vllm
export PORT=8000
export BIND=0.0.0.0
./lib/flag-check.sh experiments/c0-mtp-off/profile.args
./experiments/c0-mtp-off/run.sh
./experiments/c0-mtp-off/run.sh --check
```

On the GPU VM, after flag-check prints `RESULT: FLAG CHECK PASSED`:

```bash
GREENMIND_CONFIRM_LAUNCH=1 ./experiments/c0-mtp-off/run.sh --launch
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
| `c0-mtp-off` | | | | | | | | | |
