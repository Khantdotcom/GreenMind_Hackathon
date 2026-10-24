# Post–Gate 0 plan (Stages A → D)

Do **not** change several knobs at once. Measure Stage A first.

| Stage | Change | Decision metric | Folders |
|---|---|---|---|
| **A (now)** | `--max-num-seqs 128` + sweep `--max-num-active-seqs` {64,72,80,88,96} | SLO-met, p95 TTFT, p95 TPOT, S vs 21.0 | [`STAGE_A.md`](STAGE_A.md) |
| **B** | Best A cap + `--max-num-batched-tokens` around 2048–4096 | TTFT/TPOT trade-off | create after A winner |
| **C** | MTP k∈{off,1,2,3}; FlashInfer vs current backend, with best A/B | Incremental S / TPOT / SLO-met | create after B |
| **D** | Disaggregated prefill/decode | Only if ≥2 suitable GPUs | skip on 1×A100 |

## Joint target (unchanged)

- A ≈ 1  
- sE ≥ 0.9 → η ≳ 2.69× η_base (Final η_base 0.00163)  
- p95 TPOT ≤ 50 ms, TTFT compliant  
- ~260/300 SLO-met at similar joules  

## Demoted (do not re-burn alone)

ngram; budgets 1024/1536/3072/8192 without a new admission regime; `--max-num-seqs 64` alone; MTP+explicit APC; MTP default-APC Final #13; power cap while TPOT > 50 ms; FP8 KV on this hybrid A100.

## Note on older folders

`final-d-active-seqs-80` / `final-e-active-seqs-96` / `final-rounded` set active caps **without** `--max-num-seqs 128`. Stage A supersedes them for the decisive probe. Keep Gate 0 (`final-combined`) as the S=21.0 champion until a Stage A Final beats it.
