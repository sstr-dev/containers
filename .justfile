#!/usr/bin/env -S just --justfile

set quiet := true
set shell := ['bash', '-eu', '-o', 'pipefail', '-c']

bin_dir := justfile_dir() + '/.bin'
private_env_file := justfile_dir() + '/.private/.env'
local_push_registry := env_var_or_default('LOCAL_PUSH_REGISTRY', 'harbor.sstr.dev/containers')

[private]
default:
    just --list

[private]
[working-directory('.cache')]
sync-local-build-context app:
    rsync -aqIP {{ justfile_dir() }}/include/ {{ justfile_dir() }}/apps/{{ app }}/ .

[doc('Build and test an app locally')]
[working-directory('.cache')]
local-build app:
    just sync-local-build-context {{ app }}
    docker buildx bake --no-cache --metadata-file docker-bake.json --set=*.output=type=docker --load
    TEST_IMAGE="$(jq -r '."image-local"."image.name" | sub("^docker.io/library/"; "")' docker-bake.json)" go test -v {{ justfile_dir() }}/apps/{{ app }}/...

[doc('Build an app locally with verbose Docker output for debugging')]
[working-directory('.cache')]
local-build-debug app:
    just sync-local-build-context {{ app }}
    BUILDKIT_PROGRESS=plain docker buildx bake --no-cache --metadata-file docker-bake.json --set=*.output=type=docker --load

[doc('Build an app locally without running tests')]
[working-directory('.cache')]
local-image-build app:
    just sync-local-build-context {{ app }}
    docker buildx bake --no-cache --metadata-file docker-bake.json --set=*.output=type=docker --load

[doc('Run Go container tests for an app against the locally built image')]
[working-directory('.cache')]
local-test app:
    TEST_IMAGE="$(jq -r '."image-local"."image.name" | sub("^docker.io/library/"; "")' docker-bake.json)" go test -v {{ justfile_dir() }}/apps/{{ app }}/...

[doc('Login to the local registry using credentials from .private/.env')]
local-login registry=local_push_registry:
    set -a \
      && source {{ private_env_file }} \
      && set +a \
      && REGISTRY_HOST="{{ registry }}" \
      && REGISTRY_HOST="${REGISTRY_HOST%%/*}" \
      && : "${LOCAL_PUSH_USERNAME:?Missing LOCAL_PUSH_USERNAME in .private/.env}" \
      && : "${LOCAL_PUSH_PASSWORD:?Missing LOCAL_PUSH_PASSWORD in .private/.env}" \
      && printf '%s' "$LOCAL_PUSH_PASSWORD" | docker login "$REGISTRY_HOST" --username "$LOCAL_PUSH_USERNAME" --password-stdin

[doc('Tag and push a locally built image to the configured local registry')]
[working-directory('.cache')]
local-push app registry=local_push_registry:
    just local-login {{ registry }}
    LOCAL_IMAGE="$(jq -r '."image-local"."image.name" | sub("^docker.io/library/"; "")' docker-bake.json)" \
      && IMAGE_TAG="${LOCAL_IMAGE##*:}" \
      && TARGET_IMAGE="{{ registry }}/{{ app }}:${IMAGE_TAG}" \
      && docker tag "$LOCAL_IMAGE" "$TARGET_IMAGE" \
      && docker push "$TARGET_IMAGE"

[doc('Build, test, and push an app to the configured local registry')]
[working-directory('.cache')]
local-release app registry=local_push_registry:
    just local-image-build {{ app }}
    just local-test {{ app }}
    just local-push {{ app }} {{ registry }}

[doc('Trigger a remote build')]
remote-build app release="false":
    gh workflow run release.yaml -f app={{ app }} -f release={{ release }}

[private]
generate-label-config:
    find "{{ justfile_dir() }}/apps" -mindepth 1 -maxdepth 1 -type d -printf "%f\n" | while IFS= read -r app; do \
        yq -i ". += [{\"name\": \"app/$app\", \"color\": \"027fa0\"}]" {{ justfile_dir() }}/.github/labels.yaml; \
        yq -i ". += {\"app/$app\": [{\"changed-files\": [{\"any-glob-to-any-file\": [\"apps/$app/**\"]}]}]}" {{ justfile_dir() }}/.github/labeler.yaml; \
    done
