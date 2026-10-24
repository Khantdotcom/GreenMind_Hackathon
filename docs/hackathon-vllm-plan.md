# GreenMind vLLM plan — Final score first

Source machine: `/home/khahtay/Documents/greenmind/GreenMind_Hackathon` (Team 17, `gm17`).  
Synced for Project repo: `Khantdotcom/GreenMind_Hackathon`.  
Evidence cutoff: local repo state 2026-10-24 evening. **Only measured numbers below; blank grader cells stay blank.**

---

## 1. Digested scoring + hackathon requirements

### Score (Round 1)

```
S = 100 · A · s_E^0.6 · s_T^0.2 · s_L^0.2
```

| Factor | Role | Final-track constants |
|---|---|---|
| `A` | Accuracy gate (multiplies everything) | `R = macro-acc / 0.878`; full `A` at `R ≥ 0.98` (~86.0% macro). Floor 0.05. Weak task family (≥20 items, &lt;75% of family baseline) adds a smooth class penalty. |
| `s_E` | Energy (exponent **0.6**) | `η = SLO-met / GPU joules`; `s_E = clip(ln(η / 0.00163) / ln 3, 0, 1)`. Full marks at **3×** baseline ≈ **0.00489** req/J (~204 J per SLO-met). |
| `s_T` | Peak throughput | Fraction of **4 req/s peak-phase** requests that met SLO. Caps at 1. |
| `s_L` | Latency tails | `√(min(1, 1/p95(TTFT/SLO)) · min(1, 50ms/p95 TPOT))`. Caps at 1. |

**Only the Final counts** (300 requests, 2 submissions/hour). Validation (100 requests, 5/hour) is practice and **does not predict Final** — same server scored Validation `95.6` then Final `19.1`. Submissions close **25 Oct 2026 11:00**. Top 8 by Final `S` pitch (Round 2 = 60% of standings).

### Final baseline (graded) vs Validation (practice)

| | Validation | **Final** |
|---|---:|---:|
| `η_base` | 0.00154 | **0.00163** |
| Reference macro-accuracy | 87.2% | **87.8%** |
| Full energy marks (3×) | ~216 J / SLO-met | **~204 J / SLO-met** |

Untuned BF16 default `vllm serve` scores `S = 0` by construction (`s_E = 0` at `η = η_base`).

### SLO-met (numerator of η)

Streamed; no error/timeout (900 s); not truncated at 8192 out tokens; TTFT ≤ `0.5 + 0.25×prompt_k`; TPOT ≤ 50 ms (skip 1-token). Misses still burn joules. Idle GPU energy in the window counts. Cap 30 minutes.

### Workload shape (design target)

Open-loop: ramp → **4 req/s peak** → quiet 1 req/s. Thinking on, `max_tokens=8192`, `temperature=0`, tool_choice auto. Classes: chat 90, RAG 60, agentic 60, math/code 45, Thai 30, longctx (to 32K) 15. Hybrid Mamba/GDN model: only ~8/32 layers use conventional KV.

### Hardware / contract

1× A100-SXM4 40 GB, OpenAI `/v1/chat/completions` streaming + tool calling (`--enable-auto-tool-choice --tool-call-parser qwen3_coder`). Open source only. No response caching of graded requests; normal KV/prefix caching OK. Fixed power/clocks OK if constant for the whole run.

---

## 2. What the model already brings

**Checkpoint:** `CMKL/MANGO1.5-Qwen3.5-9B-AWQ-W4A16-mtp` (~8.1 GB).

| Built-in | Effect on S |
|---|---|
| **AWQ W4A16** (Marlin on Ampere) | Weight-only INT4 vs BF16 baseline → large energy/throughput headroom for free on A100 memory-bound decode. Accuracy on graded Finals stayed near the reference (`A` 0.98–1.00; macro 85.6–88.4%). Treat as **adopted**, not a next experiment. |
| **MTP draft head** (BF16, spliced, unquantized) | Self-speculative decoding when `--speculative-config method=mtp`. Model card smoke: 64–76% acceptance. On our run4 full server: **91.5%** draft acceptance (~1.9 tokens/step) — but Final still `S=0` because prefix-cache hits collapsed and η fell below baseline. |

**Tradeoff:** Quantization protects `A` while cutting joules; MTP can raise tokens/step (`s_T`/`s_L`/`s_E`) **only if** it does not destroy prefix caching or accuracy. On this image + hybrid model, MTP + explicit prefix caching measured **~1%** cache hits and lost the Final energy cliff.

---

## 3. Top 3 techniques to improve `S` (ranked)

### 1) Automatic prefix caching — keep it on, do not break it with MTP

**Why vs factors:** Cuts real prefill work → fewer joules per request (`s_E`), lower TTFT (`s_L`), more peak SLO-met (`s_T`). Idle joules still count, so finishing the window sooner also helps η.

**Evidence:**

