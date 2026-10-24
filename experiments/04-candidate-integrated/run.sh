#!/usr/bin/env bash
# Section 4 integrated command. Prints the decomposition and does not launch.
set -Eeuo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
# shellcheck disable=SC1091
source "$REPO/experiments/defaults.env"

if [[ $# -gt 0 ]]; then
  case "$1" in
    --launch|--check)
      echo "[REFUSE] The section 4 command is not launched. It pairs MTP with prefix caching and leaves the graded served name." >&2
      echo "Use experiments/c-isolate-mtp-cache to reproduce that failure, and the single-factor arms for everything else." >&2
      exit 1
      ;;
    --print) ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 2
      ;;
  esac
fi

cat <<EOF
Experiment: 04-candidate-integrated
Role:       decomposition of the section 4 command. Nothing is started.
Image pin:  ${VLLM_IMAGE_PIN}
Container:  ${CONTAINER_NAME} (not started)
Bind:       ${BIND}:${PORT}
Local:      ${LOCAL_BASE_URL}
Public:     ${PUBLIC_BASE_URL}
Graded weights: ${MODEL_ID}
Graded served name: ${SERVED_MODEL_NAME}

plan-command.args is a citation. It is not passed to vLLM.
  served name in the plan: mango-awq-mtp -> kept as ${SERVED_MODEL_NAME}
  gpu memory in the plan: 0.92 -> kept as 0.90
  FLASHINFER -> omitted
  prefix caching -> b-apc-on, then D, E, final-combined
  batched tokens 8192 -> frozen in A-C, swept in D
  max-num-seqs 32 -> frozen in A-D, swept in E, omitted from final-combined
  MTP k=3 -> c3-mtp-k3 with prefix caching off
  MTP with prefix caching -> c-isolate-mtp-cache at k=1 only
EOF
