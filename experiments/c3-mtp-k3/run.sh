#!/usr/bin/env bash
# c3-mtp-k3: original entry. Does not call lib/start.sh or final-run3/start.sh.
set -Eeuo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
export EXPERIMENT_ID="c3-mtp-k3"
exec "$REPO/experiments/lib/entry.sh" "$HERE/profile.args" "$@"
