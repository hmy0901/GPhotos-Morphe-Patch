#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export GRADLE_USER_HOME="${GRADLE_USER_HOME:-$repo_root/.gradle}"

# The cloud machine exports curl-style proxy variables. Java does not consume
# those variables automatically, so translate only the proxy host/port into JVM
# properties when no explicit HTTPS proxy is already configured.
if [[ -n "${HTTPS_PROXY:-${https_proxy:-}}" && " ${JAVA_TOOL_OPTIONS:-} " != *"-Dhttps.proxyHost="* ]]; then
    proxy_url="${HTTPS_PROXY:-${https_proxy:-}}"
    proxy_authority="${proxy_url#*://}"
    proxy_authority="${proxy_authority##*@}"
    proxy_authority="${proxy_authority%%/*}"
    proxy_host="${proxy_authority%:*}"
    proxy_port="${proxy_authority##*:}"
    if [[ "$proxy_host" == "$proxy_port" ]]; then
        proxy_port="443"
        [[ "$proxy_url" == http://* ]] && proxy_port="80"
    fi
    export JAVA_TOOL_OPTIONS="${JAVA_TOOL_OPTIONS:+$JAVA_TOOL_OPTIONS }-Dhttps.proxyHost=$proxy_host -Dhttps.proxyPort=$proxy_port -Dhttp.proxyHost=$proxy_host -Dhttp.proxyPort=$proxy_port"
fi

exec "$repo_root/gradlew" "$@"
