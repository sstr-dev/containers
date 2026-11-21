# syntax=docker/dockerfile:1

# Based on https://github.com/bjw-s-labs/container-images/tree/main/apps/k8s-crd-extractor
FROM docker.io/library/python:3.14-alpine3.23
ARG VERSION

ENV \
    UV_NO_CACHE=true \
    UV_EXTRA_INDEX_URL="https://wheel-index.linuxserver.io/alpine-3.23/"

COPY --from=ghcr.io/astral-sh/uv:0.13.9 /uv /uvx /bin/

#hadolint ignore=DL3018
RUN \
    apk add --no-cache \
        bash \
        ca-certificates \
        catatonit \
        kubectl \
    && uv pip install --system pyyaml \
    && rm /bin/uv /bin/uvx \
    && rm -rf /tmp/*

USER nobody:nogroup
ENV HOME=/config
WORKDIR /config
WORKDIR /app
VOLUME ["/config", "/app"]

ADD --chmod=555 https://raw.githubusercontent.com/datreeio/CRDs-catalog/${VERSION}/Utilities/crd-extractor.sh /app/crd-extractor.sh
ADD --chmod=555 https://raw.githubusercontent.com/datreeio/CRDs-catalog/${VERSION}/Utilities/openapi2jsonschema.py /app/openapi2jsonschema.py

ENTRYPOINT ["/usr/bin/catatonit", "--", "/app/crd-extractor.sh"]
