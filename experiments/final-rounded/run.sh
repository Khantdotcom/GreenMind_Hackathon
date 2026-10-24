#!/usr/bin/env bash
# final-rounded: Gate 0 + active-seqs 80 + BF16 Mamba state + finer prefix match.
set -Eeuo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
export EXPERIMENT_ID="final-rounded"
exec "$REPO/experiments/lib/entry.sh" "$HERE/profile.args" "$@"
