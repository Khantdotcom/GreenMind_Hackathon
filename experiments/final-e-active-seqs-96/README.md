# E — Gate 0 + `--max-num-active-seqs 96`

Same idea as [`final-d-active-seqs-80`](../final-d-active-seqs-80/README.md), softer cap. Run **D first**. Use E only if D’s TTFT queue blows the SLO while TPOT improved.

## How to run

```bash
export VLLM_IMAGE=vllm/vllm-openai@sha256:cb12c3016938a4ee98ed176ac833984089460689a0982cff4b5a60bb45b3cded
export CONTAINER_NAME=mango-vllm PORT=8000 BIND=0.0.0.0
unset GREENMIND_POWER_W
./experiments/final-e-active-seqs-96/run.sh --check
GREENMIND_CONFIRM_LAUNCH=1 ./experiments/final-e-active-seqs-96/run.sh --launch
```

Cold **Final** only.
