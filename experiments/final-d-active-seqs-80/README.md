# D — Gate 0 + `--max-num-active-seqs 80`

Built on the best cold Final (`final-combined` #11 **S=21.0**). One new flag.

## Why this, not another budget or MTP

A (1536) Val was weak, B (3072) Final S=16.5, C (MTP) Final S=12.7. Binding miss on #11 is still **p95 TPOT 88 ms at ~111 running**.

`--max-num-seqs 64` already scored Final S=0: it caps admission **and** shrinks CUDA-graph capture, and TTFT went to 6.54 s. vLLM 0.31+ [`--max-num-active-seqs`](https://docs.vllm.ai/en/v0.32.0/configuration/engine_args/) caps how many requests sit in RUNNING **without** shrinking graph capacity. Decode batches stay smaller; the runner can still capture large graphs.

80 is between the failed hard cap (64) and the uncapped peak (~111).

## Knobs

| Knob | Value |
|---|---|
| `--max-num-batched-tokens` | 2048 (Gate 0) |
| `--gpu-memory-utilization` | 0.95 |
| Prefix caching | on |
| MTP | off |
| `--max-num-seqs` | unset |
| `--max-num-active-seqs` | **80** |

## How to run

Cold **Final** only. Do not Validation first.

```bash
export VLLM_IMAGE=vllm/vllm-openai@sha256:cb12c3016938a4ee98ed176ac833984089460689a0982cff4b5a60bb45b3cded
export CONTAINER_NAME=mango-vllm PORT=8000 BIND=0.0.0.0
unset GREENMIND_POWER_W
./experiments/final-d-active-seqs-80/run.sh --check
GREENMIND_CONFIRM_LAUNCH=1 ./experiments/final-d-active-seqs-80/run.sh --launch
```

Sibling if 80 queues TTFT too hard: `final-e-active-seqs-96`.
