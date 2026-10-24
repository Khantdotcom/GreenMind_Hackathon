# Reference baseline

## Hypothesis

The published Final baseline is the untuned BF16 server: macro-accuracy `87.8%`, `η_base = 0.00163` SLO-met requests/J, and `S = 0` because `sE = 0` at `η = η_base`. This directory freezes that comparison target and checks the score formula. It does not start a container.

The pinned weights for every launch profile in this suite are `CMKL/MANGO1.5-Qwen3.5-9B-AWQ-W4A16-mtp`. Re-serving a different BF16 checkpoint would leave the docker contract in `docs/ops/docker-defaults.md`. Treat `87.8%` and `0.00163` as the grader constants from `scoring_criteria.md`, and compare later History rows to them.

## Knobs

None. There is no `vllm serve` profile.

Held fixed: Final `η_base = 0.00163`, `K = 3`, reference macro-accuracy `87.8%`, image digest `vllm/vllm-openai@sha256:cb12c3016938a4ee98ed176ac833984089460689a0982cff4b5a60bb45b3cded`, container name `mango-vllm`, bind `0.0.0.0:8000`, public base `http://103.153.118.56:8000/v1`.

## Accuracy

The reference macro-accuracy is `87.8%`. Later AWQ rows need `R ≥ 0.98` (macro about `86.0%`) for a full accuracy factor before any family penalty. This directory does not measure a new accuracy.

## Energy (`sE`)

`sE = clip(ln(η / 0.00163) / ln 3, 0, 1)`. At `η = 0.00163`, `sE = 0`. Full marks need `η ≥ 0.00489`.

## Latency (`sL`) and throughput (`sT`)

TTFT SLO is `0.5 s + 0.25 s` per 1k input tokens. TPOT SLO is `50 ms`. `sT` is the peak-phase SLO share at 4 req/s. `sL` is the square root of the two capped tail ratios. The BF16 baseline is not re-timed here.

`S = 100 · A · sE^0.6 · sT^0.2 · sL^0.2`.

## How to run

From the repo root. This script does not call `lib/flag-check.sh`, does not start `mango-vllm`, and does not request the public grader URL.

```bash
./experiments/03-reference-baseline/run.sh
./experiments/03-reference-baseline/run.sh --record
python3 experiments/lib/score.py --check-formula
```

`--record` writes a local text file with read-only `nvidia-smi` and `docker image inspect` output when those commands exist. It does not pull an image and does not `docker run`.

`--launch` and `--check` are refused. Server arms start at `experiments/a-awq-control`.

## Blank measurement row

| run_id | macro | SLO-met | joules | η | notes |
|---|---|---|---|---|---|
| `reference-bf16` | 87.8% (published) | | | 0.00163 (published) | not re-served by this suite |
