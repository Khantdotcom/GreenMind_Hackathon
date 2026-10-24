# Stage A — Cap active sequences, preserve runner capacity

**Status:** implement and measure **before** Stages B/C/D.  
**Parent:** Gate 0 Final #11 **S=21.0** (budget 2048, mem 0.95, APC on, MTP off).  
**Bottleneck:** ~111 running at Final peak → p95 TPOT **88 ms** (need ≤ 50 ms). η is already 1.24×; the miss is concurrent decode pressure.

## Why this is not the burned `--max-num-seqs 64`

| Flag | What it does | Measured |
|---|---|---|
| `--max-num-seqs 64` alone | Caps admission **and** shrinks runner / CUDA-graph capture | Final S=0, TTFT 6.54 s |
| `--max-num-seqs 128` + `--max-num-active-seqs N` | Runner sized for 128; only RUNNING admission is N | Untested (this stage) |

Confirm both flags with `./experiments/final-sa-active-64/run.sh --check` on the graded image.

## Sweep (one change per cold Final)

| Order | Directory | `max-num-seqs` | `max-num-active-seqs` | Result |
|---|---|---:|---:|---|
| 1 | [`final-sa-active-64`](final-sa-active-64/) | 128 | **64** | Final #14 **S=0** — TTFT 7.36 s, η 0.87×, TPOT 68 ms. **LOSE** |
| 2 (optional) | [`final-sa-active-72`](final-sa-active-72/) | 128 | **72** | unmeasured; likely still tight |
| **3** | [`final-sa-active-80`](final-sa-active-80/) | 128 | **80** | Val #25 S=27.3 (TTFT OK). **Cold Final next** |
| 4 | [`final-sa-active-88`](final-sa-active-88/) | 128 | **88** | unmeasured |
| 5 | [`final-sa-active-96`](final-sa-active-96/) | 128 | **96** | unmeasured |

Held fixed: budget **2048**, mem **0.95**, APC on, MTP **off**, no power cap, no BF16-Mamba / prefix-match stack (those wait until Stage A picks a winner).

## Success / stop rules

- **Keep** a cell if cold Final p95 TPOT moves toward **50 ms**, TTFT stays inside its input-length SLO, and S beats **21.0** (or clear TPOT/SLO-met gains without a TTFT cliff).
- If a low N queues TTFT hard: **raise** N (do not assume lower is better).
- If all five lose or TTFT-cliff: stop Stage A; do **not** jump to MTP (Stage C).
- Rank on **cold Final** only. Do not Validation-then-Final on the same container.

## Commands

```bash
export VLLM_IMAGE=vllm/vllm-openai@sha256:cb12c3016938a4ee98ed176ac833984089460689a0982cff4b5a60bb45b3cded
export CONTAINER_NAME=mango-vllm PORT=8000 BIND=0.0.0.0
unset GREENMIND_POWER_W

# Start here
./experiments/final-sa-active-64/run.sh --check
GREENMIND_CONFIRM_LAUNCH=1 ./experiments/final-sa-active-64/run.sh --launch
# → cold Final → paste History into that folder's log.md
# then 72 → 80 → 88 → 96 as needed
```

Final allows ~2 submissions/hour — one arm at a time.

## After Stage A

See [`STAGE_PLAN.md`](STAGE_PLAN.md): B = best cap + budget around 2048–4096; C = MTP depth + attention backend; D = disagg P/D only if ≥2 GPUs.
