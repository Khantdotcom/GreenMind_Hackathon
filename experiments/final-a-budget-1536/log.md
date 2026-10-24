# final-a-budget-1536 — History

**Track matters.** Validation η_base `0.00154` / macro `87.2%`. Final η_base `0.00163` / macro `87.8%`. Do not rank arms on Validation. Validation prompts = first 100 of Final — running Val then Final on the same container warms the prefix cache.

| **#** | **Track** | **Started** | **Model** | **Score S** | **A** | **R** | **sE** | **sT** | **sL** | **η vs base** | **J/request** | **p95 TTFT** | **p95 TPOT** | **SLO-met** | **Accuracy** |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 22 | **Validation** | 2026-10-24 21:29:13 | mango1.5-awq-w4a16 | **19.9** | 1.00 | 0.994 | 0.13 | 0.32 | 0.43 | 1.15× | 265 | 2.81s | 62 ms | 47/100 | 86.7% |
|  | **Final** (cold) |  | mango1.5-awq-w4a16 |  |  |  |  |  |  |  |  |  |  |  |  |

## Read of #22 (Validation only)

Vs prior cold Validation on similar APC-on / MTP-off (run5 Val S=35.6, 57/100, TTFT 2.47s, TPOT 55 ms, J 264):

- **Worse S** (19.9 vs 35.6) and **fewer SLO-met** (47 vs 57) at almost the same J/req.
- **TPOT 62 ms** — better than Gate 0 Final #11 (88 ms) but Validation never reaches Final peak concurrency (~111 running); vs run5 Val (55 ms) it is not a win.
- **TTFT 2.81 s** stretched vs run5 Val / Gate 0 Final — matches the “smaller budget hurts prefill” side of the vLLM tradeoff; direction toward the 1024 cliff.

**Verdict from Val alone:** weakly negative for 1536. Still need a **cold Final** to close the arm (or skip A and move to B/C). If #22 already ran on this container, **relaunch** before Final — do not submit Final on the warmed server.
