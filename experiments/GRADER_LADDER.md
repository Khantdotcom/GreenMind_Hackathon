# Grader — best cold Final is Gate 0 #11 S=21.0

```bash
export VLLM_IMAGE=vllm/vllm-openai@sha256:cb12c3016938a4ee98ed176ac833984089460689a0982cff4b5a60bb45b3cded
export CONTAINER_NAME=mango-vllm PORT=8000 BIND=0.0.0.0
unset GREENMIND_POWER_W
```

| Arm | Directory | Result | Launch |
|---|---|---|---|
| **Gate 0 (keep)** | `final-combined` | Final **#11 S=21.0** | `./experiments/final-combined/run.sh --launch` |
| A | `final-a-budget-1536` | Val #22 S=19.9, weak | skip |
| B | `final-b-budget-3072` | Final #12 **S=16.5 lose** | skip |
| C | `final-c-mtp-default-apc` | Val #23 S=29.6, Final #13 **S=12.7 lose** | skip |
| **D (run next)** | `final-d-active-seqs-80` | unmeasured | `./experiments/final-d-active-seqs-80/run.sh --launch` |
| E | `final-e-active-seqs-96` | unmeasured; only if D TTFT cliffs | `./experiments/final-e-active-seqs-96/run.sh --launch` |

`--check` first, then `GREENMIND_CONFIRM_LAUNCH=1 … --launch`. Cold **Final** only (no Validation on the same container).

Do not re-burn: ngram, budgets 1024/1536/3072/8192, `--max-num-seqs 64`, MTP+explicit APC, MTP default-APC (C Final).
