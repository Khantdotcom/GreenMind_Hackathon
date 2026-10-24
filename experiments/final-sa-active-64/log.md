# final-sa-active-64 — History

| **#** | **Track** | **Started** | **Model** | **Score S** | **A** | **R** | **sE** | **sT** | **sL** | **η vs base** | **J/request** | **p95 TTFT** | **p95 TPOT** | **SLO-met** | **Accuracy** |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 14 | **Final** | 2026-10-24 22:56:05 | mango1.5-awq-w4a16 | **0.0** | 0.98 | 0.981 | 0.00 | 0.02 | 0.24 | **0.87×** | 186 | **7.36s** | 68 ms | 79/300 | 86.1% |

## Verdict: LOSE — TTFT cliff (same failure shape as `--max-num-seqs 64` alone)

| | SA-64 #14 | Gate 0 #11 | old `max-num-seqs 64` |
|---|---:|---:|---:|
| S | **0.0** | **21.0** | 0.0 |
| η | **0.87×** | 1.24× | 0.94× |
| SLO-met | 79/300 | 120/300 | 87/300 |
| p95 TPOT | **68 ms** | 88 ms | 67 ms |
| p95 TTFT | **7.36 s** | 2.40 s | 6.54 s |

TPOT moved the right way (88 → 68 ms) but stayed above 50 ms. Admission **64** queued so hard that TTFT blew out → η under baseline → **sE = 0 → S = 0**. Preserving runner capacity at 128 did **not** prevent the queue cliff at active=64.

**Next:** raise active (do not retry 64). Prefer **`final-sa-active-80`** after the hourly Final window resets (72 may still be too tight). If 80 still cliffs TTFT, go 88 → 96. If none beat Gate 0, stop Stage A before MTP.
