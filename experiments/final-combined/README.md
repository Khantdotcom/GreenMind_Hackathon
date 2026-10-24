# Final combined — balance `sE`, `sT`, and `sL`

## Hypothesis

The measured Final limit is SLO-met count at the 4 req/s peak, not accuracy. The best recorded Final was `S=19.1`, 127/300, about 1.18× the Final energy baseline, p95 TTFT 2.16 s, p95 TPOT 82 ms, about 221 J/request, 44% prefix hits, and `A=1` (`sT` about 0.16, `sE` about 0.15). This profile keeps that accuracy-safe AWQ server, keeps prefix caching, leaves MTP off, sets the scheduler budget to 8192, and does not cap `--max-num-seqs` or GPU power.

**Measured Final (History #9):** `S=18.6`, A 0.97, R 0.974, sE 0.16, sT 0.15, sL 0.39, η 1.19×, 197 J/request, p95 TTFT 2.45 s, p95 TPOT **87 ms**, **115/300**, macro 85.5%. Budget 8192 did not beat the best Final; next graded arm is [`final-combined-v2`](../final-combined-v2/README.md) (ITL-first: budget **1024**, mem **0.95**).

## Knobs

Combined knobs:

- `--enable-prefix-caching` and `--mamba-cache-mode align` for prefill reuse (`sE`, TTFT side of `sL`).
- `--max-num-batched-tokens 8192` and `--enable-chunked-prefill` so mixed prefill/decode steps shrink (TPOT side of `sL`, and `sT`).
- No `--speculative-config`. MTP with caching collapsed hits.
- No `--max-num-seqs`. The best measured Final was uncapped. A cap of 64 lost the energy cliff. Experiment E is where 16/32/64 are asked, not this balance.
- No `GREENMIND_POWER_W`. A cap before TPOT is inside 50 ms shrinks the `η` numerator. Cap plus MTP is a measured loss.

`--mamba-cache-mode align` matches `run5/profile.args`. On this image the flag is deprecated and has no effect; caching follows `--enable-prefix-caching`.

Held fixed: Weights and contract flags, `--gpu-memory-utilization 0.90`, `--max-model-len 40960`, card-default power. Run this after A–E, and only while the pre-registered holds (APC on, MTP off, budget 8192) still match the ledger.

## Accuracy

Hold macro-accuracy near `87.8%`. Full `A` starts at `R ≥ 0.98`, about 86.0% macro. The profile does not change weights, does not add a quantization override, and does not enable MTP. A family with at least 20 items under 75% of its baseline applies the class penalty and this balance has failed.

## Energy (`sE`)

Raise SLO-met above the measured 127/300 without a matching rise in joules per request, so `η` stays above `0.00163` and `sE` moves up. `sE` carries exponent 0.6. It saturates at `η = 0.00489` (about 204 J per SLO-met request). Watts stay at the card default, about 400 W. Idle joules in the window still count, so a shorter busy window helps.

## Latency (`sL`) and throughput (`sT`)

TTFT SLO is `0.5 s + 0.25 s` per 1k input tokens. TPOT SLO is 50 ms. Caching is aimed at the TTFT ratio. The 8192 budget is aimed at pulling p95 TPOT down from the measured 82 ms. `sL` is `sqrt(min(1, 1/p95(TTFT/SLO)) · min(1, 50 ms/p95 TPOT))`.

`sT` is the fraction of peak-phase requests that met SLO. The measured best Final was about 0.16. The 8192 budget is the lever for that peak. Exponent 0.2 means `sT` moves `S` less than the same misses move `sE`, and those misses are already missing from `η`.

## How to run

From the repo root. These commands do not request `http://103.153.118.56:8000/v1`.

```bash
export VLLM_IMAGE=vllm/vllm-openai@sha256:cb12c3016938a4ee98ed176ac833984089460689a0982cff4b5a60bb45b3cded
export CONTAINER_NAME=mango-vllm
export PORT=8000
export BIND=0.0.0.0
./lib/flag-check.sh experiments/final-combined/profile.args
./experiments/final-combined/run.sh
./experiments/final-combined/run.sh --check
```

On the GPU VM, after flag-check prints `RESULT: FLAG CHECK PASSED`:

```bash
GREENMIND_CONFIRM_LAUNCH=1 ./experiments/final-combined/run.sh --launch
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
| `final-combined` | 85.5% | 115/300 | ~22655 (197×115) | 2.45 s | 87 ms | | | | 18.6 |
