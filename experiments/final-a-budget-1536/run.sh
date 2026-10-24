#!/usr/bin/env bash
# final-a-budget-1536: Gate 0 + budget 1536. Does not call lib/start.sh or final-run3/start.sh.
set -Eeuo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
export EXPERIMENT_ID="final-a-budget-1536"
exec "$REPO/experiments/lib/entry.sh" "$HERE/profile.args" "$@"
