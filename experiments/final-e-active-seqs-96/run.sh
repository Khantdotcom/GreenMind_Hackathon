#!/usr/bin/env bash
# final-e-active-seqs-96: Gate 0 + running-admission cap 96.
set -Eeuo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
export EXPERIMENT_ID="final-e-active-seqs-96"
exec "$REPO/experiments/lib/entry.sh" "$HERE/profile.args" "$@"
