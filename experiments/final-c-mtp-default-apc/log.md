# final-c-mtp-default-apc — History

**Track matters.** Validation η_base `0.00154` / macro `87.2%`. Final η_base `0.00163` / macro `87.8%`. Do not rank on Validation. Val prompts = first 100 of Final — Val then Final on the same container warms the prefix cache. Watch prefix-cache hit % and MTP acceptance on cold Final.

| **#** | **Track** | **Started** | **Model** | **Score S** | **A** | **R** | **sE** | **sT** | **sL** | **η vs base** | **J/request** | **p95 TTFT** | **p95 TPOT** | **SLO-met** | **Accuracy** |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 23 | **Validation** | 2026-10-24 21:57:13 | mango1.5-awq-w4a16 | **29.6** | 1.00 | 1.025 | 0.25 | 0.34 | 0.44 | 1.31× | 242 | 3.04s | 58 ms | 49/100 | 89.4% |
|  | **Final** (cold) |  | mango1.5-awq-w4a16 |  |  |  |  |  |  |  |  |  |  |  |  |

## Read of #23 (Validation only)

| | C Val #23 | A Val #22 (1536) | run5 cold Val | warm Val |
|---|---:|---:|---:|---:|
| S | **29.6** | 19.9 | **35.6** | 95.6 |
| SLO-met | 49/100 | 47/100 | 57/100 | 98/100 |
| η | 1.31× | 1.15× | 1.41× | 2.78× |
| J/req | 242 | 265 | 264 | 229 |
| p95 TTFT | 3.04 s | 2.81 s | 2.47 s | 0.16 s |
| p95 TPOT | **58 ms** | 62 ms | 55 ms | 18 ms |
| Accuracy | **89.4%** | 86.7% | — | 87.5% |

**Signal:** Best of the post-#11 Validation arms so far (beats A Val). TPOT 58 ms and Acc/R look healthy; joules better than A. Still **below** prior cold Val (35.6 / 57/100). TTFT stretched to 3.04 s. MTP historically collapses at Final peak concurrency / with explicit APC — this Val does **not** prove Final.

**Next:** Relaunch C cold → **Final only**. If Final S ≤ Gate 0 **21.0** or η under baseline / cache hits ~1%, discard C and stay on `final-combined`.
