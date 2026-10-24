# Grader — Gate 0 base + A/B/C arms (push to main)

```bash
export VLLM_IMAGE=vllm/vllm-openai@sha256:cb12c3016938a4ee98ed176ac833984089460689a0982cff4b5a60bb45b3cded
export CONTAINER_NAME=mango-vllm PORT=8000 BIND=0.0.0.0
unset GREENMIND_POWER_W
```

| Arm | Directory | Single change vs Gate 0 | Launch |
|---|---|---|---|
| Gate 0 (best #11 S=21.0) | `final-combined` | budget 2048, APC on, MTP off | `./experiments/final-combined/run.sh --launch` |
| **A** (recommend first) | `final-a-budget-1536` | budget **1536** | `./experiments/final-a-budget-1536/run.sh --launch` |
| **B** | `final-b-budget-3072` | budget **3072** | `./experiments/final-b-budget-3072/run.sh --launch` |
| **C** (hail mary) | `final-c-mtp-default-apc` | MTP k=1, omit explicit APC flags | `./experiments/final-c-mtp-default-apc/run.sh --launch` |

Always `--check` first, then `GREENMIND_CONFIRM_LAUNCH=1 … --launch`. Cold **Final** for score. Validation is indicative only (different η_base 0.00154 / macro 87.2%).

Do not re-burn: ngram, budget 1024, budget 8192, `--max-num-seqs 64`, MTP+explicit `--enable-prefix-caching`.
