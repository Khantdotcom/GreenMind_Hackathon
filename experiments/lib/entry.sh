#!/usr/bin/env bash
# Original experiment runner.
# Calls lib/flag-check.sh. Does not call lib/start.sh, final-run3/start.sh,
# or final-run3/preflight.sh, and does not request the public grader URL.
set -Eeuo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: entry.sh profile.args [--print|--check|--launch] [--isolate-failure]" >&2
  exit 2
fi

PROFILE="$1"
shift
MODE="print"
MODE_FLAGS=0
ISOLATE_ARG=0
for arg in "$@"; do
  case "$arg" in
    --print|--check|--launch)
      MODE="${arg#--}"
      MODE_FLAGS=$((MODE_FLAGS + 1))
      ;;
    --isolate-failure) ISOLATE_ARG=1 ;;
    *)
      echo "Unknown argument: $arg" >&2
      exit 2
      ;;
  esac
done
if (( MODE_FLAGS > 1 )); then
  echo "Pass only one of --print, --check, or --launch." >&2
  exit 2
fi

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$LIB_DIR/../.." && pwd)"
# shellcheck disable=SC1091
source "$REPO/experiments/defaults.env"

[[ -f "$PROFILE" ]] || { echo "Profile not found: $PROFILE" >&2; exit 2; }
EXP_ID="${EXPERIMENT_ID:-$(basename "$(dirname "$PROFILE")")}"
WAIT_SECONDS="${WAIT_SECONDS:-900}"

mapfile -t TOKENS < <(python3 "$LIB_DIR/parse_profile.py" --check-contract "$PROFILE")

has_apc=0
spec_json=""
prev=""
for token in "${TOKENS[@]}"; do
  [[ "$token" == "--enable-prefix-caching" ]] && has_apc=1
  if [[ "$prev" == "--speculative-config" ]]; then
    spec_json="$token"
  fi
  prev="$token"
done

spec_method=""
if [[ -n "$spec_json" ]]; then
  spec_method="$(python3 -c 'import json,sys; print(json.loads(sys.argv[1]).get("method",""))' "$spec_json")"
fi

if [[ "$spec_method" == "mtp" && "$has_apc" == "1" ]]; then
  if [[ "$EXP_ID" != "c-isolate-mtp-cache" ]]; then
    echo "[REFUSE] ${EXP_ID} enables MTP and prefix caching." >&2
    echo "Measured runs lost cache hits and the Final energy cliff with that pair." >&2
    echo "The only profile allowed to pair them is experiments/c-isolate-mtp-cache." >&2
    echo "N-gram/suffix speculation with APC is allowed; MTP+APC is not (except isolation)." >&2
    exit 1
  fi
  echo "ISOLATION: MTP plus prefix caching. This reproduces a measured failure. It is not a candidate."
  if [[ "$MODE" == "launch" && "$ISOLATE_ARG" != "1" ]]; then
    echo "[REFUSE] Launching the isolation profile requires --launch --isolate-failure." >&2
    exit 1
  fi
elif [[ "$ISOLATE_ARG" == "1" ]]; then
  echo "[REFUSE] --isolate-failure is only valid for experiments/c-isolate-mtp-cache." >&2
  exit 1
fi

if [[ -n "${GREENMIND_POWER_W:-}" ]]; then
  echo "[REFUSE] GREENMIND_POWER_W=${GREENMIND_POWER_W} is set." >&2
  echo "This suite leaves the card at its default power. Unset GREENMIND_POWER_W." >&2
  echo "A power cap combined with MTP lost the Final energy cliff, and no capped Final has cleared it." >&2
  exit 1
fi

if [[ "$VLLM_IMAGE" != "$VLLM_IMAGE_PIN" ]]; then
  echo "[REFUSE] VLLM_IMAGE=${VLLM_IMAGE}" >&2
  echo "This suite requires the graded digest ${VLLM_IMAGE_PIN}." >&2
  exit 1
fi

DOCKER=(
  docker run -d
  --name "$CONTAINER_NAME"
  --restart unless-stopped
  --gpus all
  --ipc=host
  -p "${BIND}:${PORT}:8000"
  -v "${HOME}/.cache/huggingface:/root/.cache/huggingface"
  --label "greenmind.run=${EXP_ID}"
  --label "greenmind.tier=${EXP_ID}"
  --label "greenmind.bind=${BIND}"
  "$VLLM_IMAGE"
)
DOCKER+=("${TOKENS[@]}")

print_plan() {
  cat <<EOF
Experiment: ${EXP_ID}
Image:      ${VLLM_IMAGE}
Container:  ${CONTAINER_NAME}
Bind:       ${BIND}:${PORT} -> container 8000
Local:      ${LOCAL_BASE_URL}
Public:     ${PUBLIC_BASE_URL}
Served:     ${SERVED_MODEL_NAME}
Weights:    ${MODEL_ID}
Power:      card default (GREENMIND_POWER_W unset)
Profile:    ${PROFILE}
Launch:     reuse name ${CONTAINER_NAME} (replace in place if it exists); one server on :${PORT}; wait on ${LOCAL_BASE_URL}/models (never ${PUBLIC_BASE_URL})

The public URL is the Team 17 grader endpoint. This script never requests it.
After local ready, point the grader at ${PUBLIC_BASE_URL} yourself. Final allows 2 submissions/hour — one experiment at a time.

Flag check (throwaway help container, not ${CONTAINER_NAME}):
  VLLM_IMAGE=${VLLM_IMAGE} ${REPO}/lib/flag-check.sh ${PROFILE}

Server command (not started):
EOF
  printf ' '
  printf ' %q' "${DOCKER[@]}"
  printf '\n'
}

