#!/usr/bin/env bash

# Pre-validate the environment
if [ "${DB_NAMES}" = "**None**" -a "${DB_NAMES_FILE}" = "**None**" ]; then
  echo "You need to set the DB_NAMES or DB_NAMES_FILE environment variable."
  exit 1
fi

if [ "${DB_NAMES_FILE}" = "**None**" ]; then
  DBS=$(echo "${DB_NAMES}" | tr , " ")
elif [ -r "${DB_NAMES_FILE}" ]; then
  DBS=$(cat "${DB_NAMES_FILE}")
else
  echo "Missing DB_NAMES_FILE file."
  exit 1
fi

export DB_TYPE="${DB_TYPE:-postgres}"
export BACKUP_DIR="${BACKUP_DIR:-/backups}"
export BACKUP_SUFFIX="${BACKUP_SUFFIX:-.sql.gz}"
export BACKUP_KEEP_MINS="${BACKUP_KEEP_MINS:-1440}"
export BACKUP_KEEP_DAYS="${BACKUP_KEEP_DAYS:-7}"
export BACKUP_KEEP_WEEKS="${BACKUP_KEEP_WEEKS:-4}"
export BACKUP_KEEP_MONTHS="${BACKUP_KEEP_MONTHS:-6}"
export BACKUP_LATEST_TYPE="${BACKUP_LATEST_TYPE:-symlink}"

resolve_first_nonempty() {
    local value
    for value in "$@"; do
        if [[ -n "${value}" && "${value}" != "**None**" ]]; then
            printf '%s' "${value}"
            return 0
        fi
    done
    return 1
}
require_value() {
    local name="$1"
    local value="$2"
    if [[ -z "${value}" ]]; then
        echo "Missing required setting: ${name}" >&2
        exit 1
    fi
}
read_first_line() {
    local file_path="$1"
    [[ -r "${file_path}" ]] || return 1
    IFS= read -r line < "${file_path}" || true
    printf '%s' "${line}"
}


if [ "${DB_TYPE}" = "postgres" ]; then
    export DB_HOST="$({ resolve_first_nonempty "${DB_HOST:-}" "${POSTGRES_HOST:-}" "${POSTGRES_PORT_5432_TCP_ADDR:-}"; } || true)"
    export DB_PORT="$({ resolve_first_nonempty "${DB_PORT:-}" "${POSTGRES_PORT:-}" "${POSTGRES_PORT_5432_TCP_PORT:-5432}"; } || true)"
    export DB_USER="$({ resolve_first_nonempty "${DB_USER:-}" "${POSTGRES_USER:-}"; } || true)"

    if [[ -z "${DB_USER}" && -n "${POSTGRES_USER_FILE:-}" && "${POSTGRES_USER_FILE}" != "**None**" ]]; then
        export DB_USER="$(read_first_line "${POSTGRES_USER_FILE}")"
    fi

    export DB_PASSWORD="$({ resolve_first_nonempty "${DB_PASSWORD:-}" "${POSTGRES_PASSWORD:-}"; } || true)"
    export DB_EXTRA_OPTS="$({ resolve_first_nonempty "${DB_EXTRA_OPTS:-}" "${POSTGRES_EXTRA_OPTS:-}"; } || true)"

    if [[ -z "${DB_PASSWORD}" && -n "${POSTGRES_PASSWORD_FILE:-}" && "${POSTGRES_PASSWORD_FILE}" != "**None**" ]]; then
        export DB_PASSWORD="$(read_first_line "${POSTGRES_PASSWORD_FILE}")"
    fi

    require_value "DB_HOST/POSTGRES_HOST" "${DB_HOST}"
    require_value "DB_PORT/POSTGRES_PORT" "${DB_PORT}"
    require_value "DB_USER/POSTGRES_USER" "${DB_USER}"

    if [[ -z "${DB_PASSWORD}" && "${POSTGRES_PASSFILE_STORE:-**None**}" == "**None**" ]]; then
        echo "Missing required setting: DB_PASSWORD/POSTGRES_PASSWORD or POSTGRES_PASSFILE_STORE" >&2
        exit 1
    fi

    export PGHOST="${DB_HOST}"
    export PGPORT="${DB_PORT}"
    export PGUSER="${DB_USER}"

    if [[ -n "${DB_PASSWORD}" ]]; then
        export PGPASSWORD="${DB_PASSWORD}"
    fi

