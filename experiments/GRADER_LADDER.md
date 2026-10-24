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

## Next graded slot (start here)

| # | `<id>` | Why |
|---|---|---|
| 1 | `final-combined-v2` | After `final-combined` Final **S=18.6** (8192 budget, 115/300, p95 TPOT 87 ms). v2 uses budget **4096** + mem **0.92**, still APC on / MTP off / uncapped. |

If v2 does not beat **S=19.1** / 127 SLO-met, next cold Final is `run6-bestsofar` (default ~2048, mem 0.90). Do **not** burn slots on c2/c3/isolate/`e-seqs-*` for score.

## Already measured (do not re-run for score)

| `<id>` | Result |
|---|---|
| `a-awq-control` | Final S=0 (cache off + seqs 32) |
| `c1-mtp-k1` | Final S=0 (MTP, cache off) |
| `final-combined` | Final **S=18.6**, 115/300, η 1.19×, p95 TPOT 87 ms |

Do not run Validation on the container before Final (warms the prefix cache).
