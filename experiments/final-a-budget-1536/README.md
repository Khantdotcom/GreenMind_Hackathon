# A — budget 1536 (ITL probe)

Single change from Gate 0 (`final-combined` #11 S=21.0): `--max-num-batched-tokens` **1536**.

## Hypothesis

vLLM chunked-prefill guidance: smaller budgets improve ITL/TPOT. 2048 is best measured; 1024 hit a TTFT cliff (S=0). 1536 sits between them to buy decode headroom without collapsing TTFT.

## Knobs

| Knob | Value | vs Gate 0 |
|---|---|---|
| `--max-num-batched-tokens` | **1536** | was 2048 |
| `--gpu-memory-utilization` | 0.95 | same |
| Prefix caching | on | same |
| Speculation / MTP | off | same |
| `--max-num-seqs` | unset | same |

## How to run

```bash
export VLLM_IMAGE=vllm/vllm-openai@sha256:cb12c3016938a4ee98ed176ac833984089460689a0982cff4b5a60bb45b3cded
export CONTAINER_NAME=mango-vllm PORT=8000 BIND=0.0.0.0
unset GREENMIND_POWER_W
./experiments/final-a-budget-1536/run.sh --check
GREENMIND_CONFIRM_LAUNCH=1 ./experiments/final-a-budget-1536/run.sh --launch
```

Prefer **cold Final**. Paste History into `log.md` before ranking.
