# final-b-budget-3072 — History

| **#** | **Track** | **Started** | **Model** | **Score S** | **A** | **R** | **sE** | **sT** | **sL** | **η vs base** | **J/request** | **p95 TTFT** | **p95 TPOT** | **SLO-met** | **Accuracy** |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 12 | **Final** | 2026-10-24 21:43:07 | mango1.5-awq-w4a16 | **16.5** | 1.00 | 1.002 | 0.14 | 0.12 | 0.39 | 1.16× | 193 | 2.66s | 87 ms | 110/300 | 88.0% |

## Read of #12 vs Gate 0 Final #11 (budget 2048, S=21.0)

| | B #12 (3072) | Gate 0 #11 (2048) | #9 (8192) |
|---|---:|---:|---:|
| S | **16.5** | **21.0** | 18.6 |
| SLO-met | 110/300 | 120/300 | 115/300 |
| η | 1.16× | 1.24× | 1.19× |
| J/req | 193 | 198 | 197 |
| p95 TTFT | 2.66 s | 2.40 s | 2.45 s |
| p95 TPOT | 87 ms | 88 ms | 87 ms |
| Accuracy | 88.0% | 86.2% | 85.5% |

**Verdict: LOSE.** Larger budget did not cut TPOT (still ~87–88 ms). SLO-met and η fell vs Gate 0; S is below both 2048 and 8192. Accuracy/R are fine (A=1) — not the cliff. **Do not promote 3072.** Keep Gate 0; next arm is C (MTP hail mary) or stay on `final-combined`.
