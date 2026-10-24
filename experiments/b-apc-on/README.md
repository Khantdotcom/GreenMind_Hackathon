# Experiment B — prefix caching on

## Hypothesis

Turn prefix caching on, still with MTP off. Hits should concentrate on the shared ~20k prefix cohort and on agentic/RAG repeats. Unique prompts should gain little. The best measured Final (`S=19.1`, 127/300, 44% prefix hits, p95 TTFT 2.16 s, p95 TPOT 82 ms) ran with caching on and MTP off. A cold explicit-cache Validation on that shape saw about 15% hits. Those numbers are priors for the direction, not a score for this profile.

## Knobs

Under test: `--enable-prefix-caching` and `--mamba-cache-mode align`.

On the pinned image, `--mamba-cache-mode` is deprecated and the engine says it has no effect. Caching follows `--enable-prefix-caching`. The `align` line is kept so this command stays comparable to `run5/profile.args`. `./lib/flag-check.sh` may WARN that `align` is missing from the deprecation help. That WARN is not a failed flag.

Same server command as `d2-batched-8192` and `e-seqs-32`.

Held fixed: weights, served name, `--gpu-memory-utilization 0.90`, `--max-model-len 40960`, tool-call parser `qwen3_coder`, reasoning parser `qwen3`, chunked prefill on, `--max-num-batched-tokens 8192`, `--max-num-seqs 32`, card-default power. GPU memory stays at the run default `0.90` (the plan's `0.92` is not introduced here). MTP off.

## Accuracy

Expect macro-accuracy to stay on the AWQ control. A drop means the hybrid cache reused the wrong state. Treat that as a hard fail for this factor.

## Energy (`sE`)

Expect fewer joules per repeated prompt, which is the path to a higher `sE`. Full `sE` still needs `η ≥ 0.00489`. Caching alone did not get the measured Final there (that run was about 1.18× baseline).

## Latency (`sL`) and throughput (`sT`)

Expect lower TTFT where the prefix hits, which moves `sL` through `p95(TTFT/SLO)`. TPOT is a decode metric and should move less than TTFT.

A higher peak SLO share is a bonus when TTFT was the miss. It is not guaranteed at 4 req/s if TPOT stays above 50 ms.

## How to run

From the repo root. These commands do not request `http://103.153.118.56:8000/v1`.

```bash
export VLLM_IMAGE=vllm/vllm-openai@sha256:cb12c3016938a4ee98ed176ac833984089460689a0982cff4b5a60bb45b3cded
export CONTAINER_NAME=mango-vllm
export PORT=8000
export BIND=0.0.0.0
./lib/flag-check.sh experiments/b-apc-on/profile.args
./experiments/b-apc-on/run.sh
./experiments/b-apc-on/run.sh --check
```

On the GPU VM, after flag-check prints `RESULT: FLAG CHECK PASSED`:

```bash
GREENMIND_CONFIRM_LAUNCH=1 ./experiments/b-apc-on/run.sh --launch
```

`GREENMIND_POWER_W` must be unset. The runner refuses a power cap.
Container name `mango-vllm`, bind `0.0.0.0:8000`, image digest above, Hugging Face cache mount `$HOME/.cache/huggingface:/root/.cache/huggingface`, and labels `greenmind.run`, `greenmind.tier`, `greenmind.bind` match `docs/ops/docker-defaults.md`.
Served name `mango1.5-awq-w4a16`. Weights `CMKL/MANGO1.5-Qwen3.5-9B-AWQ-W4A16-mtp`.
On `--launch`, the runner reuses the name `mango-vllm` (replaces it in place if it already exists) so only one experiment serves `:8000`, then waits on local `http://127.0.0.1:8000/v1/models` and a local chat probe. It does not request `http://103.153.118.56:8000/v1` and does not call `lib/start.sh`. Final: 2 submissions/hour.

## Score context

`S = 100 · A · sE^0.6 · sT^0.2 · sL^0.2` on the Final track.
`η_base = 0.00163`, `K = 3`, full energy at `η = 0.00489` (about 204 J per SLO-met request).
Reference macro-accuracy `87.8%`. Full accuracy gate at `R ≥ 0.98` (macro about `86.0%`).
TTFT SLO is `0.5 s + 0.25 s` per 1k input tokens. TPOT SLO is `50 ms`.
Copy the grader History row into `experiments/ledger.template.csv`. Turn that row into factors with `python3 experiments/lib/score.py` and the measured fields. This README does not claim an `S`.

## Blank measurement row

| run_id | macro | SLO-met | joules | p95 TTFT | p95 TPOT | prefix hits | MTP accept | preemptions | S |
|---|---|---|---|---|---|---|---|---|---|
| `b-apc-on` | | | | | | | | | |
