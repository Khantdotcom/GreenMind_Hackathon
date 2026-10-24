# Candidate configuration — decomposed, not launched

## Hypothesis

`experimentation_steps.md` section 4 offers one integrated command: AWQ MTP weights, prefix caching, chunked prefill, a scheduler budget, and MTP `k=3`. That command also sets a served name, a GPU-memory fraction, and an attention backend that are not the graded run defaults. Launching it as written would turn MTP and prefix caching on together. Measured Finals with that pair lost cache hits (about 1%) and fell through the energy cliff (`S=0`). This directory records the command and points each knob at the arm that tests it. `run.sh` will not start a server.

## The plan command (not a launch profile)

```bash
vllm serve CMKL/MANGO1.5-Qwen3.5-9B-AWQ-W4A16-mtp \
  --served-model-name mango-awq-mtp \
  --trust-remote-code \
  --gpu-memory-utilization 0.92 \
  --max-model-len 40960 \
  --attention-backend FLASHINFER \
  --enable-prefix-caching \
  --enable-chunked-prefill \
  --max-num-batched-tokens 8192 \
  --max-num-seqs 32 \
  --speculative-config '{"model":"CMKL/MANGO1.5-Qwen3.5-9B-AWQ-W4A16-mtp","num_speculative_tokens":3,"method":"mtp"}'
```

| Plan line | Where it went |
|---|---|
| Weights `CMKL/MANGO1.5-Qwen3.5-9B-AWQ-W4A16-mtp` | Every launch profile |
| Served name `mango-awq-mtp` | Not used. Graded name stays `mango1.5-awq-w4a16` |
| `--gpu-memory-utilization 0.92` | Not used. Run default stays `0.90` so it does not confound A–E |
| `--max-model-len 40960` | Every launch profile |
| `--attention-backend FLASHINFER` | Not used. It was not in the measured working base and would add a second factor |
| `--enable-prefix-caching` | `b-apc-on`, then held on for D, E, and `final-combined` |
| `--enable-chunked-prefill` | Every launch profile |
| `--max-num-batched-tokens 8192` | Frozen in A–C; swept in D; held in E and `final-combined` |
| `--max-num-seqs 32` | Frozen in A–D; swept in E; omitted from `final-combined` |
| MTP `k=3` | `c3-mtp-k3`, with prefix caching off |
| MTP and prefix caching together | `c-isolate-mtp-cache` at the measured width `k=1`, launchable only with `--isolate-failure` |
| Tool and reasoning parsers | Added on every launch profile. The benchmark requires them (`qwen3_coder`, `qwen3`) |

Contract flags that the plan omitted and this suite keeps: `--host 0.0.0.0`, `--port 8000`, `--enable-auto-tool-choice`, `--tool-call-parser qwen3_coder`, `--reasoning-parser qwen3`.

## Knobs

No launch knob. The file `plan-command.args` is the citation above in profile form so it can be diffed. It is not `profile.args`, and `run.sh` does not pass it to `experiments/lib/entry.sh`.

## Accuracy

The integrated command is not a prediction. Accuracy is judged on the single-factor arms against reference macro-accuracy `87.8%` and the full gate at `R ≥ 0.98` (about 86.0% macro).

## Energy (`sE`)

Do not expect this combined command to clear `η_base = 0.00163`. The MTP+cache pair is the measured way to lose the energy cliff. Full `sE` is `η ≥ 0.00489` with `K = 3`.

## Latency (`sL`) and throughput (`sT`)

TTFT SLO is `0.5 s + 0.25 s` per 1k input tokens. TPOT SLO is `50 ms`. Those tails are read on A–E, not on this refused command. `S = 100 · A · sE^0.6 · sT^0.2 · sL^0.2`.

## How to run

```bash
./experiments/04-candidate-integrated/run.sh
```

The script prints the table of where each knob went. `--launch` and `--check` exit non-zero and do not call Docker.

Server defaults, when you run a real arm:

```bash
export VLLM_IMAGE=vllm/vllm-openai@sha256:cb12c3016938a4ee98ed176ac833984089460689a0982cff4b5a60bb45b3cded
export CONTAINER_NAME=mango-vllm
export PORT=8000
export BIND=0.0.0.0
./lib/flag-check.sh experiments/a-awq-control/profile.args
```

Public base `http://103.153.118.56:8000/v1` is the grader endpoint. This script does not request it.
