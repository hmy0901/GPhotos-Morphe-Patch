#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"
./scripts/setup-morphe-sources.sh

if [[ -n "${MORPHE_JDK_HOME:-}" ]]; then
    export JAVA_HOME="$MORPHE_JDK_HOME"
elif [[ -n "${JAVA_HOME:-}" && -x "$JAVA_HOME/bin/javac" ]]; then
    :
elif command -v javac >/dev/null 2>&1; then
    export JAVA_HOME="$(dirname "$(dirname "$(readlink -f "$(command -v javac)")")")"
else
    ./scripts/prepare-morphe-jdk.sh
    export JAVA_HOME="$repo_root/.gradle/morphe-jdk"
fi
[[ -x "$JAVA_HOME/bin/javac" ]] || { echo "A complete JDK is required" >&2; exit 1; }
export PATH="$JAVA_HOME/bin:$PATH"

./scripts/gradle.sh -p "$repo_root/.gradle/morphe-sources/morphe-patcher" --no-daemon --max-workers=2 assemble
./scripts/gradle.sh --no-daemon --max-workers=2 verifyMorpheSourceApi
