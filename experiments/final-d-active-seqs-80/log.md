# final-d-active-seqs-80 — History

**Track matters.** Validation η_base `0.00154` / macro `87.2%`. Final η_base `0.00163` / macro `87.8%`. This row is Validation. Val prompts are the first 100 of Final, so this container is warm — relaunch before any Final.

| **#** | **Track** | **Started** | **Model** | **Score S** | **A** | **R** | **sE** | **sT** | **sL** | **η vs base** | **J/request** | **p95 TTFT** | **p95 TPOT** | **SLO-met** | **Accuracy** |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 24 | **Validation** | 2026-10-24 22:27:46 | mango1.5-awq-w4a16 | **29.2** | 1.00 | 1.041 | 0.24 | 0.35 | 0.46 | 1.30× | 261 | 2.63s | 61 ms | 52/100 | 90.8% |
|  | **Final** (cold) |  | mango1.5-awq-w4a16 |  |  |  |  |  |  |  |  |  |  |  |  |

## Read of #24 (Validation only)

| | D Val #24 | C Val #23 | A Val #22 | run5 cold Val |
|---|---:|---:|---:|---:|
| S | **29.2** | 29.6 | 19.9 | **35.6** |
| SLO-met | 52/100 | 49/100 | 47/100 | 57/100 |
| η | 1.30× | 1.31× | 1.15× | 1.41× |
| J/req | 261 | 242 | 265 | 264 |
| p95 TTFT | **2.63 s** | 3.04 s | 2.81 s | 2.47 s |
| p95 TPOT | 61 ms | 58 ms | 62 ms | 55 ms |
| Accuracy | **90.8%** | 89.4% | 86.7% | — |

**Signal:** Accuracy and TTFT look healthy (cap 80 did not reproduce the `--max-num-seqs 64` TTFT cliff on this lighter track). S is tied with C’s Validation and still under the best prior cold Validation (35.6). p95 TPOT is still over 50 ms. Validation never reaches Final’s ~111 running, and C’s strong Val became Final S=12.7. **Not a ranking result.**

**Next:** relaunch, then cold Final only. Promote only if Final S beats Gate 0 **21.0**.
