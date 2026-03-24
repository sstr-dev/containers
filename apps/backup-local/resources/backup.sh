#!/usr/bin/env bash
set -Eeuo pipefail

HOOKS_DIR="/hooks"
if [ -d "${HOOKS_DIR}" ]; then
    on_error(){
        run-parts -a "error" "${HOOKS_DIR}"
    }
    trap 'on_error' ERR
fi

source "$(dirname "$0")/env.sh"

# Pre-backup hook
if [ -d "${HOOKS_DIR}" ]; then
    run-parts -a "pre-backup" --exit-on-error "${HOOKS_DIR}"
fi

# Validate and extract DBS
DBS=""

if [[ -n "${DB_NAMES:-}" && "${DB_NAMES}" != "**None**" ]]; then
    DBS=$(echo "${DB_NAMES}" | tr ',' ' ')
elif [[ -n "${DB_NAMES_FILE:-}" && "${DB_NAMES_FILE}" != "**None**" ]]; then
    if [[ -r "${DB_NAMES_FILE}" ]]; then
        DBS=$(cat "${DB_NAMES_FILE}")
    else
        echo "DB_NAMES_FILE is set but not readable: ${DB_NAMES_FILE}" >&2
        exit 1
    fi
else
    if [ "${DB_TYPE}" = "postgres" ]; then
        EXCLUDE_DBS="template0 template1 postgres ${EXCLUDE_DBS:-}"
        DBS="$({
            psql -lqt |
            cut -d '|' -f 1 |
            sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
        } || true)"
    elif [ "${DB_TYPE}" = "mariadb" ]; then
        EXCLUDE_DBS="information_schema mysql performance_schema sys ${EXCLUDE_DBS:-}"
        DBS="$({
            mariadb --host="${DB_HOST}" --port="${DB_PORT}" --user="${DB_USER}" --password="${DB_PASSWORD}" --batch --skip-column-names -e "SHOW DATABASES"
        } || true)"
    fi

    if [[ -n "${DBS}" ]]; then
        IFS=' ' read -r -a EXCLUDE_ARRAY <<< "${EXCLUDE_DBS}"
        FILTERED_DBS=""
        while IFS= read -r dbname; do
            [[ -n "${dbname}" ]] || continue
            skip=false
            for exclude in "${EXCLUDE_ARRAY[@]}"; do
                if [[ "${dbname}" == "${exclude}" ]]; then
                    skip=true
                    break
                fi
            done
            if [[ "${skip}" == false ]]; then
                FILTERED_DBS+="${dbname} "
            fi
        done <<< "${DBS}"
        DBS="${FILTERED_DBS}"
    fi
fi

if [ -z "${DBS//[[:space:]]/}" ] || [ "${DBS}" = "**None**" ]; then
    echo "No databases found. Set DB_NAMES/DB_NAMES_FILE or adjust EXCLUDE_DBS." >&2
    exit 1
fi

# Initialize dirs
mkdir -p "${BACKUP_DIR}/last/" "${BACKUP_DIR}/daily/" "${BACKUP_DIR}/weekly/" "${BACKUP_DIR}/monthly/"


if [ "${DB_TYPE}" = "mariadb" ]; then
    if command -v mariadb-dump >/dev/null 2>&1; then
        MYSQL_DUMP_BIN="mariadb-dump"
    elif command -v mysqldump >/dev/null 2>&1; then
        MYSQL_DUMP_BIN="mysqldump"
    else
        echo "Neither mariadb-dump nor mysqldump was found in PATH." >&2
        exit 1
    fi
