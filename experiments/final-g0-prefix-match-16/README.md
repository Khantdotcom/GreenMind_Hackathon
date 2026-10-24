# Gate 0 + prefix-match unit 16

Single change from Gate 0 (`final-combined` #11 S=21.0): `--prefix-match-unit` **16**.

This arm is a **cold Final**. It does not claim a score.

## Hypothesis

vLLM can match a prefix inside a large hybrid cache block when `--prefix-match-unit` divides every block. Cold Final prefix hit rate on Gate 0 was about 44%. Unit 16 is the finer match already present in `final-rounded`, isolated here so the launch command differs from Gate 0 by that flag alone.

## Knobs

| Knob | Value | vs Gate 0 |
|---|---|---|
| `--prefix-match-unit` | **16** | added |
| `--max-num-batched-tokens` | 2048 | same |
| `--gpu-memory-utilization` | 0.95 | same |
| Prefix caching | on | same |
| Speculation / MTP | off | same |
| `--max-num-seqs` | unset | same |
| `--max-num-active-seqs` | unset | same (not the rounded stack) |
| Power | card default | same |

Left out on purpose: MTP, ngram, budget changes, active-seq caps, FP8 KV, and a power cap.

## How to run

Cold **Final** only. Do not run Validation on this container first.

```bash
export VLLM_IMAGE=vllm/vllm-openai@sha256:cb12c3016938a4ee98ed176ac833984089460689a0982cff4b5a60bb45b3cded
export CONTAINER_NAME=mango-vllm PORT=8000 BIND=0.0.0.0
unset GREENMIND_POWER_W
./experiments/final-g0-prefix-match-16/run.sh --check
GREENMIND_CONFIRM_LAUNCH=1 ./experiments/final-g0-prefix-match-16/run.sh --launch
```

`lib/flag-check.sh` accepts a flag when it appears in this image's `vllm serve --help`. If `--check` or startup says `prefix-match-unit` does not divide a block size, stop and report that line. Promote only if a cold Final beats 21.0. This folder does not claim that result.
