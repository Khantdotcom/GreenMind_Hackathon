#!/usr/bin/env bash
# final-sa-active-96: Stage A active-seqs=96, runner max-num-seqs=128.
set -Eeuo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
export EXPERIMENT_ID="final-sa-active-96"
exec "$REPO/experiments/lib/entry.sh" "$HERE/profile.args" "$@"
