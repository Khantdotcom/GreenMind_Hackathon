#!/usr/bin/env bash
# Check that every flag in a profile exists in the vLLM image, before launching
# it. Uses a throwaway container that only prints the help text, so the current
# server keeps running. Do not run it during a graded window.
#
#   ./lib/flag-check.sh run5/profile.args
#   VLLM_IMAGE=vllm/vllm-openai@sha256:<digest> ./lib/flag-check.sh run5/profile.args
set -Eeuo pipefail

IMAGE="${VLLM_IMAGE:-vllm/vllm-openai:nightly}"
PROFILE_FILE="${1:-${GREENMIND_PROFILE:-}}"
[[ -n "$PROFILE_FILE" && -f "$PROFILE_FILE" ]] || { echo "Usage: $0 path/to/profile.args" >&2; exit 2; }

echo "Image:   $IMAGE"
echo "Profile: $PROFILE_FILE"
echo "vLLM:    $(docker run --rm --entrypoint python3 "$IMAGE" -c 'import vllm; print(vllm.__version__)' 2>/dev/null || echo unknown)"

help_text="$(docker run --rm --entrypoint vllm "$IMAGE" serve --help=all 2>/dev/null || true)"
if [[ -z "$help_text" ]]; then
  # Without a GPU this image stops at "Failed to infer device type". With the GPU
  # attached, --help only reads the device type: no CUDA context, no memory used.
  help_text="$(docker run --rm --gpus all --entrypoint vllm "$IMAGE" serve --help=all 2>/dev/null || true)"
fi
if [[ -z "$help_text" ]]; then
  # The running server is the same image when the IDs match, so ask it instead.
  CONTAINER="${CONTAINER_NAME:-mango-vllm}"
  want_id="$(docker image inspect -f '{{.Id}}' "$IMAGE" 2>/dev/null || true)"
  have_id="$(docker inspect -f '{{.Image}}' "$CONTAINER" 2>/dev/null || true)"
  if [[ -n "$want_id" && "$want_id" == "$have_id" ]]; then
    echo "Help:    read from running container $CONTAINER (same image ${want_id:7:12})"
    help_text="$(docker exec "$CONTAINER" vllm serve --help=all 2>/dev/null || true)"
  fi
fi
if [[ -z "$help_text" ]]; then
  echo "[FAIL] Could not read 'vllm serve --help' from $IMAGE"
  exit 1
fi

fail=0
while IFS= read -r line || [[ -n "$line" ]]; do
  line="${line//$'\r'/}"
  [[ "$line" == --* ]] || continue
  flag="${line%%[[:space:]]*}"
  value="${line#"$flag"}"
  value="${value#"${value%%[![:space:]]*}"}"
  if grep -qE -- "${flag}([^a-z0-9-]|\$)" <<< "$help_text"; then
    echo "[PASS] $flag"
  else
    echo "[FAIL] $flag is not in this image's vllm serve --help"
    fail=1
    continue
  fi
  case "$flag" in
    --mamba-cache-mode)
      if grep -A6 -E -- "--mamba-cache-mode" <<< "$help_text" | grep -q "$value"; then
        echo "       '$value' appears in its help text"
      else
        echo "[WARN] '$value' is not listed in the help for $flag; check the startup log"
      fi
      ;;
  esac
done < "$PROFILE_FILE"

if (( fail )); then
  echo "RESULT: FLAG CHECK FAILED. Do not launch this tier on this image."
  exit 1
fi
echo "RESULT: FLAG CHECK PASSED. The MTP method and hybrid prefix caching are only proven by the startup log."
