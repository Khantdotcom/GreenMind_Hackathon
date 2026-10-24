# Hackathon Evaluation Test — Scoring Criteria

## 1. Overview

The hackathon ranks submissions with one technical score:

```
S = 100 · A · s_E^0.6 · s_T^0.2 · s_L^0.2
```

- `S` — technical score.
- `A` — accuracy factor, from 0.05 to 1.
- `s_E` — energy score.
- `s_T` — throughput score.
- `s_L` — latency score.

The factors multiply. Energy has the largest exponent. Throughput and latency saturate at 1.

## 2. Evaluation tracks

| Track | Requests | Purpose | Counts toward the graded result? |
|---|---:|---|---|
| Validation | 100 | Practice track. Checks that the server works. The score is indicative only. | No |
| Final Test | 300 | The graded evaluation round. | **Yes. Only the Final counts.** |

**Validation does not predict the Final.** The Final's longer 4 requests/s peak builds far more concurrency. run6 scored 95.6 on Validation (peak 35 running, p95 TPOT 18 ms, 98/100 SLO-met) and 19.1 on Final (peak 111 running, p95 TPOT 82 ms, 127/300 SLO-met). Use Validation to confirm a server answers correctly, and rank configurations on Final results or a Final-shaped replay.

- Each round is capped at 30 minutes.
- Requests unfinished at the cap count as failed.
- Validation allows 5 finished submissions per hour. Final allows 2 per hour.
- Final grader submissions close on 25 October 2026 at 11:00.

## 3. Baseline and energy target

The baseline is the untuned model served with default vLLM in BF16.

**The two tracks use different baselines.** Both are shown on the live grader page (confirmed 2026-10-24). Never mix them.

| Parameter | Validation (practice) | **Final (graded)** |
|---|---|---|
| Baseline energy efficiency (`η_base`) | `0.00154` SLO-met requests/J | **`0.00163` SLO-met requests/J** |
| Energy multiplier for full marks (`K`) | `3×` | `3×` |
| Full energy marks | `η ≥ 0.00462` (about 216 J per SLO-met request) | **`η ≥ 0.00489` (about 204 J per SLO-met request)** |
| Reference macro-accuracy | `87.2%` | **`87.8%`** |
| Full `A` (`R ≥ 0.98`) needs macro-accuracy of | about 85.5% | **about 86.0%** |

The Final baseline is about 6% harder on energy and slightly harder on accuracy. The same server at the same efficiency gets a lower `s_E` on Final: 1.38× on Validation is only about 1.30× on Final.

Grader wording for the columns, identical on both pages:

- **Score S**: `100 · A · sE^0.6 · sT^0.2 · sL^0.2`. Ties: higher retention R, then lower p95 TTFT.
- **A (accuracy gate)**: `R = macro-accuracy ÷ the baseline's macro-accuracy`; `A = smoothstep((R − 0.85) ÷ 0.13)`: 1 at R ≥ 0.98, fading smoothly below it, floor 0.05. A task family (≥ 20 items) keeping under 75% of the baseline's accuracy multiplies A by a smooth penalty (full at 75%, minimum at 50%).
- **sE (energy)**: `η = SLO-met requests ÷ GPU joules over the timed window`; `sE = clip(ln(η ÷ ηbase) ÷ ln K, 0, 1)`. A request counts only if it streamed, finished (not truncated), TTFT ≤ 0.5 s + 0.25 s per 1k input tokens and TPOT ≤ 50 ms.
- **sT (throughput)**: share of peak-phase requests that met their SLO.
- **sL (latency)**: `√(min(1, 1 ÷ p95 TTFT/SLO) · min(1, 50 ms ÷ p95 TPOT))`.
- **Energy**: GPU board energy from the NVML total-energy counter (CPU/DRAM RAPL and BMC/PDU are not readable on these VMs).

Energy efficiency:

```
η = SLO-met requests / GPU energy in joules
```

- Energy is GPU board energy from the NVML total-energy counter over the timed window. The grader page says CPU/DRAM (RAPL) and BMC/PDU energy are not readable on these VMs, so only GPU board joules count.
- Idle energy inside the window is included.
- Full energy marks are `3×` baseline efficiency.

```
Final:      s_E = clip( ln(η / 0.00163) / ln 3 , 0, 1 )
Validation: s_E = clip( ln(η / 0.00154) / ln 3 , 0, 1 )
```

The ratio table below applies to either track, as a multiple of that track's own baseline.

| Efficiency relative to baseline | Energy score (`s_E`) |
|---|---:|
| `1.00×` | `0.00` |
| `1.25×` | `0.20` |
| `1.50×` | `0.37` |
| `2.00×` | `0.63` |
| `2.50×` | `0.83` |
| `3.00×` or higher | `1.00` |

The untuned baseline scores `S = 0` because `s_E = 0` at `η = η_base`.

## 4. What counts as SLO-met

A request counts only when all five conditions pass:

1. The response is streamed, so TTFT can be observed.
2. There is no error or timeout. The timeout is 900 seconds.
3. The response is not cut off at 8,192 output tokens.
4. TTFT is within `0.5 + 0.25 × prompt_tokens / 1000` seconds.
5. TPOT is at most 50 ms. This condition is skipped for one-token answers.

Examples: 300 prompt tokens → 0.575 s TTFT; 6,000 → 2.0 s; 20,000 → 5.5 s.

Failed, late, and cut-off requests still add joules and add nothing to the numerator. Work still running at 30 minutes fails.

## 5. Accuracy factor (`A`)

```
R = your macro-accuracy / 0.878     (Final)
R = your macro-accuracy / 0.872     (Validation)
x = clip( (R - 0.85) / 0.13 , 0, 1 )
smoothstep(x) = 3x^2 - 2x^3
A = max( 0.05, smoothstep(x) × c_f )
```

