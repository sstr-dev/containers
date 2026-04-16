<div align="center">

## Containers

_Containers used in my homelab_

</div>

Welcome to our container images! If you are looking for a container, start by [browsing the GitHub Packages page for this repository's packages](https://github.com/sstr-dev?tab=packages&repo_name=containers).

This repository contains application-specific container builds and supporting local development tooling.

## Quick Links

- Browse published packages: [GitHub Packages](https://github.com/sstr-dev?tab=packages&repo_name=containers)
- Local development workflow: [docs/just-local-workflow.md](docs/just-local-workflow.md)
- Repository conventions and policies: [docs/repository-guidelines.md](docs/repository-guidelines.md)

## What You Will Find Here

- Container definitions under `apps/<name>/`
- Shared build resources under `include/`
- App-specific documentation in `apps/<name>/README.md`
- Local build, test, debug, and release commands in [`.justfile`](.justfile)

## Notes

- Images are intended to be simple, rootless where practical, and easy to automate.
- App-specific configuration belongs in the corresponding app README.
- Longer repository-wide guidance has been moved into `docs/`.

## Credits

This repository draws inspiration and ideas from the home-ops community, [home-operations](https://github.com/home-operations), [hotio.dev](https://hotio.dev/) and [linuxserver.io](https://www.linuxserver.io/) contributors.
