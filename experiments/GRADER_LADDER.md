# Grader — Stage A first (beat Final #11 S=21.0)

```bash
export VLLM_IMAGE=vllm/vllm-openai@sha256:cb12c3016938a4ee98ed176ac833984089460689a0982cff4b5a60bb45b3cded
export CONTAINER_NAME=mango-vllm PORT=8000 BIND=0.0.0.0
unset GREENMIND_POWER_W
```

## Run next (Stage A)

| Order | Directory | Flags | Launch |
|---|---|---|---|
| **1** | `final-sa-active-64` | `--max-num-seqs 128 --max-num-active-seqs 64` | `./experiments/final-sa-active-64/run.sh --launch` |
| 2 | `final-sa-active-72` | … active **72** | `./experiments/final-sa-active-72/run.sh --launch` |
| 3 | `final-sa-active-80` | … active **80** | `./experiments/final-sa-active-80/run.sh --launch` |
| 4 | `final-sa-active-88` | … active **88** | `./experiments/final-sa-active-88/run.sh --launch` |
| 5 | `final-sa-active-96` | … active **96** | `./experiments/final-sa-active-96/run.sh --launch` |

Details: [`STAGE_A.md`](STAGE_A.md) · full plan: [`STAGE_PLAN.md`](STAGE_PLAN.md).

`--check` first, then `GREENMIND_CONFIRM_LAUNCH=1 … --launch`. **Cold Final only.**

## Champion / burned

| Arm | Result |
|---|---|
| Gate 0 `final-combined` | Final **#11 S=21.0** (keep until beaten) |
| Budget 1536/3072/1024/8192 | lose or Val-only |
| MTP (C) | Final #13 **S=12.7** |
| `--max-num-seqs 64` alone | Final **S=0** |
| `final-rounded` | multi-knob stack; defer until Stage A picks a cap |
