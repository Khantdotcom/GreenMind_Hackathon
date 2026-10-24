#!/usr/bin/env bash
# Shared launcher for run5 and later. Same docker run as scripts/start-vllm.sh.
# The vLLM arguments come from one profile. A run folder calls this; do not
# pass a tier name. Waits until the server answers, then runs the preflight
# against the same profile. Exit 0 only when it passes.
#
# Required environment, set by <run>/start.sh:
#   GREENMIND_RUN       folder name, for example run5. Stored as a container label.
#   GREENMIND_PROFILE   path to that run's profile.args
# Optional:
#   GREENMIND_TIER      short name for the record directory. Defaults to GREENMIND_RUN.
#   GREENMIND_POWER_W   GPU power limit in watts for this run. Empty means the card
#                       default, which is restored if an earlier run lowered it.
#                       Applied before the container starts, never during a window.
#
#   REPLACE=1 ./run5/start.sh       save the current container's record, then replace it
#   docker rm -f mango-vllm && ./run5/start.sh
#
# Environment (same names as scripts/start-vllm.sh):
#   CONTAINER_NAME   default mango-vllm
#   PORT             host port, default 8000
#   VLLM_IMAGE       default vllm/vllm-openai:nightly, or vllm/vllm-openai@sha256:<digest>
#   BIND             host address. Default 0.0.0.0, because the grader calls the
#                    public IP. A loopback bind fails the grader health check.
#                    BIND=127.0.0.1 is accepted for a local-only launch.
#   MODEL_ID, SERVED_MODEL_NAME, GPU_MEMORY_UTILIZATION, MAX_MODEL_LEN
#                    come from the profile. If exported, they must match it.
# Other:
#   DRY_RUN=1        print the docker command and exit
#   WAIT_SECONDS=900 how long to wait for /v1/models
#   SKIP_PREFLIGHT=1 launch only (not recommended)
#
# Sets the power limit from GREENMIND_POWER_W (or back to the card default).
# Never locks clocks.
set -Eeuo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$HERE/.." && pwd)"
CHECKS="$HERE/preflight_checks.py"

RUN_NAME="${GREENMIND_RUN:-}"
PROFILE_FILE="${GREENMIND_PROFILE:-}"
TIER="${GREENMIND_TIER:-$RUN_NAME}"
POWER_W="${GREENMIND_POWER_W:-}"
CONTAINER="${CONTAINER_NAME:-mango-vllm}"
PORT="${PORT:-8000}"
IMAGE="${VLLM_IMAGE:-vllm/vllm-openai:nightly}"
WAIT_SECONDS="${WAIT_SECONDS:-900}"
RUNS_DIR="${RUNS_DIR:-$HOME/greenmind-runs}"
BASE_URL="http://127.0.0.1:${PORT}/v1"

die() {
  echo "[ERROR] $*" >&2
  exit 1
}

[[ -n "$RUN_NAME" && -n "$PROFILE_FILE" ]] || die "GREENMIND_RUN and GREENMIND_PROFILE are required. Launch with ./runN/start.sh, not lib/start.sh."
[[ -f "$PROFILE_FILE" ]] || die "Profile not found: $PROFILE_FILE"

[[ "$PORT" =~ ^[0-9]+$ ]] || die "PORT must be a number."
if [[ "$IMAGE" != "vllm/vllm-openai:nightly" && ! "$IMAGE" =~ ^vllm/vllm-openai@sha256:[0-9a-f]{64}$ ]]; then
  die "VLLM_IMAGE must be vllm/vllm-openai:nightly or vllm/vllm-openai@sha256:<digest>."
fi

command -v python3 >/dev/null 2>&1 || die "python3 is required."
ARGS_FILE="$(mktemp)"
trap 'rm -f "$ARGS_FILE"' EXIT
python3 "$CHECKS" launch-args "$PROFILE_FILE" > "$ARGS_FILE" \
  || die "Profile failed the endpoint contract: $PROFILE_FILE"
