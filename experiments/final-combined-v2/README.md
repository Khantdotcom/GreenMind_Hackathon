# Final combined v2 — ITL-first toward sE / sT / sL ≈ 0.7–0.9

## Goal

Push Final `sE`, `sT`, and `sL` from ~0.15–0.39 toward **0.7–0.9**.

| Factor | Today (best / final-combined) | ≈0.7 needs | ≈0.9 needs |
|---|---|---|---|
| `sE` | 0.15–0.16 (1.18–1.19× η) | ~2.16× η → **~210–230 SLO-met** at ~60 kJ | ~2.69× → **~260–290** |
| `sT` | 0.15–0.16 | ~70% of peak requests SLO-met | ~90% |
| `sL` | 0.39–0.50 | p95 TPOT ≲ 55–60 ms **and** TTFT/SLO not ≫ 1 | p95 TPOT ≤ 50 ms, TTFT near SLO |

`A` is already ~0.97–1.00. The cliff is **p95 TPOT 82–87 ms at ~111 running** on the 4 req/s peak.

## Hypothesis

Larger scheduler budgets made TPOT worse (`8192` → S=18.6 vs best Final at default ~2048). vLLM’s chunked-prefill guidance: **smaller `max_num_batched_tokens` → better ITL/TPOT** because decode is prioritized and prefills cannot monopolize a step. This profile:

- sets the budget to **1024** (ITL-first vs measured 82–87 ms),
- raises `--gpu-memory-utilization` to **0.95** for KV at peak concurrency,
- keeps APC on, MTP **off**, **no** `--max-num-seqs` (64 already lost the energy cliff), no power cap.

## Knobs

- `--max-num-batched-tokens 1024` + `--enable-chunked-prefill` — shorten mixed steps (TPOT / `sL` / `sT`).
- `--gpu-memory-utilization 0.95` — more KV, fewer preemptions at ~111 running.
- `--enable-prefix-caching` + `--mamba-cache-mode align` — TTFT / joules.
- No `--speculative-config` — MTP + explicit APC collapsed hits (~1%) and Final η under baseline.
- No `--max-num-seqs` — cap 64 moved failures to TTFT (p95 6.54 s) and η 0.94× → `S=0`.
- No `GREENMIND_POWER_W` — only after p95 TPOT has headroom under 50 ms.

Held fixed: weights, served name, `--max-model-len 40960`, parsers, card-default power (~400 W).

## Accuracy

Hold macro near `87.8%`. Full `A` at `R ≥ 0.98` (~86.0% macro). `final-combined` landed 85.5% / A 0.97 — soft, not the cliff.

## Energy / latency / throughput

`η = SLO-met / GPU joules` (J/request on the grader is joules/300). Exponent 0.6 on `sE`. Idle watts in the window still count, so finishing earlier helps.

If this Final still shows p95 TPOT ≥ ~70 ms and SLO-met ≲ 150, the next untested breakthrough is MTP k=1 **without** explicit `--enable-prefix-caching` (image-default APC only — ANALYSIS hypothesis; cliff risk if hits collapse). Do not re-try cap 64 or budget 8192 for score.

## How to run

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

## Prior Final rows

| run_id | S | sE | sT | sL | η | p95 TPOT | SLO-met |
|---|---:|---:|---:|---:|---:|---:|---:|
| best Final (~2048, uncapped) | 19.1 | 0.15 | 0.16 | 0.50 | 1.18× | 82 ms | 127/300 |
| `final-combined` (8192 / 0.90) | 18.6 | 0.16 | 0.15 | 0.39 | 1.19× | 87 ms | 115/300 |

## Blank measurement row

| run_id | macro | SLO-met | joules | p95 TTFT | p95 TPOT | prefix hits | MTP accept | preemptions | S | sE | sT | sL |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `final-combined-v2` | | | | | | | | | | | | |
