#!/usr/bin/env bash

set -eu

CONFIG_FILE="${CONFIG_FILE:-${CONFiG_FILE:-/app/config/config.php}}"
USERS_FILE="${USERS_FILE:-/app/config/users.php}"

php_escape() {
    local value="${1:-}"
    value="${value//\\/\\\\}"
    value="${value//\'/\\\'}"
    printf "%s" "$value"
}

php_bool() {
    local value="${1:-}"
    local default="${2:-false}"

    if [[ -z "$value" ]]; then
        printf "%s" "$default"
        return
    fi

    case "${value,,}" in
        1|true|yes|on)
            printf "true"
            ;;
        0|false|no|off)
            printf "false"
            ;;
        *)
            printf "%s" "$default"
            ;;
    esac
}

controller_url() {
    local base_url="${1:-}"
    local port="${2:-}"

    if [[ -z "$base_url" ]]; then
        printf ""
        return
    fi

    if [[ -z "$port" ]]; then
        printf "%s" "$base_url"
        return
    fi

    if [[ "$base_url" =~ ^https?://[^/]+:[0-9]+(/.*)?$ ]]; then
        printf "%s" "$base_url"
        return
    fi

    printf "%s:%s" "${base_url%/}" "$port"
}

sha512_hash() {
    local value="${1:-}"
    printf "%s" "$value" | openssl dgst -sha512 -binary | od -An -vtx1 | tr -d ' \n'
}

render_classic_controller() {
    local prefix="$1"
    local index="$2"
    local username_var="${prefix}_USER"
    local password_var="${prefix}_PASSWORD"
    local url_var="${prefix}_URL"
    local name_var="${prefix}_NAME"
    local verify_ssl_var="${prefix}_VERIFY_SSL"
    local username="${!username_var:-${USER:-}}"
    local password="${!password_var:-${PASSWORD:-}}"
    local url="${!url_var:-}"
    local name="${!name_var:-${DISPLAYNAME:-Controller ${index}}}"
    local verify_ssl="${!verify_ssl_var:-${VERIFY_SSL:-true}}"

    if [[ -z "$url" ]]; then
        url="$(controller_url "${UNIFIURL:-}" "${PORT:-}")"
    fi

    cat <<EOF
    [
        'username' => '$(php_escape "$username")',
        'password' => '$(php_escape "$password")',
        'url' => '$(php_escape "$url")',
        'name' => '$(php_escape "$name")',
        'type' => 'classic',
        'verify_ssl' => $(php_bool "$verify_ssl" true),
    ],
EOF
}

render_official_controller() {
    local prefix="$1"
    local index="$2"
    local token_var="${prefix}_TOKEN"
    local api_key_var="${prefix}_API_KEY"
    local url_var="${prefix}_URL"
    local name_var="${prefix}_NAME"
    local verify_ssl_var="${prefix}_VERIFY_SSL"
    local token="${!token_var:-${!api_key_var:-${TOKEN:-${API_KEY:-}}}}"
    local url="${!url_var:-}"
    local name="${!name_var:-${DISPLAYNAME:-Controller ${index}}}"
    local verify_ssl="${!verify_ssl_var:-${VERIFY_SSL:-true}}"

    if [[ -z "$url" ]]; then
        url="$(controller_url "${UNIFIURL:-}" "${PORT:-}")"
    fi

    cat <<EOF
    [
        'api_key' => '$(php_escape "$token")',
        'url' => '$(php_escape "$url")',
        'name' => '$(php_escape "$name")',
        'type' => 'official',
        'verify_ssl' => $(php_bool "$verify_ssl" true),
    ],
EOF
}

render_config() {
    local config_dir
    config_dir="$(dirname "$CONFIG_FILE")"
    mkdir -p "$config_dir"

    local controller_blocks=""
    local found_controllers="false"

    while IFS='=' read -r env_name _; do
        local prefix="${env_name%_TYPE}"
        local index="${prefix#CONTROLLERS_}"
        local type_var="${prefix}_TYPE"
        local type="${!type_var:-classic}"

        found_controllers="true"

        case "${type,,}" in
            official)
                controller_blocks+=$(render_official_controller "$prefix" "$index")
                ;;
            classic|"")
                controller_blocks+=$(render_classic_controller "$prefix" "$index")
                ;;
            *)
                echo "unsupported controller type '${type}' for ${prefix}, skipping" >&2
                ;;
        esac
    done < <(env | LC_ALL=C sort | sed -n 's/^\(CONTROLLERS_[0-9]\+_TYPE\)=.*/\1=/p')

    if [[ "$found_controllers" == "false" ]] && [[ -n "${UNIFIURL:-}" ]]; then
        controller_blocks="$(render_classic_controller "CONTROLLERS_0" "0")"
    fi

    cat >"$CONFIG_FILE" <<EOF
<?php

\$controllers = [
${controller_blocks}];

\$theme = '$(php_escape "${THEME:-bootstrap}")';
\$navbar_class = '$(php_escape "${NAVBAR_CLASS:-dark}")';
\$navbar_bg_class = '$(php_escape "${NAVBAR_BG_CLASS:-dark}")';
\$debug = $(php_bool "${DEBUG:-false}" false);
EOF
}

render_users() {
    local users_dir
    users_dir="$(dirname "$USERS_FILE")"
    mkdir -p "$users_dir"

    local user_blocks=""

    while IFS='=' read -r env_name _; do
        local prefix="${env_name%_USER_NAME}"
        local user_name_var="${prefix}_USER_NAME"
        local password_hash_var="${prefix}_PASSWORD_HASH"
        local password_sha512_var="${prefix}_PASSWORD_SHA512"
        local password_var="${prefix}_PASSWORD"
        local user_name="${!user_name_var:-}"
        local password_hash="${!password_hash_var:-${!password_sha512_var:-}}"
        local password_plain="${!password_var:-}"

        if [[ -z "$user_name" ]]; then
            continue
        fi

        if [[ -z "$password_hash" ]] && [[ -n "$password_plain" ]]; then
            password_hash="$(sha512_hash "$password_plain")"
        fi

        if [[ -z "$password_hash" ]]; then
            echo "missing password hash/password for ${prefix}, skipping user entry" >&2
            continue
        fi

        user_blocks+=$(cat <<EOF
    [
        'user_name' => '$(php_escape "$user_name")',
        'password' => '$(php_escape "$password_hash")',
    ],
EOF
)
    done < <(env | LC_ALL=C sort | sed -n 's/^\(USERS_[0-9]\+_USER_NAME\)=.*/\1=/p')

    if [[ -z "$user_blocks" ]]; then
        return
    fi

    cat >"$USERS_FILE" <<EOF
<?php

\$users = [
${user_blocks}];
EOF
}

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "rendering UniFi-API-browser config to $CONFIG_FILE"
    render_config
fi

if [[ ! -f "$USERS_FILE" ]] && env | grep -Eq '^USERS_[0-9]+_USER_NAME='; then
    echo "rendering UniFi-API-browser users to $USERS_FILE"
    render_users
fi

echo "starting UniFi-API-browser"
php -S 0:8000 -t /app
