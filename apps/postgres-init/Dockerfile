# syntax=docker/dockerfile:1
ARG VERSION
FROM docker.io/library/postgres:${VERSION}
ARG VERSION
USER root
RUN \
    apk add --no-cache \
        bash \
        ca-certificates \
        catatonit \
    && rm -rf /tmp/*
COPY ./resources/list_dbs.sh /list_dbs.sh
COPY ./resources/entrypoint.sh /entrypoint.sh
#COPY ./scripts /scripts
USER nobody:nogroup
ENTRYPOINT ["/usr/bin/catatonit", "--", "/entrypoint.sh"]
