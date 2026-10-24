# Rounded profile — best base, three unburned levers

Built on Gate 0 (best **cold Final S=21.0**) and D’s Validation (S=29.2, accuracy 90.8%, no TTFT cliff).

## Honesty about S ≥ 90

`S = 100 · A · sE^0.6 · sT^0.2 · sL^0.2`. With A≈1, S≥90 needs **sE, sT, and sL all near 0.9** at once:

| Need | Rough bar | Best cold Final (#11) |
|---|---|---|
| sE | η ≳ 2.7× → about **240/300** SLO-met at ~200 J/req | 120/300, η 1.24×, sE 0.20 |
| sT | ~90% of the peak phase inside SLO | sT 0.12 |
| sL | p95 TPOT ≤ 50 ms and TTFT near each request’s SLO | TPOT **88 ms**, TTFT 2.40 s, sL 0.45 |

Nothing measured on a cold Final is close. The only S≥90 was a **warm Validation (95.6)** on prompts already in cache. This folder does not claim that number.

## What this stack changes (and what it refuses)

| Knob | Value | Why it is in |
|---|---|---|
| Budget / mem / APC / MTP | **2048 / 0.95 / on / off** | Only Final shape that scored 21.0 |
| `--max-num-active-seqs` | **80** | Caps RUNNING without shrinking CUDA graphs. `--max-num-seqs 64` scored 0. D Val kept TTFT at 2.63 s |
| `--mamba-ssm-cache-dtype` | **bfloat16** | 24 of 32 layers are recurrent state. Smaller state → more cache, possible finer reuse. Untested |
| `--prefix-match-unit` | **16** | vLLM: match inside a large hybrid block (cold Final hit rate was ~44%). Must divide every cache block; if startup rejects it, say so |

Left out on purpose: MTP (Final 12.7), ngram (Val 4.5), budgets 1024/1536/3072/8192, FP8 KV (A100 has no FP8 math; hybrid KV is a small slice), power cap (raises TPOT while we are already over 50 ms).

## How to run

Cold **Final** only. Do not run Validation on this container first.

```bash
export VLLM_IMAGE=vllm/vllm-openai@sha256:cb12c3016938a4ee98ed176ac833984089460689a0982cff4b5a60bb45b3cded
export CONTAINER_NAME=mango-vllm PORT=8000 BIND=0.0.0.0
unset GREENMIND_POWER_W
./experiments/final-rounded/run.sh --check
GREENMIND_CONFIRM_LAUNCH=1 ./experiments/final-rounded/run.sh --launch
```

If `--check` or startup says `prefix-match-unit` does not divide a block size, stop and report that line. Promote only if the cold Final **beats 21.0**.
