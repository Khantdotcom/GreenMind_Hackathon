# Grader — Stage A first (beat Final #11 S=21.0)

```bash
export VLLM_IMAGE=vllm/vllm-openai@sha256:cb12c3016938a4ee98ed176ac833984089460689a0982cff4b5a60bb45b3cded
export CONTAINER_NAME=mango-vllm PORT=8000 BIND=0.0.0.0
unset GREENMIND_POWER_W
```

## Run next (Stage A)

| Order | Directory | Flags | Result / launch |
|---|---|---|---|
| 1 | `final-sa-active-64` | active **64** | Final #14 **S=0** (TTFT 7.36 s) — skip |
| 2 | `final-sa-active-72` | active **72** | optional |
| **3 next** | `final-sa-active-80` | active **80** | `./experiments/final-sa-active-80/run.sh --launch` |
| 4 | `final-sa-active-88` | active **88** | if 80 cliffs TTFT |
| 5 | `final-sa-active-96` | active **96** | if 88 still cliffs |

Details: [`STAGE_A.md`](STAGE_A.md) · full plan: [`STAGE_PLAN.md`](STAGE_PLAN.md).

`--check` first, then `GREENMIND_CONFIRM_LAUNCH=1 … --launch`. **Cold Final only.**

## Cold Final — prefix-match unit 16 (unmeasured)

Single change from Gate 0 (`final-combined`): `--prefix-match-unit 16`. Budget 2048, mem 0.95, APC on, MTP off, no seq cap, no power cap. No score claimed.

```bash
./experiments/final-g0-prefix-match-16/run.sh --check
GREENMIND_CONFIRM_LAUNCH=1 ./experiments/final-g0-prefix-match-16/run.sh --launch
```

## Champion / burned

| Arm | Result |
|---|---|
| Gate 0 `final-combined` | Final **#11 S=21.0** (keep until beaten) |
| `final-g0-prefix-match-16` | unmeasured; Gate 0 + `--prefix-match-unit 16`; cold Final; no score claimed |
| Budget 1536/3072/1024/8192 | lose or Val-only |
| MTP (C) | Final #13 **S=12.7** |
| `--max-num-seqs 64` alone | Final **S=0** |
| `final-rounded` | multi-knob stack; defer until Stage A picks a cap |
