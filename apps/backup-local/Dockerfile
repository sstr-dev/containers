# syntax=docker/dockerfile:1
ARG VERSION
FROM docker.io/library/postgres:${VERSION}
ENV DB_TYPE=postgres \
    DB_NAMES="**None**" \
    DB_NAMES_FILE="**None**" \
    DB_EXTRA_OPTS="" \
    POSTGRES_PORT=5432 \
    POSTGRES_EXTRA_OPTS="-Z1" \
    MARIADB_PORT=3306 \
    MARIADB_EXTRA_OPTS="--single-transaction --quick --routines --events" \
    BACKUP_DIR="/backups" \
    BACKUP_SUFFIX=".sql.gz" \
    BACKUP_KEEP_MINS=1440 \
    BACKUP_KEEP_DAYS=7 \
    BACKUP_KEEP_WEEKS=4 \
    BACKUP_KEEP_MONTHS=6 \
    BACKUP_LATEST_TYPE=symlink \
    VALIDATE_ON_START=TRUE
USER root
RUN \
    apk add --no-cache \
        bash \
        ca-certificates \
        catatonit \
        curl \
        findutils \
        tzdata \
        mariadb-client \
    && rm -rf /tmp/*

COPY ./resources/init.sh /init.sh
COPY ./resources/env.sh /env.sh
COPY ./resources/backup.sh /backup.sh
COPY ./resources/hooks /hooks

RUN chmod 0755 /init.sh /env.sh /backup.sh /hooks/00-webhook

#COPY ./scripts /scripts
USER nobody:nogroup
ENTRYPOINT ["/init.sh"]

