# unifi-api-browser

Container image for [Art-of-WiFi/UniFi-API-browser](https://github.com/Art-of-WiFi/UniFi-API-browser).

On startup, the container checks whether `CONFIG_FILE` exists. If it does not, the entrypoint renders a `config.php` from environment variables.

`users.php` is handled separately: it is only rendered when at least one `USERS_<index>_USER_NAME` environment variable is set.

## Important variables

- `CONFIG_FILE`: Optional target path for the rendered PHP config. Default: `/app/config/config.php`
- `USERS_FILE`: Optional target path for the rendered PHP users file. Default: `/app/config/users.php`
- `THEME`: UI theme. Default: `bootstrap`
- `NAVBAR_CLASS`: Navbar text style. Default: `dark`
- `NAVBAR_BG_CLASS`: Navbar background style. Default: `dark`
- `DEBUG`: Enables upstream debug mode when set to `true`, `1`, `yes`, or `on`

## Single-controller fallback

If no `CONTROLLERS_<index>_*` variables are set, the container falls back to a single classic controller using:

- `USER`
- `PASSWORD`
- `UNIFIURL`
- `PORT`
- `DISPLAYNAME`
- `VERIFY_SSL`

This is mainly useful for quick local tests or simple one-controller setups.

## Multi-controller configuration

Controllers are defined with indexed environment variables:

- `CONTROLLERS_0_TYPE=classic|official`
- `CONTROLLERS_0_NAME`
- `CONTROLLERS_0_URL`
- `CONTROLLERS_0_VERIFY_SSL`

For `classic` controllers:

- `CONTROLLERS_0_USER`
- `CONTROLLERS_0_PASSWORD`

For `official` controllers:

- `CONTROLLERS_0_TOKEN` or `CONTROLLERS_0_API_KEY`

The same pattern repeats for `CONTROLLERS_1_*`, `CONTROLLERS_2_*`, and so on.

## Browser users configuration

Browser auth users are defined with indexed environment variables:

- `USERS_0_USER_NAME`
- `USERS_0_PASSWORD_HASH`

Optional convenience input:

- `USERS_0_PASSWORD`

If `USERS_0_PASSWORD` is set and no `USERS_0_PASSWORD_HASH` is provided, the entrypoint computes the SHA-512 hash automatically.

The same pattern repeats for `USERS_1_*`, `USERS_2_*`, and so on.

If no `USERS_<index>_USER_NAME` variable is present, `users.php` is not written at all.

## Local test

Example using the included env file:

```bash
docker run --rm -p 8000:8000 --env-file apps/unifi-api-browser/env.example unifi-api-browser:v3.0.0
```

Or with the local image from this repository:

```bash
just local-build-debug unifi-api-browser
docker run --rm -p 8000:8000 --env-file apps/unifi-api-browser/env.example unifi-api-browser:v3.0.0
```

Then open `http://localhost:8000`.

## Notes

- If `CONFIG_FILE` already exists, the entrypoint leaves it untouched.
- If `USERS_FILE` already exists, the entrypoint leaves it untouched.
- `CONTROLLERS_<index>_TOKEN` is written to upstream `api_key` for `official` controllers.
- `VERIFY_SSL` and `CONTROLLERS_<index>_VERIFY_SSL` accept `true|false`, `1|0`, `yes|no`, and `on|off`.
- `USERS_<index>_PASSWORD_HASH` should contain a SHA-512 hex digest compatible with upstream `users.php`.
