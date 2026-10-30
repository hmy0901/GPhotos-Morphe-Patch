#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

if ! command -v java >/dev/null 2>&1; then
    echo "Java 17 or newer is required to run Gradle 9.8.2." >&2
    exit 1
fi

java_major="$(java -version 2>&1 | awk -F '[".]' '/version/ { print $2; exit }')"
if [[ -z "$java_major" || "$java_major" -lt 17 ]]; then
    echo "Java 17 or newer is required to run Gradle 9.8.2." >&2
    exit 1
fi

./scripts/gradle.sh --no-daemon --version
./scripts/gradle.sh --no-daemon --rerun-tasks test
