#!/usr/bin/env bash
# c-isolate-mtp-cache: failure-mode entry. Does not call lib/start.sh.
set -Eeuo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
export EXPERIMENT_ID="c-isolate-mtp-cache"
exec "$REPO/experiments/lib/entry.sh" "$HERE/profile.args" "$@"
