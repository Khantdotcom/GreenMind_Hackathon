# Final combined — high-S base (speculation off)

Single-arm folder. **Target:** push `R`, `sE`, `sT`, `sL` toward 1. **Honesty:** the only measured `S ≥ 90` was a **warm Validation** (95.6). Best **cold Final** is now **21.0** (History #11, Gate 0). No cold config in-repo has cleared Final `S ≥ 90`.

## Current profile (Gate 0 — measured #11)

| Knob | Value | Why |
|---|---|---|
| `--max-num-batched-tokens` | **2048** | Best Final so far (#11 S=21.0); 8192→18.6; 1024→S=0 |
| `--gpu-memory-utilization` | **0.95** | KV headroom at peak |
| Prefix caching | **on** | Shared-prefix RAG / TTFT (APC does not cut decode TPOT) |
| Speculation | **off** | Ngram Validation: S=4.5; high-QPS Final hurts per vLLM + our logs |
| MTP | **off** | MTP+explicit APC → ~1% hits, Final S=0 |
| `--max-num-seqs` | unset | Cap 64 → Final S=0 (TTFT cliff) |
| Power | card default | Cap only after TPOT &lt; 50 ms |

## Score math for S ≥ 90

`S = 100 · A · sE^0.6 · sT^0.2 · sL^0.2`. With `A ≈ 1`, you need roughly `sE,sT,sL ≳ 0.9` together — i.e. **η ≳ 2.7×**, **peak SLO-met ≳ 90%**, **p95 TPOT ≤ ~50 ms**, TTFT inside SLO. At ~198 J/req that is ~**260/300** SLO-met (#11 has 120).

| Track | Best measured | What it was |
|---|---:|---|
| Validation (warm) | **95.6** | Same APC-on / MTP-off server after prompts already in cache |
| Validation (cold + ngram) | **4.5** | 36/100, η 1.02×, TPOT 82 ms — **do not keep ngram** |
| Final (best) | **21.0** | Gate 0 #11: 120/300, TPOT 88 ms, η 1.24×, J 198 |

**Graded track is Final.** Validation `S ≥ 90` does not mean Final `S ≥ 90`. Warming Final with Validation is not a fair config win (Validation prompts = first 100 of Final).

## How to run

```bash
export VLLM_IMAGE=vllm/vllm-openai@sha256:cb12c3016938a4ee98ed176ac833984089460689a0982cff4b5a60bb45b3cded
export CONTAINER_NAME=mango-vllm
export PORT=8000
export BIND=0.0.0.0
unset GREENMIND_POWER_W
./experiments/final-combined/run.sh --check
GREENMIND_CONFIRM_LAUNCH=1 ./experiments/final-combined/run.sh --launch
```

Prefer **cold Final** for ranking. Paste History before the next edit.

## Next levers (implemented as separate folders)

| Letter | Directory | Change |
|---|---|---|
| **A** | [`../final-a-budget-1536`](../final-a-budget-1536/README.md) | budget **1536** |
| **B** | [`../final-b-budget-3072`](../final-b-budget-3072/README.md) | budget **3072** |
| **C** | [`../final-c-mtp-default-apc`](../final-c-mtp-default-apc/README.md) | MTP k=1, omit explicit APC. Final #13 **S=12.7 lose** |
| **D** | [`../final-d-active-seqs-80`](../final-d-active-seqs-80/README.md) | `--max-num-active-seqs 80` (next) |
| **E** | [`../final-e-active-seqs-96`](../final-e-active-seqs-96/README.md) | `--max-num-active-seqs 96` if D queues TTFT |

Do not re-burn: `--max-num-seqs 64`, ngram, budgets 1024/1536/3072/8192, MTP (explicit APC or default-APC Final). Power cap only if p95 TPOT is already under 50 ms. FP8 KV is a poor fit on this hybrid A100 model.
