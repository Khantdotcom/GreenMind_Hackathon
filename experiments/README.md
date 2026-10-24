# Experiment suite

Runnable profiles for [`experimentation_steps.md`](../experimentation_steps.md). Each directory is one arm: its own `profile.args`, `run.sh`, and README (hypothesis, knobs, and accuracy / energy / latency expectations).

The runners call [`lib/flag-check.sh`](../lib/flag-check.sh) and use the docker defaults in [`docs/ops/docker-defaults.md`](../docs/ops/docker-defaults.md). They do not call `lib/start.sh` or `final-run3/start.sh`. They do not request `http://103.153.118.56:8000/v1`.

Nothing here is a graded score. Paste a History row into [`ledger.template.csv`](ledger.template.csv) and compute factors with `python3 experiments/lib/score.py`.

## Defaults (same strings as the graded VM)

| Item | Value |
|---|---|
| Image | `vllm/vllm-openai@sha256:cb12c3016938a4ee98ed176ac833984089460689a0982cff4b5a60bb45b3cded` |
| vLLM in that image | `0.32.1rc1.dev361+g83c078d95` |
| Container | `mango-vllm` |
| Bind | `0.0.0.0:8000` → container port 8000 |
| Local base | `http://127.0.0.1:8000/v1` |
| Public grader base | `http://103.153.118.56:8000/v1` |
| Weights | `CMKL/MANGO1.5-Qwen3.5-9B-AWQ-W4A16-mtp` |
| Served name | `mango1.5-awq-w4a16` |
| Power | card default (~400 W). Leave `GREENMIND_POWER_W` unset |

Contract flags on every launch profile match `final-run3/profile.args`: `--trust-remote-code`, `--max-model-len 40960`, `--enable-auto-tool-choice`, `--tool-call-parser qwen3_coder`, `--reasoning-parser qwen3`. GPU memory is `0.90` on ladder arms; `final-combined` (Gate 0) and `final-combined-v2` use `0.95`.

## Score

`S = 100 · A · sE^0.6 · sT^0.2 · sL^0.2` on the Final track.

| Constant | Final |
|---|---|
| `η_base` | `0.00163` SLO-met requests/J |
| `K` | `3` |
| Full `sE` | `η ≥ 0.00489` (~204 J per SLO-met) |
| Reference macro-accuracy | `87.8%` |
| Full `A` | `R ≥ 0.98` (~86.0% macro) |
| TTFT SLO | `0.5 s + 0.25 s` per 1k input tokens |
| TPOT SLO | `50 ms` |

`η` at or below `η_base` forces `sE = 0` and `S = 0`. Validation baselines are a different track and are not accepted by `experiments/lib/score.py`.

## What measured runs already ruled out

- MTP together with prefix caching: cache hits fell to about 1% and Final `η` dropped under baseline (`S=0`) even with high draft acceptance.
- A power cap together with MTP: Final `η` about 0.80×, `S=0`.
- `--max-num-seqs 64`: the miss moved toward TTFT (p95 6.54 s) and `η` fell to about 0.94×.

Launch profiles keep MTP and prefix caching apart, except `c-isolate-mtp-cache`, which exists to reproduce the cache collapse. No profile sets a power cap. `final-combined` and `final-combined-v2` do not set `--max-num-seqs`.

On this image, `--mamba-cache-mode` is deprecated and has no effect. Prefix caching follows `--enable-prefix-caching`. Profiles that turn caching on still pass `--mamba-cache-mode align` so the line matches `run5/profile.args`. Flag-check may WARN that `align` is missing from the deprecation help. That WARN is expected.

APC-off profiles use `--disable-prefix-caching`. This image's `EnableDisableAction` lists that form in `--help` and hides `--no-enable-prefix-caching` (still accepted at runtime, but `lib/flag-check.sh` only reads help).

## Order

Change one factor at a time. Use one fixed manifest ([`workload/`](workload/README.md)) for every arm. Do not run a Validation on the container before a Final: the Validation prompts are the first 100 of the Final and would warm the prefix cache.

| Step | Directory | What changes |
|---|---|---|
| Freeze | [`03-reference-baseline`](03-reference-baseline/README.md) | Published BF16 Final constants. Does not start a server. |
| Decompose | [`04-candidate-integrated`](04-candidate-integrated/README.md) | Section 4's combined command. Refuses to launch it. |
| A | [`a-awq-control`](a-awq-control/README.md) | AWQ, APC off, MTP off, scheduler frozen |
| B | [`b-apc-off`](b-apc-off/README.md), [`b-apc-on`](b-apc-on/README.md) | Prefix caching, MTP off |
| C | [`c0-mtp-off`](c0-mtp-off/README.md), [`c1-mtp-k1`](c1-mtp-k1/README.md), [`c2-mtp-k2`](c2-mtp-k2/README.md), [`c3-mtp-k3`](c3-mtp-k3/README.md) | MTP `k = 0..3` with APC off |
| Isolate | [`c-isolate-mtp-cache`](c-isolate-mtp-cache/README.md) | MTP k=1 plus APC. Failure mode only. |
| D | [`d1-batched-4096`](d1-batched-4096/README.md), [`d2-batched-8192`](d2-batched-8192/README.md), [`d3-batched-16384`](d3-batched-16384/README.md) | Token budget. APC on, MTP off |
| E | [`e-seqs-16`](e-seqs-16/README.md), [`e-seqs-32`](e-seqs-32/README.md), [`e-seqs-64`](e-seqs-64/README.md) | `--max-num-seqs`. Budget pre-registered at 8192 |
| Balance | [`final-combined`](final-combined/README.md) | **Single-arm high-S base:** budget **2048**, mem **0.95**, APC on, speculation **off**, uncapped |

`a-awq-control`, `b-apc-off`, and `c0-mtp-off` share one server command: they are the control cell of the next factor. `b-apc-on`, `d2-batched-8192`, and `e-seqs-32` share another.

Score climbs happen by editing **`final-combined` only**. Ngram speculation was reverted after Validation S=4.5 (36/100). Current base is 2048/0.95/APC/no-speculation. MTP+explicit APC stays refused except `c-isolate-mtp-cache`. Measured `S≥90` exists only on warm Validation; best Final remains ~19.1.

## Commands

```bash
export VLLM_IMAGE=vllm/vllm-openai@sha256:cb12c3016938a4ee98ed176ac833984089460689a0982cff4b5a60bb45b3cded
export CONTAINER_NAME=mango-vllm
export PORT=8000
export BIND=0.0.0.0
./experiments/a-awq-control/run.sh                 # print only
./experiments/a-awq-control/run.sh --check         # lib/flag-check.sh
GREENMIND_CONFIRM_LAUNCH=1 ./experiments/a-awq-control/run.sh --launch
python3 experiments/lib/score.py --check-formula   # formula only, not a score
python3 experiments/lib/test_suite.py
```

`--check` and `--launch` need Docker. `--launch` replaces `mango-vllm` in place (same name every time; one server on `:8000`), then waits on local `/v1/models` and a local chat probe. It does not request the public grader URL. Final allows 2 submissions/hour — one experiment at a time. Flag-check uses a throwaway help container, which is the behavior of `lib/flag-check.sh`. See [`GRADER_LADDER.md`](GRADER_LADDER.md).
