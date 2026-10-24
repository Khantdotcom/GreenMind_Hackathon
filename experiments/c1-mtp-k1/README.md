# Experiment C1 — MTP `num_speculative_tokens=1`

## Hypothesis

With prefix caching off, draft `1` token(s) per step. More accepted tokens per step can lower TPOT and joules per output token. The model card's own smoke tests report 64–76% acceptance. One full server measured 91.5% acceptance at k=1 and still scored Final `S=0` because prefix caching was also on. This profile keeps caching off so acceptance can be read without that confound.

## Knobs

Under test: `--speculative-config` method `mtp`, `num_speculative_tokens=1`, model `CMKL/MANGO1.5-Qwen3.5-9B-AWQ-W4A16-mtp`.

Prefix caching is `--no-enable-prefix-caching`. Do not add `--enable-prefix-caching` to this profile. That pair is isolated in `c-isolate-mtp-cache`.

Held fixed: weights, served name, `--gpu-memory-utilization 0.90`, `--max-model-len 40960`, tool-call parser `qwen3_coder`, reasoning parser `qwen3`, chunked prefill on, `--max-num-batched-tokens 8192`, `--max-num-seqs 32`, card-default power. GPU memory stays at the run default `0.90` (the plan's `0.92` is not introduced here). Prefix caching off. No power cap.

## Accuracy

Expect accuracy to match C0 if verification is exact at temperature 0. Any family penalty or a drop through the `R ≥ 0.98` gate eliminates this `k`.

## Energy (`sE`)

Expect `η` to rise only when accepted drafts remove full-model decode steps. Rejected drafts can increase joules. `sE` uses Final `η_base = 0.00163` and saturates at `0.00489`. No power cap on this row: cap plus MTP already lost the cliff.

## Latency (`sL`) and throughput (`sT`)

Expect p95 TPOT to move toward 50 ms if the acceptance length is honestly above 1. TTFT should stay near C0, because MTP does not skip prefill.

At the 4 req/s peak, verification cost can erase the tokens/step gain. Record peak SLO share separately from the quiet phase.

## How to run

From the repo root. These commands do not request `http://103.153.118.56:8000/v1`.

```bash
export VLLM_IMAGE=vllm/vllm-openai@sha256:cb12c3016938a4ee98ed176ac833984089460689a0982cff4b5a60bb45b3cded
export CONTAINER_NAME=mango-vllm
export PORT=8000
export BIND=0.0.0.0
./lib/flag-check.sh experiments/c1-mtp-k1/profile.args
./experiments/c1-mtp-k1/run.sh
./experiments/c1-mtp-k1/run.sh --check
```

On the GPU VM, after flag-check prints `RESULT: FLAG CHECK PASSED`:

```bash
GREENMIND_CONFIRM_LAUNCH=1 ./experiments/c1-mtp-k1/run.sh --launch
```

`GREENMIND_POWER_W` must be unset. The runner refuses a power cap.
Container name `mango-vllm`, bind `0.0.0.0:8000`, image digest above, Hugging Face cache mount `$HOME/.cache/huggingface:/root/.cache/huggingface`, and labels `greenmind.run`, `greenmind.tier`, `greenmind.bind` match `docs/ops/docker-defaults.md`.
Served name `mango1.5-awq-w4a16`. Weights `CMKL/MANGO1.5-Qwen3.5-9B-AWQ-W4A16-mtp`.
The runner does not remove an existing `mango-vllm` container and does not call `lib/start.sh`.

## Score context

`S = 100 · A · sE^0.6 · sT^0.2 · sL^0.2` on the Final track.
`η_base = 0.00163`, `K = 3`, full energy at `η = 0.00489` (about 204 J per SLO-met request).
Reference macro-accuracy `87.8%`. Full accuracy gate at `R ≥ 0.98` (macro about `86.0%`).
TTFT SLO is `0.5 s + 0.25 s` per 1k input tokens. TPOT SLO is `50 ms`.
Copy the grader History row into `experiments/ledger.template.csv`. Turn that row into factors with `python3 experiments/lib/score.py` and the measured fields. This README does not claim an `S`.

## Blank measurement row

| run_id | macro | SLO-met | joules | p95 TTFT | p95 TPOT | prefix hits | MTP accept | preemptions | S |
|---|---|---|---|---|---|---|---|---|---|
| `c1-mtp-k1` | | | | | | | | | |
