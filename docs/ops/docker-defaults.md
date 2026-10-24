# Docker / endpoint defaults (hackathon VM)

Recorded on host `gm17` (Team 17). Verified from `run4/runs/20261024-175317_r4-full-lpt1056/environment.txt` and `lib/start.sh`.

## Image

| Field | Value |
|---|---|
| Tag used in launchers | `vllm/vllm-openai:nightly` (env `VLLM_IMAGE`) |
| Pinned digest (graded runs) | `sha256:cb12c3016938a4ee98ed176ac833984089460689a0982cff4b5a60bb45b3cded` |
| Repo digest form | `vllm/vllm-openai@sha256:cb12c3016938a4ee98ed176ac833984089460689a0982cff4b5a60bb45b3cded` |
| vLLM version in that image | `0.32.1rc1.dev361+g83c078d95` |

Prefer launching with the digest pin so later `:nightly` pulls cannot change flags mid-ladder:

```bash
export VLLM_IMAGE=vllm/vllm-openai@sha256:cb12c3016938a4ee98ed176ac833984089460689a0982cff4b5a60bb45b3cded
```

## Container

| Field | Value |
|---|---|
| Name (`CONTAINER_NAME`) | `mango-vllm` |
| Example historical id | `d753a4a716aaed32a0989a64ea3ed08c2c07c3e5e2a585c3dc31c829a631629d` (full-lpt1056 launch; not necessarily still running) |
| Labels | `greenmind.run`, `greenmind.tier`, `greenmind.bind` |
| GPU | `--gpus all`, `--ipc=host` |
| HF cache mount | `$HOME/.cache/huggingface:/root/.cache/huggingface` |
| Restart | `unless-stopped` |

## Endpoint / bind

| Field | Value |
|---|---|
| Host port (`PORT`) | `8000` |
| Bind (`BIND`) | `0.0.0.0` (required; loopback fails grader health) |
| Local URL | `http://127.0.0.1:8000/v1` |
| Public grader endpoint (Team 17) | `http://103.153.118.56:8000/v1` |
| Served model name | `mango1.5-awq-w4a16` |
| Weights | `CMKL/MANGO1.5-Qwen3.5-9B-AWQ-W4A16-mtp` |

## Env vars the launcher understands

| Var | Role | Default |
|---|---|---|
| `GREENMIND_RUN` | Run folder name / container label | set by `<run>/start.sh` |
| `GREENMIND_PROFILE` | Path to `profile.args` | set by `<run>/start.sh` |
| `GREENMIND_TIER` | Record directory name | defaults to `GREENMIND_RUN` |
| `GREENMIND_POWER_W` | Fixed GPU power limit (watts) before start | empty = card default (~400 W) |
| `CONTAINER_NAME` | Docker name | `mango-vllm` |
| `PORT` | Host port | `8000` |
| `VLLM_IMAGE` | Image tag or `@sha256:…` | `vllm/vllm-openai:nightly` |
| `BIND` | `0.0.0.0` or `127.0.0.1` | `0.0.0.0` |
| `REPLACE` | `1` = save prior record, remove, relaunch | unset = refuse if container exists |
| `DRY_RUN` | `1` = print docker command only | unset |
| `WAIT_SECONDS` | Wait for `/v1/models` | `900` |
| `SKIP_PREFLIGHT` | `1` = skip after ready | unset |
| `RUNS_DIR` | Launch records | `$HOME/greenmind-runs` |

## Compose-less run snippet (matches `lib/start.sh`)

```bash
docker run -d \
  --name mango-vllm \
  --restart unless-stopped \
  --gpus all \
  --ipc=host \
  -p 0.0.0.0:8000:8000 \
  -v "$HOME/.cache/huggingface:/root/.cache/huggingface" \
  --label greenmind.run=final-run3 \
  --label greenmind.tier=final-run3 \
  --label greenmind.bind=0.0.0.0 \
  vllm/vllm-openai@sha256:cb12c3016938a4ee98ed176ac833984089460689a0982cff4b5a60bb45b3cded \
  # … plus args from final-run3/profile.args …
```

Preferred path (flag-check + shared launcher):

```bash
export VLLM_IMAGE=vllm/vllm-openai@sha256:cb12c3016938a4ee98ed176ac833984089460689a0982cff4b5a60bb45b3cded
./final-run3/flag-check.sh && REPLACE=1 ./final-run3/start.sh
python3 lib/warmup.py
# second terminal: ./lib/watch.sh just before Submit
```

## Flag-check usage

```bash
# Via run wrapper (recommended)
./final-run3/flag-check.sh

# Or directly
./lib/flag-check.sh final-run3/profile.args
VLLM_IMAGE=vllm/vllm-openai@sha256:cb12c301… ./lib/flag-check.sh final-run3/profile.args
```

Behavior (`lib/flag-check.sh`):

1. Prints image and `vllm.__version__`.
2. Loads `vllm serve --help=all` (throwaway container; may need `--gpus all` if device infer fails; may fall back to `docker exec mango-vllm` if the running image id matches).
3. For every `--flag` line in the profile, `[PASS]` / `[FAIL]`.
4. Exit non-zero on any unknown flag. **Do not launch on FAIL.**
5. MTP method and hybrid prefix caching are only proven by the **startup log**, not by flag-check.

## Power

Card default on the graded VM: **400 W** (`NVIDIA A100-SXM4-40GB`, driver `580.173.02`). Set only via `GREENMIND_POWER_W` **before** the container starts; never change power during a graded window.
