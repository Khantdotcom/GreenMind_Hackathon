# Grader — single arm: `final-combined` (push to main)

```bash
export VLLM_IMAGE=vllm/vllm-openai@sha256:cb12c3016938a4ee98ed176ac833984089460689a0982cff4b5a60bb45b3cded
export CONTAINER_NAME=mango-vllm PORT=8000 BIND=0.0.0.0
unset GREENMIND_POWER_W

./experiments/final-combined/run.sh --check
GREENMIND_CONFIRM_LAUNCH=1 ./experiments/final-combined/run.sh --launch
```

| Gate | Knobs | Goal |
|---|---|---|
| 0 | budget 2048, mem 0.95, APC on, MTP off | above energy cliff |
| **1 (now)** | Gate 0 + **ngram** speculation k=4 | pull p95 TPOT / raise sE sT sL toward 1 |

Cold Final only. No Validation warm. No MTP+APC. No `max-num-seqs 64`.
