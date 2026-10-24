# Grader ladder (one experiment at a time)

Final allows **2 submissions per hour**. After each `--launch`, leave **only** that `mango-vllm` running, wait until local ready, then submit **Final** (not Validation) on the grader. Paste the History row before the next arm.

`--launch` reuses the same container name `mango-vllm`: it replaces the previous experiment in place so port `8000` always has one server.

## Setup (once per shell)

```bash
export VLLM_IMAGE=vllm/vllm-openai@sha256:cb12c3016938a4ee98ed176ac833984089460689a0982cff4b5a60bb45b3cded
export CONTAINER_NAME=mango-vllm
export PORT=8000
export BIND=0.0.0.0
unset GREENMIND_POWER_W
```

## Per arm

```bash
./experiments/<id>/run.sh --check
GREENMIND_CONFIRM_LAUNCH=1 ./experiments/<id>/run.sh --launch
# wait until the script prints local /models and chat PASS
# grader: http://103.153.118.56:8000/v1 , model mango1.5-awq-w4a16 , Final, Health, Submit
# paste History into experiments/ledger.template.csv
```

For the isolation arm only:

```bash
GREENMIND_CONFIRM_LAUNCH=1 ./experiments/c-isolate-mtp-cache/run.sh --launch --isolate-failure
```

## Remaining order (start here)

| # | `<id>` |
|---|---|
| 2 | `c1-mtp-k1` |
| 3 | `c2-mtp-k2` |
| 4 | `c3-mtp-k3` |
| 5 | `c-isolate-mtp-cache` (optional) |
| 6 | `d1-batched-4096` |
| 7 | `d2-batched-8192` |
| 8 | `d3-batched-16384` |
| 9 | `e-seqs-16` |
| 10 | `e-seqs-32` |
| 11 | `e-seqs-64` |
| 12 | `final-combined` |

Do not run Validation on the container before Final (warms the prefix cache).