`c_f` is the weakest-class factor:

```
c = weakest class accuracy / baseline accuracy for that class
c_f = smoothstep( clip( (c - 0.50) / 0.25 , 0, 1 ) )
```

The grader's History page words the class rule as: a **task family** with at least 20 items that keeps under 75% of the baseline's accuracy multiplies `A` by a smooth penalty, full at 75% and minimum at 50%. Task ids in Validation output carry family names such as `security`, `instruction`, `thai`, `longctx`, `math`, `sql_result`, and agentic `ag…` families. A family may be finer than the six workload classes in the briefing.

Ties are broken by higher retention `R`, then lower p95 TTFT.

- `R ≥ 0.98` gives `A = 1` before a class penalty. That is macro-accuracy of about `86.0%` on Final (`0.98 × 87.8%`) and about `85.5%` on Validation (`0.98 × 87.2%`).
- `R ≤ 0.85` reaches the floor `A = 0.05`. The factor is never exactly 0 from the retention curve alone.
- A class with at least 20 questions and retention under 75% of its own baseline applies `c_f`. The class factor is 1 at 75% retention and 0 at 50% retention.
- Beating the reference macro-accuracy does not add points.

One briefing ambiguity remains: the accuracy floor is 0.05, while the class factor is described as reaching 0 at 50% class retention. Confirm how those two combine, and how classes with fewer than 20 questions are treated, if a run is close to either edge.

## 6. Throughput score (`s_T`)

```
s_T = peak-phase requests that passed SLO / peak-phase requests that arrived
```

- Only the constant 4 requests/second peak phase counts.
- Late, failed, and cut-off requests count as not served.
- `s_T` saturates at 1 when every peak request passes SLO.
- The exponent is 0.2, so a mediocre peak pass rate moves `S` less than the same misses move `s_E`. Those misses are also missing from `η`.

## 7. Latency score (`s_L`)

```
s_L,TTFT = min( 1, 1 / p95(TTFT / TTFT_SLO) )
s_L,TPOT = min( 1, 50 ms / p95(TPOT) )
s_L = sqrt( s_L,TTFT × s_L,TPOT )
```

- TTFT is divided by each request's own TTFT SLO before the percentile.
- TPOT target is 50 ms.
- `s_L` saturates at 1 once both tails are inside target. Further speed still helps energy and SLO-met count.

## 8. How to read a score

```
S = 100 · A · s_E^0.6 · s_T^0.2 · s_L^0.2
```

1. Energy carries exponent 0.6. Rescuing a failed request raises `η` and can raise `s_T` or `s_L`.
2. Accuracy multiplies the whole score. Full credit starts at 98% retention.
3. Throughput and latency saturate at 1.
4. Idle joules count, so a shorter busy window matters, not a lower watt reading by itself.
5. A power cap that pushes TPOT over 50 ms shrinks the numerator of `η`. Cap power only after SLO-met is already high.

## 9. Measured results

| Run | Track | Baseline used | `S` | SLO-met | η vs that baseline | p95 TTFT | p95 TPOT | Peak running |
|---|---|---|---:|---:|---:|---:|---:|---:|
| run4 full | Final | 0.00163 | 0.0 | 93/300 | 0.92× | 3.59 s | 91 ms | n/a |
| run4 full | Validation | 0.00154 | 32.8 | 50/100 | 1.38× | 3.12 s | 55 ms | n/a |
| run5 | Validation | 0.00154 | 35.6 | 57/100 | 1.41× | 2.47 s | 55 ms | 66 |
| run6 | Validation | 0.00154 | 95.6 | 98/100 | 2.78× | 0.16 s | 18 ms | 35 |
| run6 | **Final** | **0.00163** | **19.1** | 127/300 | 1.18× | 2.16 s | 82 ms | 111 |

run6 shows why only the Final can rank configurations. Details: `run6/ANALYSIS.md`.

### Earliest Validation (V0)

Indicative Validation of the defaults in `scripts/start-vllm.sh` (AWQ W4A16 checkpoint, speculative decoding off, `max_model_len` 32768, GPU memory utilization 0.85):

| Field | Value |
|---|---|
| `S` | 34.8 |
| SLO-met | 56/100 |
| `A`, `s_E`, `s_T`, `s_L`, joules, p95 TTFT, p95 TPOT | Not yet copied from grader History |

If `A`, `s_T`, and `s_L` were all 1, then `s_E ≈ 0.17` and efficiency would be only about `1.2×` baseline. If accuracy or latency is worse than that, energy is better than `1.2×` and the score is being spent on those factors. Either way, V0 used at most about 30 kJ for 100 requests (56 SLO-met at about 1.21 × `η_base`). Full energy marks on 100 SLO-met requests need about 21.6 kJ or less. Copy the History row before the next flag change. The ledger is `experiments/log.md`.

The E1 Validation (2026-10-24 07:56:39 UTC, V0 plus `--max-model-len 40960`) shows the three final `math` requests running 72–82 s, against at most about 30 s for every other visible request. They are likely 8192-token cutoffs, which fail SLO and accuracy and lengthen the energy window. Details: `experiments/results/2026-10-24T075639Z-validation.md`.

## 10. Still unresolved

- How the 0.05 accuracy floor combines with the family penalty. The History page calls 50% retention the penalty's "minimum", not zero.
- Whether "task family" means the six briefing classes or the finer task-id families, and how families under 20 items affect `c_f`.
- Whether a page header changes again. Check the baseline line at the top of each History page before recording a row.

The image digest of `vllm/vllm-openai:nightly` for the 34.8 run was not recorded. Record it on the VM before comparing later runs.
