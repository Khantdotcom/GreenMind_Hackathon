# C — MTP k=1, image-default APC only (hail mary)

From Gate 0 (`final-combined` #11 S=21.0): add MTP `num_speculative_tokens=1` and **omit** both `--enable-prefix-caching` and `--disable-prefix-caching`.

## Hypothesis

MTP can cut decode TPOT when acceptance is high. MTP + **explicit** `--enable-prefix-caching` collapsed cache hits (~1%) and Final η under baseline (S=0). This arm asks whether leaving APC to the image default (no explicit enable) avoids that collapse while still getting MTP decode wins. High cliff risk — cold Final only.

## Knobs

| Knob | Value | vs Gate 0 |
|---|---|---|
| `--max-num-batched-tokens` | 2048 | same |
| `--gpu-memory-utilization` | 0.95 | same |
| `--enable-prefix-caching` | **absent** | was on |
| `--disable-prefix-caching` | **absent** | n/a |
| `--speculative-config` MTP k=1 | **on** | was off |
| `--max-num-seqs` | unset | same |

`entry.sh` refuses MTP only when `--enable-prefix-caching` is also present (except `c-isolate-mtp-cache`). This profile is allowed to launch without `--isolate-failure`.

## How to run

```bash
export VLLM_IMAGE=vllm/vllm-openai@sha256:cb12c3016938a4ee98ed176ac833984089460689a0982cff4b5a60bb45b3cded
export CONTAINER_NAME=mango-vllm PORT=8000 BIND=0.0.0.0
unset GREENMIND_POWER_W
./experiments/final-c-mtp-default-apc/run.sh --check
GREENMIND_CONFIRM_LAUNCH=1 ./experiments/final-c-mtp-default-apc/run.sh --launch
```

Prefer **cold Final**. Watch prefix-cache hit rate in telemetry. Paste History into `log.md` before ranking.
