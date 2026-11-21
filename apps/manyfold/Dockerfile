# syntax=docker/dockerfile:1

# Based on https://github.com/bjw-s-labs/container-images/tree/main/apps/manyfold
ARG VERSION
FROM ghcr.io/manyfold3d/manyfold:${VERSION}

USER root
#hadolint ignore=DL3018
RUN \
    apk add --no-cache \
        bash \
        catatonit \
        valkey \
    && mv /usr/src/app /app \
    && chmod -R 777 /app/tmp \
    && chmod -R 777 /app/log

USER nobody:nogroup
WORKDIR /data
VOLUME ["/data"]

COPY --chmod=755 ./entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/usr/bin/catatonit", "--", "/entrypoint.sh"]
