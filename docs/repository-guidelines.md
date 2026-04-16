# Repository Guidelines

This document collects repository-wide conventions and policies that are useful once you are already working with the containers in this repository.

## Mission

The goal of this repository is to provide [semantically versioned](https://semver.org/), [rootless](https://rootlesscontaine.rs/), and [multi-architecture](https://www.docker.com/blog/multi-arch-build-and-images-the-simple-way/) containers for various applications.

The repository follows a simple operational model:

- Prefer one process per container
- Log to stdout
- Avoid heavy init systems such as `s6-overlay`
- Prefer Alpine or Ubuntu base images

## Image Conventions

### Tag Immutability

Containers built here do not use immutable tags in the traditional sense. Instead, deployments should pin the `sha256` digest of an image.

Examples:

| Container | Immutable |
|-----------------------|----|
| `ghcr.io/sstr-dev/home-assistant:rolling` | ❌ |
| `ghcr.io/sstr-dev/home-assistant:2025.5.1` | ❌ |
| `ghcr.io/sstr-dev/home-assistant:rolling@sha256:8053...` | ✅ |
| `ghcr.io/sstr-dev/home-assistant:2025.5.1@sha256:8053...` | ✅ |

If pinning an image to the digest, tools like [Renovate](https://github.com/renovatebot/renovate) can still update containers based on digest or version changes.

### Rootless

Most containers run as a non-root user (`65534:65534`) by default. You can change the user and group where your runtime environment requires it.

Docker Compose example:

```yaml
services:
  home-assistant:
    image: ghcr.io/sstr-dev/home-assistant:2025.5.1
    container_name: home-assistant
    user: 1000:1000
    read_only: true
    tmpfs:
      - /tmp:rw
```

Kubernetes example:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: home-assistant
spec:
  template:
    spec:
      containers:
        - name: home-assistant
          image: ghcr.io/sstr-dev/home-assistant:2025.5.1
          securityContext:
            allowPrivilegeEscalation: false
            capabilities:
              drop:
                - ALL
            readOnlyRootFilesystem: true
          volumeMounts:
            - name: tmp
              mountPath: /tmp
      securityContext:
        runAsUser: 1000
        runAsGroup: 1000
        fsGroup: 65534
        fsGroupChangePolicy: OnRootMismatch
      volumes:
        - name: tmp
          emptyDir: {}
```

### Passing Arguments

Some applications only support parts of their configuration through command-line arguments rather than environment variables. In Kubernetes, these can be passed with `args`, for example:

```yaml
args:
  - --port
  - "8080"
```

### Configuration Volume

For applications requiring persistent configuration data, the configuration volume is typically hardcoded to `/config` inside the container.

### Verify Image Signature

These images are signed using GitHub attestation.

Verify with `gh`:

```bash
gh attestation verify --repo sstr-sstr/containers oci://ghcr.io/home-operations/${APP}:${TAG}
```

Or with `cosign`:

```bash
cosign verify-attestation --new-bundle-format --type slsaprovenance1 \
    --certificate-oidc-issuer "https://token.actions.githubusercontent.com" \
    --certificate-identity-regexp "^https://github.com/sstr-sstr/containers/.github/workflows/app-builder.yaml@refs/heads/main" \
    ghcr.io/sstr-sstr/${APP}:${TAG}
```

### Deliberately Unsupported Patterns

This repository does not support multiple channels for the same application.

Examples:

- Prowlarr, Radarr, Lidarr, and Sonarr publish only the `develop` branch
- qBittorrent is published only with LibTorrent 2.x

## Contributing

Using an official upstream container image is preferred whenever it is a good fit. Contributing to this repository makes the most sense when:

- the upstream project is actively maintained, and
- no suitable official container exists, or
- the official image does not support multi-architecture builds, or
- the official image relies on tooling or patterns this repository intentionally avoids

## Deprecations

Containers in this repository may be deprecated when:

1. The upstream project is no longer actively maintained.
2. An official upstream container exists that fits this repository better.
3. The maintenance burden becomes too high.

Deprecated containers are announced with a release and remain available in the registry for six months before removal.

## Maintaining a Fork

This repository is a fork of [home-operations/containers](https://github.com/home-operations/containers).

Things to keep in mind:

1. Set up Renovate, for example with the [GitHub Action](https://github.com/renovatebot/github-action).
2. Some Renovate conventions come from shared configuration such as [home-operations/.github](https://github.com/home-operations/.github) and [home-operations/renovate-config](https://github.com/home-operations/renovate-config).
3. Keep GitHub usernames and repository names lowercase to avoid GHCR naming issues.
