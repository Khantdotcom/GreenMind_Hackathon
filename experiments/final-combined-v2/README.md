# Final combined v2 — 4096 budget + 0.92 GPU mem

## Hypothesis

Measured `final-combined` (budget **8192**, mem **0.90**, uncapped, APC on, MTP off) scored **S=18.6** on Final: 115/300 SLO-met, p95 TTFT 2.45 s, p95 TPOT **87 ms**, η 1.19×, A 0.97 (History #9). That is slightly **worse** than the best Final (`S=19.1`, 127/300, p95 TPOT 82 ms) on the default ~2048 budget.

Approach 6: larger token budgets help prefill throughput; **smaller** budgets protect decode TPOT. 8192 moved the wrong way (TPOT 82→87, SLO-met 127→115). This profile keeps the cliff-clearing shape (APC on, MTP off, **no** `--max-num-seqs`, no power cap) but:

- drops the scheduler budget to **4096** (midpoint between the best-known default and the failed 8192), and
- raises `--gpu-memory-utilization` to **0.92** (Approach 8) for more KV at the ~111-running peak so preemptions/recompute hurt less.

## Knobs

- `--enable-prefix-caching` and `--mamba-cache-mode align` (TTFT / `sE`).
- `--max-num-batched-tokens 4096` and `--enable-chunked-prefill` (TPOT side of `sL` / `sT` vs 8192).
- `--gpu-memory-utilization 0.92` (KV capacity at peak).
- No `--speculative-config`. MTP with caching collapsed hits.
- No `--max-num-seqs`. Cap 64 lost the energy cliff.
- No `GREENMIND_POWER_W`. Cap only after p95 TPOT is under 50 ms.

`--mamba-cache-mode align` matches `run5/profile.args`. On this image the flag is deprecated and has no effect; caching follows `--enable-prefix-caching`.

Held fixed: Weights and contract parsers, `--max-model-len 40960`, card-default power. Do not add FLASHINFER or MTP here.

## Accuracy

Hold macro near `87.8%`. Full `A` needs `R ≥ 0.98` (~86.0% macro). `final-combined` landed at 85.5% / A 0.97 — soft, not the cliff. This profile does not change weights or enable MTP.

## Energy (`sE`)

Raise SLO-met above 115–127 without matching joules growth. `sE` has exponent 0.6 and saturates at `η = 0.00489`. Watts stay at card default (~400 W).

## Latency (`sL`) and throughput (`sT`)

Binding miss on both measured Finals: p95 TPOT **82–87 ms** vs SLO **50 ms**. Peak `sT` stayed ~0.15–0.16. 4096 aims to shorten mixed steps vs 8192 so more decode tokens stay under 50 ms at 4 req/s.

## How to run

From the repo root. These commands do not request `http://103.153.118.56:8000/v1`.

```bash
export VLLM_IMAGE=vllm/vllm-openai@sha256:cb12c3016938a4ee98ed176ac833984089460689a0982cff4b5a60bb45b3cded
export CONTAINER_NAME=mango-vllm
export PORT=8000
export BIND=0.0.0.0
unset GREENMIND_POWER_W
./experiments/final-combined-v2/run.sh --check
GREENMIND_CONFIRM_LAUNCH=1 ./experiments/final-combined-v2/run.sh --launch
```

Wait for local `/v1/models` and chat PASS. Submit **Final** only (no Validation warm). Paste History into `experiments/ledger.template.csv`.

Container name `mango-vllm`, bind `0.0.0.0:8000`, image digest above, Hugging Face cache mount `$HOME/.cache/huggingface:/root/.cache/huggingface`, and labels match `docs/ops/docker-defaults.md`. Served name `mango1.5-awq-w4a16`. Weights `CMKL/MANGO1.5-Qwen3.5-9B-AWQ-W4A16-mtp`.

If this Final does not beat `S=19.1` / 127 SLO-met, fall back to cold `run6-bestsofar` (default budget, mem 0.90) rather than raising the budget again.

## Score context

`S = 100 · A · sE^0.6 · sT^0.2 · sL^0.2` on the Final track.
`η_base = 0.00163`, `K = 3`, full energy at `η = 0.00489`.
Reference macro-accuracy `87.8%`. Full accuracy gate at `R ≥ 0.98` (macro about `86.0%`).
TTFT SLO is `0.5 s + 0.25 s` per 1k input tokens. TPOT SLO is `50 ms`.
This README does not claim an `S`.

## Prior Final row (do not treat as this profile)

| run_id | S | A | R | sE | sT | sL | η | J/req | p95 TTFT | p95 TPOT | SLO-met | macro |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| `final-combined` (8192 / 0.90) | 18.6 | 0.97 | 0.974 | 0.16 | 0.15 | 0.39 | 1.19× | 197 | 2.45 s | 87 ms | 115/300 | 85.5% |

## Blank measurement row

| run_id | macro | SLO-met | joules | p95 TTFT | p95 TPOT | prefix hits | MTP accept | preemptions | S |
|---|---|---|---|---|---|---|---|---|---|
| `final-combined-v2` | | | | | | | | | |
