# B — budget 3072 (midpoint toward 8192)

Single change from Gate 0 (`final-combined` #11 S=21.0): `--max-num-batched-tokens` **3072**.

## Hypothesis

Larger budgets clear prefill in fewer steps (better TTFT / fewer mixed steps). Full 8192 already lost (S=18.6, TPOT 87 ms). 3072 tests whether a milder bump helps before the 8192 cliff.

## Knobs

| Knob | Value | vs Gate 0 |
|---|---|---|
| `--max-num-batched-tokens` | **3072** | was 2048 |
| `--gpu-memory-utilization` | 0.95 | same |
| Prefix caching | on | same |
| Speculation / MTP | off | same |
| `--max-num-seqs` | unset | same |

## How to run

```bash
export VLLM_IMAGE=vllm/vllm-openai@sha256:cb12c3016938a4ee98ed176ac833984089460689a0982cff4b5a60bb45b3cded
export CONTAINER_NAME=mango-vllm PORT=8000 BIND=0.0.0.0
unset GREENMIND_POWER_W
./experiments/final-b-budget-3072/run.sh --check
GREENMIND_CONFIRM_LAUNCH=1 ./experiments/final-b-budget-3072/run.sh --launch
```

Prefer **cold Final**. Paste History into `log.md` before ranking.