mapfile -d '' VLLM_ARGS < "$ARGS_FILE"
(( ${#VLLM_ARGS[@]} > 0 )) || die "Profile produced no arguments: $PROFILE_FILE"

PROFILE_MODEL="$(python3 "$CHECKS" profile-value "$PROFILE_FILE" model)"
PROFILE_SERVED="$(python3 "$CHECKS" profile-value "$PROFILE_FILE" --served-model-name)"
PROFILE_MEM="$(python3 "$CHECKS" profile-value "$PROFILE_FILE" --gpu-memory-utilization || echo '')"
PROFILE_LEN="$(python3 "$CHECKS" profile-value "$PROFILE_FILE" --max-model-len)"

# scripts/start-vllm.sh variables: a leftover export must not disagree with the profile.
if [[ -n "${MODEL_ID:-}" && "$MODEL_ID" != "$PROFILE_MODEL" && "$MODEL_ID" != "$PROFILE_SERVED" ]]; then
  die "MODEL_ID=$MODEL_ID differs from the profile ($PROFILE_MODEL). Unset it."
fi
if [[ -n "${SERVED_MODEL_NAME:-}" && "$SERVED_MODEL_NAME" != "$PROFILE_SERVED" ]]; then
  die "SERVED_MODEL_NAME=$SERVED_MODEL_NAME differs from the profile ($PROFILE_SERVED). Unset it."
fi
if [[ -n "${GPU_MEMORY_UTILIZATION:-}" ]] && ! awk -v a="$GPU_MEMORY_UTILIZATION" -v b="$PROFILE_MEM" 'BEGIN { exit !(b != "" && a + 0 == b + 0) }'; then
  die "GPU_MEMORY_UTILIZATION=$GPU_MEMORY_UTILIZATION differs from tier $TIER (${PROFILE_MEM:-unset}). Unset it; the profile sets it."
fi
if [[ -n "${MAX_MODEL_LEN:-}" && "$MAX_MODEL_LEN" != "$PROFILE_LEN" ]]; then
  die "MAX_MODEL_LEN=$MAX_MODEL_LEN differs from tier $TIER ($PROFILE_LEN). Unset it; the profile sets it."
fi

# Existing container. The bind defaults to 0.0.0.0 so the grader can reach it.
EXISTING=0
if command -v docker >/dev/null 2>&1 && docker container inspect "$CONTAINER" >/dev/null 2>&1; then
  EXISTING=1
fi
if [[ -n "${BIND:-}" ]]; then
  BIND_SOURCE="BIND environment variable"
else
  BIND="0.0.0.0"
  BIND_SOURCE="grader-facing default (the public IP cannot reach a loopback bind)"
fi
case "$BIND" in
  0.0.0.0|127.0.0.1) ;;
  *) die "Bind '$BIND' ($BIND_SOURCE) must be 0.0.0.0 or 127.0.0.1." ;;
esac

DOCKER_CMD=(
  docker run -d
  --name "$CONTAINER"
  --restart unless-stopped
  --gpus all
  --ipc=host
  -p "${BIND}:${PORT}:8000"
  -v "$HOME/.cache/huggingface:/root/.cache/huggingface"
  --label "greenmind.run=$RUN_NAME"
  --label "greenmind.tier=$TIER"
  --label "greenmind.bind=$BIND"
  "$IMAGE"
  "${VLLM_ARGS[@]}"
)

echo "Run:       $RUN_NAME"
echo "Profile:    $PROFILE_FILE"
echo "Container:  $CONTAINER"
echo "Bind:       ${BIND}:${PORT} -> container 8000 ($BIND_SOURCE)"
echo "Endpoint:   $BASE_URL"
echo "Image:      $IMAGE"
if [[ -n "$POWER_W" ]]; then echo "Power:      ${POWER_W} W"; else echo "Power:      card default"; fi
echo "Command:"
printf '  %q' "${DOCKER_CMD[@]}"
printf '\n'

if [[ "${DRY_RUN:-}" == "1" ]]; then
  echo "DRY_RUN=1: nothing started."
  exit 0
fi

command -v docker >/dev/null 2>&1 || die "docker is not on PATH."
command -v curl >/dev/null 2>&1 || die "curl is not on PATH."
docker info >/dev/null 2>&1 || die "Cannot talk to the Docker daemon."

if (( EXISTING )) && [[ "${REPLACE:-}" != "1" ]]; then
  echo "Container '$CONTAINER' already exists." >&2
  echo "Inspect it with: docker logs --tail 100 $CONTAINER" >&2
  echo "Remove it deliberately (docker rm -f $CONTAINER), or re-run with REPLACE=1 to save its record first." >&2
  exit 1
fi

STAMP="$(date +%Y%m%d-%H%M%S)"
RUN_DIR="$RUNS_DIR/${STAMP}_${RUN_NAME}"
mkdir -p "$RUN_DIR"
cp "$PROFILE_FILE" "$RUN_DIR/profile.args"
printf '%q ' "${DOCKER_CMD[@]}" > "$RUN_DIR/command.txt"
echo >> "$RUN_DIR/command.txt"

if (( EXISTING )); then
  echo "Saving the previous container's record to $RUN_DIR/previous-*"
  docker inspect "$CONTAINER" > "$RUN_DIR/previous-inspect.json" 2>&1 || true
  docker logs "$CONTAINER" > "$RUN_DIR/previous-container.log" 2>&1 || true
  docker rm -f "$CONTAINER" >/dev/null
fi

others="$(docker ps --format '{{.Names}}|{{.Ports}}' | awk -F'|' -v p=":${PORT}->" 'index($2, p) { print $1 }')"
[[ -z "$others" ]] || die "Another container publishes host port $PORT: $others. Stop it first."
if command -v nvidia-smi >/dev/null 2>&1; then
  apps=""
  for _ in $(seq 1 15); do
    apps="$(nvidia-smi --query-compute-apps=pid,process_name --format=csv,noheader 2>/dev/null || true)"
    [[ -z "$apps" ]] && break
    sleep 2
  done
  [[ -z "$apps" ]] || die "The GPU is still busy after 30 s. One serving process only: $(tr '\n' ';' <<< "$apps")"

  plq() { nvidia-smi -i 0 --query-gpu="$1" --format=csv,noheader,nounits | tr -d ' \r' | cut -d. -f1; }
  default_w="$(plq power.default_limit)"
  current_w="$(plq power.limit)"
  target_w="${POWER_W:-$default_w}"
  [[ "$target_w" =~ ^[0-9]+$ ]] || die "GREENMIND_POWER_W must be whole watts, got '$target_w'."
  (( target_w >= $(plq power.min_limit) && target_w <= $(plq power.max_limit) )) \
    || die "$target_w W is outside this card's power range."
  if [[ "$current_w" != "$target_w" ]]; then
    echo "Power limit: $current_w W -> $target_w W"
    [[ "$target_w" == "$default_w" ]] || sudo nvidia-smi -i 0 -pm 1 >/dev/null
    sudo nvidia-smi -i 0 -pl "$target_w" >/dev/null || die "Could not set the power limit to $target_w W."
  fi
  echo "Power limit: $(plq power.limit) W (card default $default_w W)"
fi

mkdir -p "$HOME/.cache/huggingface"
"${DOCKER_CMD[@]}" > "$RUN_DIR/container-id.txt"
ln -sfn "$RUN_DIR" "$RUNS_DIR/latest"

{
  echo "tier: $TIER"
  echo "started: $(date -Is)"
  echo "host: $(hostname)"
  echo "bind: ${BIND}:${PORT} ($BIND_SOURCE)"
  echo "git: $(git -C "$REPO_DIR" rev-parse --short HEAD 2>/dev/null || echo unknown)$( [[ -n "$(git -C "$REPO_DIR" status --porcelain 2>/dev/null)" ]] && echo ' (dirty)')"
  echo "image: $IMAGE"
  echo "image_id: $(docker inspect -f '{{.Image}}' "$CONTAINER" 2>/dev/null || echo unknown)"
  echo "repo_digests: $(docker image inspect -f '{{json .RepoDigests}}' "$IMAGE" 2>/dev/null || echo unknown)"
  if command -v nvidia-smi >/dev/null 2>&1; then
    echo "gpu: $(nvidia-smi --query-gpu=name,driver_version,power.limit,power.default_limit --format=csv,noheader 2>/dev/null || echo unknown)"
  fi
} > "$RUN_DIR/environment.txt"

echo
echo "Started $CONTAINER. Record: $RUN_DIR"
echo "Waiting up to ${WAIT_SECONDS}s for $BASE_URL/models ..."

deadline=$(( $(date +%s) + WAIT_SECONDS ))
ready=0
state="unknown"
restarts="0"
while (( $(date +%s) < deadline )); do
  state="$(docker inspect -f '{{.State.Status}}' "$CONTAINER" 2>/dev/null || echo missing)"
  restarts="$(docker inspect -f '{{.RestartCount}}' "$CONTAINER" 2>/dev/null || echo 0)"
  if [[ "$state" != "running" && "$state" != "restarting" ]] || (( restarts > 0 )); then
    break
  fi
  if curl -fsS --max-time 5 "$BASE_URL/models" >/dev/null 2>&1; then
    ready=1
    break
  fi
  sleep 5
done

docker logs "$CONTAINER" > "$RUN_DIR/startup.log" 2>&1 || true
echo "vllm_version: $(docker exec "$CONTAINER" python3 -c 'import vllm; print(vllm.__version__)' 2>/dev/null || echo unknown)" >> "$RUN_DIR/environment.txt"

echo
echo "--- Startup facts (from $RUN_DIR/startup.log) ---"
grep -Ei 'maximum concurrency|max_num_batched_tokens|max_num_seqs|long.prefill|partial.prefill|chunked prefill|prefix caching|mamba_cache_mode|mamba.shared|speculative|num_speculative_tokens|mtp|cuda ?graph|kv cache|out of memory|error|traceback' \
  "$RUN_DIR/startup.log" | tail -40 || echo "(no matching lines)"

if (( ready == 0 )); then
  echo
  echo "[FAIL] Server did not become ready (state: ${state:-unknown}, restarts: ${restarts:-?})."
  echo "Last 60 log lines:"
  tail -60 "$RUN_DIR/startup.log" || true
  echo
  echo "NOT READY. Do not benchmark. Stop it with: docker rm -f $CONTAINER"
  echo "The previous container's record is under $RUN_DIR/previous-*."
  exit 1
fi

echo
echo "[PASS] $BASE_URL/models answered."
if [[ "${SKIP_PREFLIGHT:-}" == "1" ]]; then
  echo "SKIP_PREFLIGHT=1: run PROFILE=$PROFILE_FILE $HERE/preflight.sh before any benchmark."
  exit 0
fi

echo "Running the preflight with the same profile ..."
pf_rc=0
PROFILE="$PROFILE_FILE" EXPECTED_BIND="$BIND" CONTAINER="$CONTAINER" HOST_PORT="$PORT" \
  BASE_URL="$BASE_URL" MODEL_ID="$PROFILE_SERVED" PREFLIGHT_LOG_DIR="$RUN_DIR/preflight" \
  "$HERE/preflight.sh" || pf_rc=$?

echo
if (( pf_rc == 0 )); then
  echo "READY: $RUN_NAME passed the preflight. Record: $RUN_DIR"
  echo "Before Submit: python3 $HERE/warmup.py, then $HERE/watch.sh in a second shell (Validation only)."
  exit 0
fi
echo "NOT READY: preflight failed for $RUN_NAME. Do not benchmark."
echo "Put the previous server back from its own folder. Do not change this profile to match a failed launch."
exit 1
