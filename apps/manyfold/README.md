# manyfold

[Manyfold](https://github.com/manyfold3d/manyfold) (3D model library) based on the official image, adjusted to run rootless:

- runs as `nobody:nogroup`, app moved to `/app`, data in `/data`
- `catatonit` as init, `entrypoint.sh` runs `db:prepare:with_data`, clears the tmp cache and starts `foreman`
- optional built-in valkey: `RUN_BUILTIN_REDIS=true` (only when `REDIS_URL` is unset/localhost)

Defaults: `PORT=3214`, `REDIS_URL=redis://localhost:6379`.
Based on the [bjw-s-labs image](https://github.com/bjw-s-labs/container-images/tree/main/apps/manyfold).