fi
#Loop all databases
for DB in ${DBS}; do
    #Initialize filename vers
    LAST_FILENAME="${DB}-`date +%Y%m%d-%H%M%S`${BACKUP_SUFFIX}"
    DAILY_FILENAME="${DB}-`date +%Y%m%d`${BACKUP_SUFFIX}"
    WEEKLY_FILENAME="${DB}-`date +%G%V`${BACKUP_SUFFIX}"
    MONTHY_FILENAME="${DB}-`date +%Y%m`${BACKUP_SUFFIX}"
    FILE="${BACKUP_DIR}/last/${LAST_FILENAME}"
    DFILE="${BACKUP_DIR}/daily/${DAILY_FILENAME}"
    WFILE="${BACKUP_DIR}/weekly/${WEEKLY_FILENAME}"
    MFILE="${BACKUP_DIR}/monthly/${MONTHY_FILENAME}"

    #Create dump
    if [ "${DB_TYPE}" = "postgres" ]; then
        echo "Creating dump of ${DB} database from ${DB_HOST}..."
        pg_dump -d "${DB}" -f "${FILE}" ${DB_EXTRA_OPTS}
    fi

    if [ "${DB_TYPE}" = "mariadb" ]; then
        echo "Creating dump of ${DB} database from ${DB_HOST}..."
        "${MYSQL_DUMP_BIN}" --host="${DB_HOST}" --port="${DB_PORT}" --user="${DB_USER}" --password="${DB_PASSWORD}" ${DB_EXTRA_OPTS} --databases "${DB}" | gzip > "${FILE}"
    fi

    #Copy (hardlink) for each entry
    if [ -d "${FILE}" ]; then
        DFILENEW="${DFILE}-new"
        WFILENEW="${WFILE}-new"
        MFILENEW="${MFILE}-new"
        rm -rf "${DFILENEW}" "${WFILENEW}" "${MFILENEW}"
        mkdir "${DFILENEW}" "${WFILENEW}" "${MFILENEW}"
        (
            # Allow to hardlink more files than max arg list length
            # first CHDIR to avoid possible space problems with BACKUP_DIR
            cd "${FILE}"
            for F in *; do
                ln -f "$F" "${DFILENEW}/"
                ln -f "$F" "${WFILENEW}/"
                ln -f "$F" "${MFILENEW}/"
            done
        )
        rm -rf "${DFILE}" "${WFILE}" "${MFILE}"
        echo "Replacing daily backup ${DFILE} folder this last backup..."
        mv "${DFILENEW}" "${DFILE}"
        echo "Replacing weekly backup ${WFILE} folder this last backup..."
        mv "${WFILENEW}" "${WFILE}"
        echo "Replacing monthly backup ${MFILE} folder this last backup..."
        mv "${MFILENEW}" "${MFILE}"
    else
        echo "Replacing daily backup ${DFILE} file this last backup..."
        ln -vf "${FILE}" "${DFILE}"
        echo "Replacing weekly backup ${WFILE} file this last backup..."
        ln -vf "${FILE}" "${WFILE}"
        echo "Replacing monthly backup ${MFILE} file this last backup..."
        ln -vf "${FILE}" "${MFILE}"
    fi
    # Update latest symlinks
    LATEST_LN_ARG=""
    if [ "${BACKUP_LATEST_TYPE}" = "symlink" ]; then
        LATEST_LN_ARG="-s"
    fi
    if [ "${BACKUP_LATEST_TYPE}" = "symlink" -o "${BACKUP_LATEST_TYPE}" = "hardlink"  ]; then
        echo "Point last backup file to this last backup..."
        ln "${LATEST_LN_ARG}" -vf "${LAST_FILENAME}" "${BACKUP_DIR}/last/${DB}-latest${BACKUP_SUFFIX}"
        echo "Point latest daily backup to this last backup..."
        ln "${LATEST_LN_ARG}" -vf "${DAILY_FILENAME}" "${BACKUP_DIR}/daily/${DB}-latest${BACKUP_SUFFIX}"
        echo "Point latest weekly backup to this last backup..."
        ln "${LATEST_LN_ARG}" -vf "${WEEKLY_FILENAME}" "${BACKUP_DIR}/weekly/${DB}-latest${BACKUP_SUFFIX}"
        echo "Point latest monthly backup to this last backup..."
        ln "${LATEST_LN_ARG}" -vf "${MONTHY_FILENAME}" "${BACKUP_DIR}/monthly/${DB}-latest${BACKUP_SUFFIX}"
    else # [ "${BACKUP_LATEST_TYPE}" = "none"  ]
        echo "Not updating lastest backup."
    fi
    #Clean old files
    echo "Cleaning older files for ${DB} database from ${DB_HOST}..."
    find "${BACKUP_DIR}/last" -maxdepth 1 -mmin "+${KEEP_MINS}" -name "${DB}-*${BACKUP_SUFFIX}" -exec rm -rvf '{}' ';'
    find "${BACKUP_DIR}/daily" -maxdepth 1 -mtime "+${KEEP_DAYS}" -name "${DB}-*${BACKUP_SUFFIX}" -exec rm -rvf '{}' ';'
    find "${BACKUP_DIR}/weekly" -maxdepth 1 -mtime "+${KEEP_WEEKS}" -name "${DB}-*${BACKUP_SUFFIX}" -exec rm -rvf '{}' ';'
    find "${BACKUP_DIR}/monthly" -maxdepth 1 -mtime "+${KEEP_MONTHS}" -name "${DB}-*${BACKUP_SUFFIX}" -exec rm -rvf '{}' ';'
done

echo "SQL backup created successfully"

# Post-backup hook
if [ -d "${HOOKS_DIR}" ]; then
    run-parts -a "post-backup" --reverse --exit-on-error "${HOOKS_DIR}"
fi
