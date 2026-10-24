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

## Next graded slot (start here)

| # | `<id>` | Why |
|---|---|---|
| 1 | `final-combined-v2` | ITL-first toward sE/sT/sL **0.7–0.9**: budget **1024**, mem **0.95**, APC on / MTP off / uncapped. Need ~210–230 SLO-met and p95 TPOT ≤ ~50 ms (today 115–127 / 82–87 ms). |

If p95 TPOT stays ≥ ~70 ms and SLO-met ≲ 150, do **not** re-burn 8192 or `--max-num-seqs 64`. Next research arm is MTP k=1 with **image-default** APC only (no explicit `--enable-prefix-caching`). Fallback cold baseline: `run6-bestsofar`.

## Already measured (do not re-run for score)

| `<id>` / config | Result |
|---|---|
| best Final (~2048 uncapped) | **S=19.1**, 127/300, sE/sT/sL 0.15/0.16/0.50, TPOT 82 ms |
| `final-combined` (8192) | **S=18.6**, 115/300, 0.16/0.15/0.39, TPOT 87 ms |
| `--max-num-seqs 64` | S=0, η 0.94×, TTFT 6.54 s |
| MTP + explicit APC | S=0, ~1% cache hits |
| `a-awq-control` / `c1-mtp-k1` | S=0 |

Do not run Validation on the container before Final (warms the prefix cache).
