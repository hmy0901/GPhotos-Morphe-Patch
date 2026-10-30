#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source_parent="$repo_root/.gradle/morphe-sources"
mkdir -p "$source_parent"

fetch_pinned() {
    local project_name="$1" expected_sha="$2" destination="$source_parent/$1"
    local origin_url="https://github.com/MorpheApp/$project_name.git"
    if [[ -d "$destination/.git" ]]; then
        [[ "$(git -C "$destination" remote get-url origin)" == "$origin_url" ]] || {
            echo "$destination has an unexpected origin" >&2; exit 1;
        }
        [[ "$(git -C "$destination" rev-parse HEAD)" == "$expected_sha" ]] || {
            echo "$destination does not match pinned commit $expected_sha" >&2; exit 1;
        }
        [[ -z "$(git -C "$destination" status --porcelain)" ]] || {
            echo "$destination contains local changes" >&2; exit 1;
        }
        return
    fi
    [[ ! -e "$destination" ]] || { echo "$destination exists without Git metadata" >&2; exit 1; }
    local staging
    staging="$(mktemp -d "$source_parent/.staging.XXXXXX")"
    git -C "$staging" init -q
    git -C "$staging" remote add origin "$origin_url"
    git -C "$staging" fetch --depth 1 origin "$expected_sha"
    git -C "$staging" checkout -q --detach FETCH_HEAD
    [[ "$(git -C "$staging" rev-parse HEAD)" == "$expected_sha" ]]
    mv "$staging" "$destination"
}

fetch_pinned morphe-patcher f3997dc1011b84a301c1ffe426fd9dfdd85095ba
fetch_pinned ARSCLib 4695b583ef51890ce283f3f2e0f6f63dff230ef0
fetch_pinned smali ac700e1942d26a7374166dce35f6da049a10e1a5
