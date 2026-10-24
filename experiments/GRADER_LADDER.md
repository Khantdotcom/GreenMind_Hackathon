# Grader ladder — single arm: `final-combined`

Final allows **2 submissions per hour**. Optimize **only** `experiments/final-combined` (process 3A: one knob → one cold Final → paste History).

`--launch` reuses `mango-vllm` in place so port `8000` has one server.

## Setup (once per shell)

```bash
export VLLM_IMAGE=vllm/vllm-openai@sha256:cb12c3016938a4ee98ed176ac833984089460689a0982cff4b5a60bb45b3cded
export CONTAINER_NAME=mango-vllm
export PORT=8000
export BIND=0.0.0.0
unset GREENMIND_POWER_W
```

## Next graded slot

```bash
./experiments/final-combined/run.sh --check
GREENMIND_CONFIRM_LAUNCH=1 ./experiments/final-combined/run.sh --launch
```

| Gate | Profile knobs | Goal |
|---|---|---|
| **0 (now)** | budget **2048**, mem **0.95**, APC on, MTP off, uncapped | `η > 1.0×`, `S > 0` (recover cliff) |
| **1 (after Gate 0)** | budget only ∈ `{1536, 2048, 3072}` | raise SLO-met / cut p95 TPOT |

Do not run Validation before Final. Do not re-burn budget **1024**, **8192**, or `--max-num-seqs 64` for score.

## Already measured

| Config | S | Notes |
|---|---:|---|
| Best Final (~2048 / 0.90) | 19.1 | Reference shape |
| `final-combined` @8192 | 18.6 | TPOT 87 ms |
| ITL-first @1024 / 0.95 | **0.0** | TTFT 5.54 s, η 0.79× |
