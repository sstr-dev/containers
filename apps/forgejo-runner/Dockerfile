# syntax=docker/dockerfile:1

# Job image for the Forgejo runner (runner-k8s-plugin).
FROM docker.io/gitea/runner-images:ubuntu-26.04@sha256:433d703e6214e93234583ecc9cbec0b30fb5691259b0581597aaede21b031f8b

ARG TARGETARCH

# Install binaries from other images
COPY --from=ghcr.io/fluxcd/flux-cli:v2.10.1 /usr/local/bin/flux /usr/local/bin/flux
COPY --from=docker.io/alpine/helm:4.3.2 /usr/bin/helm /usr/local/bin/helm
COPY --from=ghcr.io/sigstore/cosign/cosign:v3.1.4 /ko-app/cosign /usr/local/bin/cosign
COPY --from=ghcr.io/home-operations/flate:0.8.0 /flate /usr/local/bin/flate
COPY --from=ghcr.io/perfectra1n/fjo:0.3.1 /usr/local/bin/fjo /usr/local/bin/fjo

# hadolint ignore=DL3008,DL3015
RUN \
    apt-get -qq update \
    && apt-get -qq install -y clang llvm python3.14 python3.14-venv rsync

# renovate: datasource=github-releases depName=kubernetes-sigs/kustomize extractVersion=^kustomize/(?<version>.+)$
ARG KUSTOMIZE_VERSION=v5.8.3
RUN \
    wget -qO- "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize/${KUSTOMIZE_VERSION}/kustomize_${KUSTOMIZE_VERSION}_linux_${TARGETARCH}.tar.gz" \
    | tar xz -C /usr/local/bin kustomize

# pipx
ENV PATH="/root/.local/bin:${PATH}"
RUN \
    mkdir -p ~/.local/bin \
    && python3.14 -m venv ~/.local/share/pipx-venv \
    && ~/.local/share/pipx-venv/bin/pip install --no-cache-dir pipx \
    && ln -s ~/.local/share/pipx-venv/bin/pipx ~/.local/bin/pipx

# renovate: datasource=github-releases depName=cli/cli extractVersion=^v(?<version>.*)$
ARG GH_CLI_VERSION=2.105.0
RUN \
    wget -qO- "https://github.com/cli/cli/releases/download/v${GH_CLI_VERSION}/gh_${GH_CLI_VERSION}_linux_${TARGETARCH}.tar.gz" \
    | tar xz --strip-components=2 -C /usr/local/bin "gh_${GH_CLI_VERSION}_linux_${TARGETARCH}/bin/gh"

RUN \
    apt-get clean \
    && rm -rf /var/lib/apt/lists/* /var/cache/* /var/log/* /tmp/*