- Best Final so far: **`S=19.1`**, 127/300, 1.18× Final baseline, p95 TTFT 2.16 s, p95 TPOT 82 ms, 221 J/req, **44%** prefix hits — run5 container after two Validations (`run6/log.md`, `run6/ANALYSIS.md`). Note: `./run6/start.sh` never launched; flag-check failed and the run5 server stayed up.
- Warm Validation on that cache: **`S=95.6`**, 98/100, 87% hits, p95 TPOT 18 ms — same container, second pass over Validation prompts that are the **first 100 of the Final**.
- Cold-ish Validation with explicit `--enable-prefix-caching --mamba-cache-mode align` but MTP off: `S=35.6`, 57/100, **15%** hits (`run5/log.md`).
- MTP + caching (run4 full / final-run2): hits **~1%**, Final `S=0`.

**Action:** Leave image-default caching (or the measured run5 explicit flags) with **MTP off**. Do not run Validation-before-Final on the graded container unless organizers confirm it is allowed (cache warm-start of the first 100).

### 2) Larger scheduler token budget (`--max-num-batched-tokens 8192`) / fewer mixed prefill+decode steps

**Why vs factors:** Peak concurrency (~111 running on the 19.1 Final) mixes long prefills into decode steps. Mixed steps inflate average TPOT above 50 ms → peak SLO fails (`s_T`↓, η numerator↓ → `s_E`↓) and TTFT/TPOT tails hurt `s_L`. A larger step budget clears prefill in fewer steps so more steps stay fast decode-only.

**Evidence:**

- final-run1 engine notes (cap 64): prefill 5–8k prompt tok/s while generate 620–1,660 tok/s → **38–100 ms/token** in mixed regime; pure decode **9–12 ms** at 8–15 running (`CYCLE_PLAN.md`, `final-run3/README.md`).
- A100 default budget in this image: **2048** (`run4/log.md` startup warning).
- **final-run3** = this change alone on the uncapped, MTP-off base. Console shows a full 300-request Final completed (`final-run3/log.md` through `[300/300]`), but the **grader History score row was never copied** — `S` / SLO-met / η for that Final are **unknown** in-repo.

**Action:** Pin image digest, relaunch `final-run3`, submit Final cold, **immediately paste History** into `final-run3/log.md`. Compare to 127/300 / 2.16 s / 82 ms / 1.18×. If SLO-met rises without dropping η under 1.00×, keep; else fall back to cold run5-shaped `final-run4`.

### 3) Fixed GPU power cap — only after SLO-met clears the energy cliff

**Why vs factors:** `s_E^0.6` dominates. Lower constant watts cut joules if decode still meets TPOT. Cap **before** high SLO-met shrinks the numerator and can zero `s_E` (as seen when η &lt; 1.00×).

**Evidence:**

- No graded Final with a power cap has cleared the cliff yet; plan correctly deferred caps (`approach/README.md`, `CYCLE_PLAN.md`: try 250 W only if p95 TPOT ≤ ~40 ms).
- Under cliff examples: final-run1 **0.94×** → `S=0` (87/300); final-run2 **0.80×** → `S=0` (81/300); run4 full **0.92×** → `S=0` (93/300).

**Action:** After a Final with SLO-met ≫ 127 and p95 TPOT comfortably under 50 ms, set `GREENMIND_POWER_W=250` (then 225/200) on a repeat profile. Never change power mid-window.

**Explicitly demoted (measured losses):**

| Technique | Result | Paths |
|---|---|---|
| `--max-num-seqs 64` | Moves failure TPOT→TTFT; η 0.94×; `S=0` | `final-run1/log.md` |
| Cap 64 + MTP k=1 | Hits 1.07%; η 0.80×; `S=0`; p95 TTFT 7.82 s | `final-run2/log.md`, `CYCLE_PLAN.md` |
| MTP + explicit prefix caching | 91.5% MTP accept but ~1% cache hits; Final `S=0` | `run4/log.md` |

---

## 4. What worked vs did not (concrete)

| Run | Track | Config gist | `S` | SLO-met | η vs Final/Val base | p95 TTFT / TPOT | Verdict |
|---|---|---|---:|---:|---:|---|---|
| V0 | Val | AWQ defaults, MTP off | 34.8 | 56/100 | (partial) | — | Baseline ladder start (`scoring_criteria.md`) |
| run4 full | **Final** | MTP k=1 + prefix align | **0.0** | 93/300 | 0.92× | 3.59 s / 91 ms | Fail energy cliff; ~1% cache (`run4/log.md`) |
| run4 full | Val | same | 32.8 | 50/100 | 1.38× Val | 3.12 s / 55 ms | Below V0 |
| run5 | Val | MTP off, explicit prefix | 35.6 | 57/100 | 1.41× Val | 2.47 s / 55 ms | Slightly better; 15% hits |
| “run6” V2 | Val | **same run5 container**, warm | **95.6** | 98/100 | 2.78× Val | 0.16 s / 18 ms | Cache warm — not a new config |
| “run6” F2 | **Final** | same container | **19.1** | **127/300** | **1.18× Final** | 2.16 s / **82 ms** | **Best Final**; peak 111 running; `s_T=0.16` |
| final-run1 | **Final** | + `--max-num-seqs 64` | **0.0** | 87/300 | 0.94× | 6.54 s / 67 ms | Cap hurts |
| final-run2 | **Final** | + cap + MTP k=1 | **0.0** | 81/300 | 0.80× | 7.82 s / 63 ms | MTP kills cache |
| final-run3 | **Final** | + `max-num-batched-tokens 8192` | **missing** | missing | missing | missing | 300 lines scraped; **History not pasted** (`final-run3/log.md`) |
| final-run4…7 | — | planned | — | — | — | — | Not graded / empty tables |

