#!/usr/bin/env bash
# final-d-active-seqs-80: Gate 0 + running-admission cap 80.
set -Eeuo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
export EXPERIMENT_ID="final-d-active-seqs-80"
exec "$REPO/experiments/lib/entry.sh" "$HERE/profile.args" "$@"
