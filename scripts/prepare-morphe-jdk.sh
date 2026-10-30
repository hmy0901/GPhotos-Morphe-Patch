#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
jdk_root="$repo_root/.gradle/morphe-jdk"
if [[ -x "$jdk_root/bin/javac" ]]; then
    "$jdk_root/bin/javac" -version
    exit 0
fi

command -v apt-get >/dev/null && command -v dpkg-deb >/dev/null || {
    echo "A complete JDK or Debian apt tools are required" >&2; exit 1;
}
java_bin="$(readlink -f "$(command -v java)")"
runtime_root="$(dirname "$(dirname "$java_bin")")"
[[ -d "$runtime_root" ]] || { echo "Java runtime directory missing" >&2; exit 1; }
major="$(java -version 2>&1 | awk -F '[".]' '/version/ { print $2; exit }')"
runtime_version="$(dpkg-query -W -f='${Version}' "openjdk-$major-jre-headless")"
apt_root="$repo_root/.gradle/morphe-apt"
mkdir -p "$apt_root/lists/partial" "$apt_root/archives/partial" "$apt_root/etc"
apt_opts=(-o "Dir::State::lists=$apt_root/lists" -o "Dir::Cache::archives=$apt_root/archives" -o "Dir::Etc::parts=$apt_root/etc")
apt-get "${apt_opts[@]}" update
(
    cd "$apt_root"
    apt-get "${apt_opts[@]}" download "openjdk-$major-jdk-headless=$runtime_version"
)
package_file="$(find "$apt_root" -maxdepth 1 -name "openjdk-$major-jdk-headless_*.deb" -print -quit)"
[[ -n "$package_file" ]] || { echo "Matching signed JDK package not downloaded" >&2; exit 1; }
[[ "$(dpkg-deb -f "$package_file" Version)" == "$runtime_version" ]] || {
    echo "JDK package version does not match the installed runtime" >&2; exit 1;
}
package_root="$apt_root/extracted"
dpkg-deb -x "$package_file" "$package_root"
package_jdk="$package_root/usr/lib/jvm/$(basename "$runtime_root")"
[[ -x "$package_jdk/bin/javac" ]] || { echo "JDK package lacks javac" >&2; exit 1; }
mkdir -p "$jdk_root"
cp -a "$runtime_root/." "$jdk_root/"
cp -a "$package_jdk/." "$jdk_root/"
"$jdk_root/bin/javac" -version
