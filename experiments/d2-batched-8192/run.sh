#!/usr/bin/env bash
# d2-batched-8192: original entry. Does not call lib/start.sh or final-run3/start.sh.
set -Eeuo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
export EXPERIMENT_ID="d2-batched-8192"
exec "$REPO/experiments/lib/entry.sh" "$HERE/profile.args" "$@"
