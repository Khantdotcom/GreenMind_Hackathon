#!/usr/bin/env bash
# final-b-budget-3072: Gate 0 + budget 3072. Does not call lib/start.sh or final-run3/start.sh.
set -Eeuo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
export EXPERIMENT_ID="final-b-budget-3072"
exec "$REPO/experiments/lib/entry.sh" "$HERE/profile.args" "$@"
