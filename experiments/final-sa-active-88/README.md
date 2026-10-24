# Stage A — active 88 (runner 128)

Single change from Gate 0 for this cell: `--max-num-seqs 128` + `--max-num-active-seqs 88`.

See [`../STAGE_A.md`](../STAGE_A.md) for the full sweep order and success criteria.

```bash
export VLLM_IMAGE=vllm/vllm-openai@sha256:cb12c3016938a4ee98ed176ac833984089460689a0982cff4b5a60bb45b3cded
export CONTAINER_NAME=mango-vllm PORT=8000 BIND=0.0.0.0
unset GREENMIND_POWER_W
./experiments/final-sa-active-88/run.sh --check
GREENMIND_CONFIRM_LAUNCH=1 ./experiments/final-sa-active-88/run.sh --launch
```

Cold **Final** only. Paste History into `log.md`.
