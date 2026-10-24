# Experiment D — batched tokens 4096

## Hypothesis

A 4096 token budget should protect decode TPOT during the 10-prompt ~30k burst, and it can stretch TTFT on those long prefills. Long-context TTFT SLO is `0.5 s + 0.25 s` per 1k input tokens (about 5.5 s at 20k, about 8 s at 30k). Missing that SLO drops both `sL` and the `η` numerator.

## Knobs

Under test: `--max-num-batched-tokens 4096` with `--enable-chunked-prefill`.

APC is held on and MTP is held off. That is the pre-registered pair from measured Finals: caching on was the best Final, and MTP plus caching lost the energy cliff. If a new A–C Final contradicts that pair, do not promote this row.

Held fixed: Weights and contract flags, `--gpu-memory-utilization 0.90`, `--max-model-len 40960`, `--max-num-seqs 32`, prefix caching on, MTP off, chunked prefill on, card-default power.

## Accuracy

Accuracy should match the APC-on control. The token budget does not change weights or sampling.

## Energy (`sE`)

Energy moves through the SLO-met count. A budget that creates more SLO-met requests at similar joules raises `η`. A budget that keeps the GPU busy longer with misses can lower it. Full `sE` is still `η ≥ 0.00489`.

## Latency (`sL`) and throughput (`sT`)

Watch p95 TPOT during the long-prompt burst and p95 of TTFT/SLO for the long prefills. `sL` is the square root of those two capped ratios.

Peak-phase SLO share is the `sT` readout. The image default budget on this A100 path was 2048; 4096, 8192, and 16384 are all above that.

## How to run

From the repo root. These commands do not request `http://103.153.118.56:8000/v1`.

```bash
export VLLM_IMAGE=vllm/vllm-openai@sha256:cb12c3016938a4ee98ed176ac833984089460689a0982cff4b5a60bb45b3cded
export CONTAINER_NAME=mango-vllm
export PORT=8000
export BIND=0.0.0.0
./lib/flag-check.sh experiments/d1-batched-4096/profile.args
./experiments/d1-batched-4096/run.sh
./experiments/d1-batched-4096/run.sh --check
```

On the GPU VM, after flag-check prints `RESULT: FLAG CHECK PASSED`:

```bash
GREENMIND_CONFIRM_LAUNCH=1 ./experiments/d1-batched-4096/run.sh --launch
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
| `d1-batched-4096` | | | | | | | | | |
