# Just Local Workflow

This repository includes a `just`-based local workflow for building, testing, debugging, and publishing container images.

## Setup

Requirements:

- `just`
- `docker`
- `jq`
- `go`
- `rsync`

List available commands:

```bash
just --list
```

For local registry pushes, add credentials to `.private/.env`:

```bash
LOCAL_PUSH_USERNAME='robot$containers+local-push'
LOCAL_PUSH_PASSWORD='replace-me'
```

The local registry target defaults to:

```bash
harbor.sstr.dev/containers
```

You can override it per command:

```bash
LOCAL_PUSH_REGISTRY=harbor.example.dev/team just local-push unifi-api-browser
```

## Build

Build and test an app locally:

```bash
just local-build unifi-api-browser
```

Build only:

```bash
just local-image-build unifi-api-browser
```

This builds inside `.cache` using the app directory plus the shared `include/` files.

## Test

Run Go container tests against the image referenced by `.cache/docker-bake.json`:

```bash
just local-test unifi-api-browser
```

This is most useful after `just local-image-build <app>`.

## Debug

Use the debug build when you want verbose Docker build output, including `RUN` command output from the Dockerfile:

```bash
just local-build-debug unifi-api-browser
```

This sets:

```bash
BUILDKIT_PROGRESS=plain
```

## Release

Log in to the local registry using credentials from `.private/.env`:

```bash
just local-login
```

Push a previously built image:

```bash
just local-push unifi-api-browser
```

Build, test, and push in one command:

```bash
just local-release unifi-api-browser
```

The pushed tag is derived from the locally built image tag in `.cache/docker-bake.json`.

## Typical Flow

Quick iteration:

```bash
just local-build-debug unifi-api-browser
```

Normal local validation:

```bash
just local-image-build unifi-api-browser
just local-test unifi-api-browser
```

Publish to Harbor:

```bash
just local-release unifi-api-browser
```

