# Final combined — single-arm climb (Gate 0)

Iterate **only this folder**. One knob change → one cold Final → paste History (process 3A). North star: raise `S` toward 100 (`A=sE=sT=sL=1`).

## Gate 0 (this profile) — approved 1B

Recover above the energy cliff using the best-known Final shape plus more KV:

- `--max-num-batched-tokens **2048**` (image default / best Final ~19.1). Measured **8192 → S=18.6**; **1024 → S=0** (TTFT 5.54 s, η 0.79×).
- `--gpu-memory-utilization **0.95**` (more KV at peak ~111 running).
- APC on, MTP **off**, **no** `--max-num-seqs`, no power cap.

After Gate 0 clears (`η > 1.0×`, `S > 0`), next lever is **2A**: scheduler-only budget in `{1536, 2048, 3072}` — still edit only this `profile.args`.

## Prior Finals (do not re-burn)

| Config | S | η | SLO-met | p95 TTFT | p95 TPOT |
|---|---:|---:|---:|---:|---:|
| Best Final (~2048, mem 0.90) | 19.1 | 1.18× | 127/300 | 2.16 s | 82 ms |
| This folder @ 8192 / 0.90 (#9) | 18.6 | 1.19× | 115/300 | 2.45 s | 87 ms |
| ITL-first 1024 / 0.95 (#10) | **0.0** | **0.79×** | 81/300 | **5.54 s** | 90 ms |

## Knobs (held)

- `--enable-prefix-caching` + `--mamba-cache-mode align` (prefill reuse).
- `--enable-chunked-prefill` (decode priority under long prefills).
- No `--speculative-config` until a later approved gate.
- No `--max-num-seqs` (cap 64 lost the cliff).
- No `GREENMIND_POWER_W` until p95 TPOT has headroom under 50 ms.

`--mamba-cache-mode align` is deprecated on this image and has no effect; caching follows `--enable-prefix-caching`.

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

Wait for local `/v1/models` and chat PASS. Submit **Final** only (no Validation warm). Paste History into `experiments/ledger.template.csv`.

## Score context

`S = 100 · A · sE^0.6 · sT^0.2 · sL^0.2`. Full `sE` needs `η ≥ 0.00489` (3× Final base `0.00163`). Full `A` needs `R ≥ 0.98` (~86.0% macro). TPOT SLO 50 ms. This README does not claim an `S`.

## Measurement rows

| run_id | budget | mem | macro | SLO-met | p95 TTFT | p95 TPOT | η | S |
|---|---:|---:|---|---:|---:|---:|---:|---:|
| `final-combined` @8192 | 8192 | 0.90 | 85.5% | 115/300 | 2.45 s | 87 ms | 1.19× | 18.6 |
| `final-combined` Gate 0 | 2048 | 0.95 | | | | | | |
