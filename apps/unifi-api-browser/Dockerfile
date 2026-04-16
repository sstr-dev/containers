FROM docker.io/library/alpine:3.23.3

ARG VERSION

#hadolint ignore=DL3018
RUN \
    apk add --no-cache \
        bash \
        ca-certificates \
        coreutils \
        catatonit \
        curl \
        openssl \
        php \
        php-session \
        php-curl \
        php-tokenizer \
        composer

#hadolint ignore=DL3018,DL3059
RUN \
    mkdir -p /app \
    && \
    curl -fsSL "https://github.com/Art-of-WiFi/UniFi-API-browser/archive/refs/tags/${VERSION}.tar.gz" \
        | tar xzf - -C /app --strip-components=1 \
    && \
    chown -R nobody:nobody /app/config

# Define environment variable
ENV PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
ENV LANG="C.UTF-8"

USER nobody

COPY ./resources/entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/usr/bin/catatonit", "--", "/entrypoint.sh"]
# /app/index.php
