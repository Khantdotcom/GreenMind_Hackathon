# Final combined — single-arm climb (Gate 1)

Iterate **only this folder**. Push goes to `main`. North star: `R`, `sE`, `sT`, `sL` → 1 (so `S` → 100).

## Gate 1 (this profile)

Keep Gate 0 base, add official **n-gram speculative decoding** to cut decode TPOT under the Final peak (vLLM docs: n-gram is the lightweight speculation path; MTP+explicit APC remains forbidden).

| Knob | Value |
|---|---|
| `--max-num-batched-tokens` | **2048** |
| `--gpu-memory-utilization` | **0.95** |
| Prefix caching | on (`--enable-prefix-caching`, align line) |
| Speculation | **ngram** k=4, lookup 2–5 |
| `--max-num-seqs` | unset |
| Power | card default |

`R` is already ~0.97–1.00 on measured Finals — do not change weights/quantization. Binding miss is **p95 TPOT 82–90 ms** → low `sE`/`sT`/`sL`.

## Prior Finals

| Config | S | R | sE | sT | sL | p95 TPOT | SLO-met |
|---|---:|---:|---:|---:|---:|---:|---:|
| Best Final (~2048 / 0.90) | 19.1 | 0.975 | 0.15 | 0.16 | 0.50 | 82 ms | 127/300 |
| @8192 / 0.90 | 18.6 | 0.974 | 0.16 | 0.15 | 0.39 | 87 ms | 115/300 |
| @1024 / 0.95 | **0.0** | 0.997 | 0.00 | 0.03 | 0.26 | 90 ms | 81/300 |

## How to run

```bash
export VLLM_IMAGE=vllm/vllm-openai@sha256:cb12c3016938a4ee98ed176ac833984089460689a0982cff4b5a60bb45b3cded
export CONTAINER_NAME=mango-vllm
export PORT=8000
export BIND=0.0.0.0
unset GREENMIND_POWER_W
./experiments/final-combined/run.sh --check
GREENMIND_CONFIRM_LAUNCH=1 ./experiments/final-combined/run.sh --launch
```

Cold Final only. Paste History before the next knob.

## If Gate 1 does not move TPOT under ~60 ms

Next single-arm options (still this folder): budget ∈ `{1536, 3072}` with ngram kept, or raise ngram `num_speculative_tokens` to 5–6. Do not re-enable MTP+APC or `--max-num-seqs 64`.
