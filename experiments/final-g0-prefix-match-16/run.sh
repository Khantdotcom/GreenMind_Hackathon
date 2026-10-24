#!/usr/bin/env bash
# final-g0-prefix-match-16: Gate 0 + prefix-match unit 16. Does not call lib/start.sh or final-run3/start.sh.
set -Eeuo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
export EXPERIMENT_ID="final-g0-prefix-match-16"
exec "$REPO/experiments/lib/entry.sh" "$HERE/profile.args" "$@"
