#!/usr/bin/env bash
# Reference baseline. Prints Final constants and checks the score formula.
# Does not start mango-vllm and does not request the public grader URL.
set -Eeuo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
# shellcheck disable=SC1091
source "$REPO/experiments/defaults.env"

MODE="print"
if [[ $# -gt 1 ]]; then
  echo "Usage: $0 [--print|--record]" >&2
  exit 2
fi
if [[ $# -eq 1 ]]; then
  case "$1" in
    --print) MODE="print" ;;
    --record) MODE="record" ;;
    --launch|--check)
      echo "[REFUSE] The reference baseline does not start ${CONTAINER_NAME} and has no server flags to check." >&2
      exit 1
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 2
      ;;
  esac
fi

python3 "$REPO/experiments/lib/score.py" --check-formula

cat <<EOF
Experiment: 03-reference-baseline
Role:       published Final BF16 constants. This directory does not serve.
Image pin:  ${VLLM_IMAGE_PIN}
Container:  ${CONTAINER_NAME}
Bind:       ${BIND}:${PORT}
Local:      ${LOCAL_BASE_URL}
Public:     ${PUBLIC_BASE_URL}
Weights:    ${MODEL_ID} (launch profiles only; the BF16 baseline is not this checkpoint)
Served:     ${SERVED_MODEL_NAME}
eta_base:   ${ETA_BASE}
K:          ${ENERGY_K}
macro:      ${REF_MACRO}
TTFT SLO:   ${TTFT_SLO_BASE_S}s + ${TTFT_SLO_PER_1K_S}s per 1k input tokens
TPOT SLO:   ${TPOT_SLO_S}s
Formula:    python3 experiments/lib/score.py --check-formula
EOF

if [[ "$MODE" == "print" ]]; then
  echo "PRINT ONLY. Pass --record to write a local environment note. Nothing was started."
  exit 0
fi

STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
OUT="${HERE}/environment-${STAMP}.txt"
{
  echo "recorded: ${STAMP}"
  echo "host: $(hostname)"
  echo "image_pin: ${VLLM_IMAGE_PIN}"
  echo "container_name: ${CONTAINER_NAME}"
  echo "bind: ${BIND}:${PORT}"
  echo "public_base: ${PUBLIC_BASE_URL}"
  echo "eta_base: ${ETA_BASE}"
  echo "reference_macro: ${REF_MACRO}"
  echo "git: $(git -C "$REPO" rev-parse --short HEAD 2>/dev/null || echo unknown)"
  echo
  echo "---- nvidia-smi (read only) ----"
  if command -v nvidia-smi >/dev/null 2>&1; then
    nvidia-smi --query-gpu=name,driver_version,memory.total,power.default_limit --format=csv || true
  else
    echo "nvidia-smi not on PATH"
  fi
  echo
  echo "---- docker image inspect (no pull, no run) ----"
  if command -v docker >/dev/null 2>&1; then
    docker image inspect "$VLLM_IMAGE_PIN" --format 'id={{.Id}} digests={{json .RepoDigests}}' 2>&1 || echo "image not present locally"
  else
    echo "docker not on PATH"
  fi
} > "$OUT"
echo "Wrote ${OUT}"
