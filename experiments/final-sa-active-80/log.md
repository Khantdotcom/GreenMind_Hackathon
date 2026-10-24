# final-sa-active-80 — History

**Track matters.** Validation η_base `0.00154` / macro `87.2%`. Final η_base `0.00163` / macro `87.8%`. Val prompts = first 100 of Final — this container is warm; relaunch before Final.

| **#** | **Track** | **Started** | **Model** | **Score S** | **A** | **R** | **sE** | **sT** | **sL** | **η vs base** | **J/request** | **p95 TTFT** | **p95 TPOT** | **SLO-met** | **Accuracy** |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 25 | **Validation** | 2026-10-24 23:09:10 | mango1.5-awq-w4a16 | **27.3** | 1.00 | 1.003 | 0.21 | 0.35 | 0.46 | 1.26× | 263 | 2.63s | 61 ms | 51/100 | 87.5% |
|  | **Final** (cold) |  | mango1.5-awq-w4a16 |  |  |  |  |  |  |  |  |  |  |  |  |

## Read of #25 (Validation only)

| | SA-80 Val #25 | D Val #24 (active 80, no runner 128) | SA-64 Final #14 | Gate 0 Final #11 |
|---|---:|---:|---:|---:|
| S | **27.3** | 29.2 | **0.0** | **21.0** |
| SLO-met | 51/100 | 52/100 | 79/300 | 120/300 |
| p95 TTFT | **2.63 s** | 2.63 s | **7.36 s** | 2.40 s |
| p95 TPOT | 61 ms | 61 ms | 68 ms | 88 ms |
| η | 1.26× | 1.30× | 0.87× | 1.24× |
| Accuracy | 87.5% | 90.8% | 86.1% | 86.2% |

**Signal:** No TTFT cliff on Validation at active **80** (unlike Final #14 at 64). Shape matches prior D Val almost exactly. TPOT still above 50 ms; S below prior cold Val (35.6). Validation never reaches Final’s ~111 running — **not a ranking result**. C’s Val 29.6 became Final 12.7.

**Next:** wait for Final hourly window if needed → **relaunch** → cold Final only on this profile. Promote only if Final S beats Gate 0 **21.0** without η under baseline.
