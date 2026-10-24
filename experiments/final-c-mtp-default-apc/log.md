# final-c-mtp-default-apc — History

**Track matters.** Validation η_base `0.00154` / macro `87.2%`. Final η_base `0.00163` / macro `87.8%`.

| **#** | **Track** | **Started** | **Model** | **Score S** | **A** | **R** | **sE** | **sT** | **sL** | **η vs base** | **J/request** | **p95 TTFT** | **p95 TPOT** | **SLO-met** | **Accuracy** |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 13 | **Final** | 2026-10-24 22:07:04 | mango1.5-awq-w4a16 | **12.7** | 0.93 | 0.979 | 0.16 | 0.04 | 0.29 | 1.19× | 165 | 3.89s | 94 ms | 96/300 | 85.9% |
| 23 | **Validation** | 2026-10-24 21:57:13 | mango1.5-awq-w4a16 | **29.6** | 1.00 | 1.025 | 0.25 | 0.34 | 0.44 | 1.31× | 242 | 3.04s | 58 ms | 49/100 | 89.4% |

## Verdict: LOSE on Final

| | C Final #13 | Gate 0 Final #11 |
|---|---:|---:|
| S | **12.7** | **21.0** |
| SLO-met | 96/300 | 120/300 |
| η | 1.19× | 1.24× |
| p95 TTFT | 3.89 s | 2.40 s |
| p95 TPOT | **94 ms** | 88 ms |
| Accuracy | 85.9% (A 0.93) | 86.2% (A 1.00) |

Val #23 did not hold. Peak TPOT got worse, TTFT stretched, sT collapsed to 0.04, and accuracy slipped under the A=1 line. **Do not promote MTP.** Stay on Gate 0 (`final-combined`, S=21.0).
