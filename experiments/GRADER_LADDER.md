# Grader — `final-combined` only (push to main)

```bash
export VLLM_IMAGE=vllm/vllm-openai@sha256:cb12c3016938a4ee98ed176ac833984089460689a0982cff4b5a60bb45b3cded
export CONTAINER_NAME=mango-vllm PORT=8000 BIND=0.0.0.0
unset GREENMIND_POWER_W
./experiments/final-combined/run.sh --check
GREENMIND_CONFIRM_LAUNCH=1 ./experiments/final-combined/run.sh --launch
```

**Now:** budget **2048**, mem **0.95**, APC on, **no speculation** (ngram Validation S=4.5 reverted). Best cold Final **#11 S=21.0**.

Cold **Final** for score. Validation is indicative only (different η_base 0.00154 / macro 87.2%).

Do not re-burn: ngram, budget 1024, budget 8192, `--max-num-seqs 64`, MTP+explicit APC.
