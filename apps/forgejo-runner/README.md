# forgejo-runner

Job image for Forgejo Actions with the [runner-k8s-plugin](https://git.erwanleboucher.dev/eleboucher/runner-k8s-plugin).
Not the runner daemon itself — that is `code.forgejo.org/forgejo/runner`.

Based on [`gitea/runner-images`](https://gitea.com/gitea/runner-images) (`ubuntu-26.04`, act-compatible incl. node, git, docker cli)
and the [bjw-s-labs image](https://github.com/bjw-s-labs/container-images/tree/main/apps/forgejo-runner).

Additional tools: `flux`, `helm`, `kustomize`, `flate`, `cosign`, `gh`, `fjo`, `pipx` (python 3.14), `clang`/`llvm`, `rsync`.

Runs as root by design (workflow steps expect it); isolation happens at the Kubernetes job/namespace level.
