#!/usr/bin/env bash
# final-c-mtp-default-apc: Gate 0 + MTP k=1, no explicit APC flags.
# Does not call lib/start.sh or final-run3/start.sh.
set -Eeuo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
export EXPERIMENT_ID="final-c-mtp-default-apc"
exec "$REPO/experiments/lib/entry.sh" "$HERE/profile.args" "$@"