**Diagnosis of the 19.1 Final:** Accuracy fine (`A=1`, R 0.975). Joules/request ~221 similar to Validation. Collapse is **SLO-met count** at high concurrency: p95 TPOT 82 ms and bad TTFT tails → `s_T=0.16`, `s_E=0.15`. Need ~240/300 at ≤~210 J/req for `S`≈80 (estimate in `CYCLE_PLAN.md`, not a measurement).

---

## 5. Config defaults to standardize

See also sync payload `internal/repo-sync/docker-defaults.md`.

| Item | Standard |
|---|---|
| Image | `vllm/vllm-openai@sha256:cb12c3016938a4ee98ed176ac833984089460689a0982cff4b5a60bb45b3cded` (vLLM `0.32.1rc1.dev361+g83c078d95`) |
| Container name | `mango-vllm` |
| Bind / port | `0.0.0.0:8000` → `/v1` |
| Public endpoint (Team 17) | `http://103.153.118.56:8000/v1` |
| Model / served name | `CMKL/MANGO1.5-Qwen3.5-9B-AWQ-W4A16-mtp` / `mango1.5-awq-w4a16` |
| Contract flags | `--trust-remote-code --enable-auto-tool-choice --tool-call-parser qwen3_coder --reasoning-parser qwen3` |
| Working base knobs | `--gpu-memory-utilization 0.90 --max-model-len 40960`; MTP **off**; **no** `--max-num-seqs` |
| Power | Card default 400 W unless `GREENMIND_POWER_W` set **before** start |
| Launch | `./<run>/flag-check.sh && REPLACE=1 ./<run>/start.sh` then `python3 lib/warmup.py`; `lib/watch.sh` beside Submit |
| Records | `$HOME/greenmind-runs/<stamp>_<run>/` (`environment.txt`, `startup.log`, `container-id.txt`) |

**final-run3 profile (candidate next):**

```
CMKL/MANGO1.5-Qwen3.5-9B-AWQ-W4A16-mtp
--host 0.0.0.0 --port 8000 --served-model-name mango1.5-awq-w4a16
--trust-remote-code --gpu-memory-utilization 0.90 --max-model-len 40960
--enable-auto-tool-choice --tool-call-parser qwen3_coder --reasoning-parser qwen3
--max-num-batched-tokens 8192
```

**Best measured Final server shape (run5 / warm “run6”):** same without `8192`, with `--enable-prefix-caching --mamba-cache-mode align` (or image-default caching alone — both had caching on; explicit path hit less cold).

---

## 6. Next concrete steps for the Project repo

1. **Land sync payload** from `internal/repo-sync/` per `MANIFEST.md` (scoring, aboutmodel, final-run3, `lib/flag-check.sh` + `lib/start.sh`, docker defaults).
2. **Pull remaining `lib/`** helpers not in this payload (`preflight*`, `warmup.py`, `watch.sh`, `summarize.py`) from the VM repo so launchers are runnable.
3. **Pin `VLLM_IMAGE` to the sha256 digest** in docs and start scripts; record digest on every History row.
4. **Recover final-run3 graded metrics** from grader History (or re-run Final # slot) — without `S`/η the 8192 experiment is incomplete.
5. **Execute ladder on the GPU VM only:** cold Final of `final-run4` (run5 flags) if 8192 did not beat 127/300; else promote winner into final-run5–7; power-cap only after TPOT headroom.
6. **Ask organizers** whether Validation-before-Final on the same container (prefix warm-start) is allowed; until then submit Finals cold.
7. **Keep a single score ledger** (Final vs Validation baselines never mixed). Target for competitive `S`: raise SLO-met far above 127 while staying above 1.00× η; then cut watts.

---

## Blockers / gaps

- **This analysis host has no GPU / no `nvidia-smi` / no running `mango-vllm`** — cannot re-measure; only local logs.
- **final-run3 History row missing** despite a completed 300-request scrape.
- **`~/greenmind-runs/` not present on this checkout path** for later finals (only `run4/runs/…` sample).
- Full preflight/warmup stack not in sync payload yet.
