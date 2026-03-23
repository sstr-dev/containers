#!/usr/bin/env bash
set -Eeuo pipefail

if [[ "${VALIDATE_ON_START:-TRUE}" != "FALSE" ]]; then
    # shellcheck disable=SC1091
    source /env.sh >/dev/null
fi

if [[ "${BACKUP_ON_START:-FALSE}" == "TRUE" && "${1:-}" != "/backup.sh" ]]; then
    /backup.sh
fi

exec "$@"
