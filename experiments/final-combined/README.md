# Final combined — high-S base (speculation off)

Single-arm folder. **Target:** push `R`, `sE`, `sT`, `sL` toward 1. **Honesty:** the only measured `S ≥ 90` was a **warm Validation** (95.6). Best **Final** is still **19.1**. No cold config in-repo has cleared Final `S ≥ 90`.

## Current profile (after ngram Validation failure)

| Knob | Value | Why |
|---|---|---|
| `--max-num-batched-tokens` | **2048** | Best Final shape; 8192→18.6; 1024→S=0 |
| `--gpu-memory-utilization` | **0.95** | KV headroom at peak |
| Prefix caching | **on** | Shared-prefix RAG / TTFT |
| Speculation | **off** | Ngram Validation: S=4.5, 36/100, TPOT 82 ms |
| MTP | **off** | MTP+explicit APC → ~1% hits, Final S=0 |
| `--max-num-seqs` | unset | Cap 64 → Final S=0 |
| Power | card default | Cap only after TPOT &lt; 50 ms |

## Score math for S ≥ 90

`S = 100 · A · sE^0.6 · sT^0.2 · sL^0.2`. With `A ≈ 1`, you need roughly `sE,sT,sL ≳ 0.9` together — i.e. **η ≳ 2.7×**, **peak SLO-met ≳ 90%**, **p95 TPOT ≤ ~50 ms**, TTFT inside SLO.

| Track | Best measured | What it was |
|---|---:|---|
| Validation (warm) | **95.6** | Same APC-on / MTP-off server after prompts already in cache |
| Validation (cold + ngram) | **4.5** | 36/100, η 1.02×, TPOT 82 ms — **do not keep ngram** |
| Final (best) | **19.1** | 127/300, TPOT 82 ms, η 1.18× |

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

## Next levers toward S ≥ 90 (still this folder; need approval)

1. **Budget only** `{1536, 3072}` after measuring this base on **Final**.
2. **MTP k=1 with image-default APC only** (omit `--enable-prefix-caching`) — high upside, high cliff risk.
3. **Power cap** only if p95 TPOT is already under 50 ms.
