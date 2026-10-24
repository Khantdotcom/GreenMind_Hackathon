#!/usr/bin/env bash
set -Eeuo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PROFILE="${PROFILE:-$HERE/profile.args}"
exec "$HERE/../lib/preflight.sh" "$@"
