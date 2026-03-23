# backup-local

Local backup container

## Important variables

- `DB_TYPE=postgres|mariadb`
- `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`
- `DB_NAMES` or `DB_NAMES_FILE`
- `BACKUP_DIR`, `BACKUP_KEEP_MINS`, `BACKUP_KEEP_DAYS`, `BACKUP_KEEP_WEEKS`, `BACKUP_KEEP_MONTHS`
- `BACKUP_LATEST_TYPE=symlink|hardlink|none`
- `VALIDATE_ON_START`

## Postgres options
- DB_EXTRA_OPTS: "--blobs --clean --create --compress=9"

## MariaDB options
- DB_EXTRA_OPTS: "--single-transaction --quick --routines --events --triggers --hex-blob --add-drop-table"