fi
if [ "${DB_TYPE}" = "mariadb" ]; then
    export DB_HOST="$({ resolve_first_nonempty "${DB_HOST:-}" "${MARIADB_HOST:-}" "${MYSQL_HOST:-}"; } || true)"
    export DB_PORT="$({ resolve_first_nonempty "${DB_PORT:-}" "${MARIADB_PORT:-}" "${MYSQL_PORT:-3306}"; } || true)"
    export DB_USER="$({ resolve_first_nonempty "${DB_USER:-}" "${MARIADB_USER:-}" "${MYSQL_USER:-}"; } || true)"

    if [[ -z "${DB_USER}" && -n "${MARIADB_USER_FILE:-}" && "${MARIADB_USER_FILE}" != "**None**" ]]; then
        export DB_USER="$(read_first_line "${MARIADB_USER_FILE}")"
    elif [[ -z "${DB_USER}" && -n "${MYSQL_USER_FILE:-}" && "${MYSQL_USER_FILE}" != "**None**" ]]; then
        export DB_USER="$(read_first_line "${MYSQL_USER_FILE}")"
    fi

    export DB_PASSWORD="$({ resolve_first_nonempty "${DB_PASSWORD:-}" "${MARIADB_PASSWORD:-}" "${MYSQL_PASSWORD:-}"; } || true)"
    export DB_EXTRA_OPTS="$({ resolve_first_nonempty "${DB_EXTRA_OPTS:-}" "${MARIADB_EXTRA_OPTS:-}" "${MYSQL_EXTRA_OPTS:-}"; } || true)"

    if [[ -z "${DB_PASSWORD}" && -n "${MARIADB_PASSWORD_FILE:-}" && "${MARIADB_PASSWORD_FILE}" != "**None**" ]]; then
        export DB_PASSWORD="$(read_first_line "${MARIADB_PASSWORD_FILE}")"
    elif [[ -z "${DB_PASSWORD}" && -n "${MYSQL_PASSWORD_FILE:-}" && "${MYSQL_PASSWORD_FILE}" != "**None**" ]]; then
        export DB_PASSWORD="$(read_first_line "${MYSQL_PASSWORD_FILE}")"
    fi
    require_value "DB_HOST/MARIADB_HOST/MYSQL_HOST" "${DB_HOST}"
    require_value "DB_PORT/MARIADB_PORT/MYSQL_PORT" "${DB_PORT}"
    require_value "DB_USER/MARIADB_USER/MYSQL_USER" "${DB_USER}"
    require_value "DB_PASSWORD/MARIADB_PASSWORD/MYSQL_PASSWORD" "${DB_PASSWORD}"

    export MYSQL_HOST="${DB_HOST}"
    export MYSQL_TCP_PORT="${DB_PORT}"
    export MYSQL_USER="${DB_USER}"
    export MYSQL_PWD="${DB_PASSWORD}"
fi

KEEP_MINS=${BACKUP_KEEP_MINS}
KEEP_DAYS=${BACKUP_KEEP_DAYS}
KEEP_WEEKS=`expr $(((${BACKUP_KEEP_WEEKS} * 7) + 1))`
KEEP_MONTHS=`expr $(((${BACKUP_KEEP_MONTHS} * 31) + 1))`

# Validate backup dir
if [ '!' -d "${BACKUP_DIR}" -o '!' -w "${BACKUP_DIR}" -o '!' -x "${BACKUP_DIR}" ]; then
  echo "BACKUP_DIR points to a file or folder with insufficient permissions."
  exit 1
fi