wait_local_ready() {
  local deadline state restarts ready=0
  command -v curl >/dev/null 2>&1 || { echo "curl is not on PATH." >&2; exit 1; }
  echo "Waiting up to ${WAIT_SECONDS}s for ${LOCAL_BASE_URL}/models ..."
  deadline=$(( $(date +%s) + WAIT_SECONDS ))
  while (( $(date +%s) < deadline )); do
    state="$(docker inspect -f '{{.State.Status}}' "$CONTAINER_NAME" 2>/dev/null || echo missing)"
    restarts="$(docker inspect -f '{{.RestartCount}}' "$CONTAINER_NAME" 2>/dev/null || echo 0)"
    if [[ "$state" != "running" && "$state" != "restarting" ]] || (( restarts > 0 )); then
      break
    fi
    if curl -fsS --max-time 5 "${LOCAL_BASE_URL}/models" >/dev/null 2>&1; then
      ready=1
      break
    fi
    sleep 5
  done
  if (( ready == 0 )); then
    echo "[FAIL] Server did not become ready (state: ${state:-unknown}, restarts: ${restarts:-?})." >&2
    echo "Last 60 log lines:" >&2
    docker logs --tail 60 "$CONTAINER_NAME" 2>&1 || true
    echo "NOT READY for the grader. Do not Submit yet." >&2
    exit 1
  fi
  echo "[PASS] ${LOCAL_BASE_URL}/models answered."

  # Grader health hits Chat. Probe localhost only; never the public URL.
  if curl -fsS --max-time 60 "${LOCAL_BASE_URL}/chat/completions" \
    -H 'Content-Type: application/json' \
    -d "{\"model\":\"${SERVED_MODEL_NAME}\",\"messages\":[{\"role\":\"user\",\"content\":\"ping\"}],\"max_tokens\":1,\"temperature\":0,\"stream\":false}" \
    >/dev/null 2>&1; then
    echo "[PASS] local chat/completions answered. Grader Chat health can use ${PUBLIC_BASE_URL}."
  else
    echo "[FAIL] local chat/completions did not answer. Grader Chat health will fail." >&2
    echo "Last 60 log lines:" >&2
    docker logs --tail 60 "$CONTAINER_NAME" 2>&1 || true
    exit 1
  fi
}

if [[ "$MODE" == "print" ]]; then
  print_plan
  echo "PRINT ONLY. Nothing was started."
  launch_args="--launch"
  if [[ "$EXP_ID" == "c-isolate-mtp-cache" ]]; then
    launch_args="--launch --isolate-failure"
  fi
  echo "Flag check:  ./experiments/${EXP_ID}/run.sh --check"
  echo "Launch:      GREENMIND_CONFIRM_LAUNCH=1 ./experiments/${EXP_ID}/run.sh ${launch_args}"
  exit 0
fi

if [[ "$MODE" == "launch" && "${GREENMIND_CONFIRM_LAUNCH:-}" != "1" ]]; then
  echo "[REFUSE] --launch requires GREENMIND_CONFIRM_LAUNCH=1. Nothing was started." >&2
  exit 1
fi

export VLLM_IMAGE CONTAINER_NAME
"$REPO/lib/flag-check.sh" "$PROFILE"

if [[ "$MODE" == "check" ]]; then
  exit 0
fi

command -v docker >/dev/null 2>&1 || { echo "docker is not on PATH." >&2; exit 1; }
docker info >/dev/null 2>&1 || { echo "Cannot talk to the Docker daemon." >&2; exit 1; }

# Same graded name every time: replace mango-vllm in place so only one experiment
# serves :8000 for the grader. Do not leave two servers up.
if docker container inspect "$CONTAINER_NAME" >/dev/null 2>&1; then
  echo "Replacing existing ${CONTAINER_NAME} with this experiment (${EXP_ID})."
  docker rm -f "$CONTAINER_NAME" >/dev/null
fi
others="$(docker ps --format '{{.Names}}|{{.Ports}}' | awk -F'|' -v p=":${PORT}->" 'index($2, p) { print $1 }')"
if [[ -n "$others" ]]; then
  echo "[REFUSE] Another container still publishes host port ${PORT}: ${others}" >&2
  echo "Stop that foreign container yourself. This runner only replaces ${CONTAINER_NAME}." >&2
  exit 1
fi

mkdir -p "${HOME}/.cache/huggingface"
"${DOCKER[@]}"
echo "Started ${CONTAINER_NAME} for ${EXP_ID} (only server on :${PORT})."
wait_local_ready
echo "Local ready. This script did not call ${PUBLIC_BASE_URL}."
echo "In the grader: Endpoint ${PUBLIC_BASE_URL}, model ${SERVED_MODEL_NAME}, Final only, Health check, then Submit."
echo "Final limit: 2 submissions/hour. Keep this container running until that Final finishes."
echo "Logs: docker logs -f ${CONTAINER_NAME}"
