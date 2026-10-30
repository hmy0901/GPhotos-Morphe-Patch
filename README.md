# GPhotos-Morphe-Patch

Google Photos Universal External Media Library Patch.

## Phase 0 development environment

This repository currently contains a Kotlin/JVM scaffold for environment and API checks. It does not download, modify, or distribute Google Photos APKs.

Requirements: JDK 17 or newer to run Gradle 9.8.2. The project compiles to JVM 11 bytecode. An Android SDK is not required for the current JVM-only checks.

```bash
./scripts/install.sh
./scripts/test.sh
```

The official Morphe Patcher artifact is pinned to `app.morphe:morphe-patcher:2.1.0` from GitHub Packages. Its repository documents the need for a GitHub `read:packages` credential even for public packages. Configure `GITHUB_ACTOR` and `GITHUB_TOKEN` (or `gpr.user` / `gpr.key` in the user Gradle properties file), then run:

```bash
./scripts/gradle.sh --no-daemon verifyMorphePatcherApi
```

Never put credentials in repository files. See [docs/environment-check.md](docs/environment-check.md) for the verified toolchain, official source revision, network status, and current blockers.
