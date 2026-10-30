# Codex Cloud environment check

This report records the Phase 0 setup performed on the isolated cloud machine for commit `4c86b1772b85ba823d661ab5146aea6e51d3ab50`, on branch `chore/cloud-development-environment`.

## Repository and branch inventory

- The selected repository had one remote branch, `origin/main`, at `4c86b1772b85ba823d661ab5146aea6e51d3ab50` before setup. No other branch or development commits were present.
- GitHub read access was verified with `git ls-remote origin HEAD` and `git ls-remote --heads origin`.
- Phase 0 changes are isolated on `chore/cloud-development-environment`; `main` was not modified.

## Official Morphe Patcher research

Sources inspected directly from the official [`MorpheApp/morphe-patcher`](https://github.com/MorpheApp/morphe-patcher) repository at source commit `f3997dc1011b84a301c1ffe426fd9dfdd85095ba`:

- The README documents Maven coordinate `app.morphe:morphe-patcher:$version` and GitHub Packages as the artifact repository.
- That source commit's `gradle.properties` declares Patcher version `2.1.0`; its wrapper pins Gradle `9.8.2` with SHA-256 verification.
- Its version catalog pins Kotlin `2.4.21`; its build compiles library bytecode to JVM 11. Official CI runs Gradle on JDK 17 and tests against JDK 11, 17, and 25.
- The public API dump contains `app.morphe.patcher.Patcher`, `PatcherConfig`, `PatcherContext`, and `PatcherResult`.
- The official runtime dependency catalog includes Bouncy Castle `bcpkix-jdk18on:1.77`, Android tools `apksig`/`apkzlib:9.1.1`, ARSCLib commit `4695b583ef`, Guava `33.5.0-jre`, Kotlin reflection `2.4.21`, coroutines `1.10.2`, serialization JSON `1.12.0`, and Morphe's smali commit `ac700e1942`. It uses Android API stubs `com.google.android:android:4.1.1.4` as compile-only. Its test dependencies include MockK `1.14.11`, Kotlin test, and JUnit Jupiter `5.10.1`.
- The official setup guide states GitHub Packages authentication with `read:packages` is required even for public packages. No credential values are stored in this repository.

### Artifact access result

The official source was cloned successfully through the existing GitHub HTTPS proxy. Requests to `maven.pkg.github.com` did not reach Maven: curl reported `CONNECT tunnel failed, response 403` (HTTP status `000`). The current allowlist does not include `maven.pkg.github.com`. This is an egress-policy block, not an HTTP 401 from GitHub Packages, so the available token's package scope could not yet be evaluated. After allowing that host, retry `./scripts/gradle.sh --no-daemon -PskipMorpheSourceComposite=true verifyMorphePatcherApi`; if GitHub returns 401, use a GitHub credential with `read:packages` and a matching `GITHUB_ACTOR` as described by Morphe's official setup instructions.

## Machine toolchain

- Java: OpenJDK `21.0.12.1` present; compatible with Gradle's JDK 17+ runtime requirement.
- Gradle: no system Gradle was installed at inspection time. This project now includes the official Gradle 9.8.2 wrapper and its distribution checksum.
- Android SDK / Build Tools: `adb`, `sdkmanager`, `ANDROID_HOME`, and `ANDROID_SDK_ROOT` were absent. This Phase 0 JVM scaffold does not apply the Android Gradle Plugin or build an APK, so an Android SDK is not required for its current compile/test tasks.
- GitHub source access: PASS. Maven Central root access: PASS. Morphe GitHub Packages: BLOCKED by the current network allowlist before authentication.

## Setup files and current verification

- `./scripts/install.sh` checks Java 17+ and runs the Gradle wrapper plus JVM tests.
- `./scripts/test.sh` reruns the JVM unit tests on every call, even when Gradle's task cache is warm.
- `scripts/gradle.sh` translates the cloud's `HTTPS_PROXY`/`HTTP_PROXY` host and port to JVM proxy properties; Java and Gradle do not consume those curl-style variables automatically.
- `./scripts/gradle.sh --no-daemon -PskipMorpheSourceComposite=true verifyMorphePatcherApi` is an explicit authenticated artifact check; it is separate from ordinary compilation/tests so local JVM setup remains usable while GitHub Packages access is being configured.
- No Google Photos APK was downloaded or modified.

## Verification result

- `./scripts/install.sh`: PASS. Gradle 9.8.2 distribution was downloaded from the official Gradle distribution endpoint and accepted only after the wrapper's pinned SHA-256 check. Kotlin compilation and JVM unit tests completed with `BUILD SUCCESSFUL`.
- The unit test suite contains two JVM tests covering valid Maven coordinate parsing and rejection of malformed/empty coordinates.
- `./scripts/test.sh`: PASS. Independent run completed 2 tests, 0 failures, 0 errors, 0 skipped.
- Final `./scripts/install.sh` run: PASS. It verified Gradle 9.8.2, compiled Kotlin/JVM sources, and reran both JVM tests successfully.
- `./scripts/gradle.sh -PskipMorpheSourceComposite=true verifyMorphePatcherApi`: BLOCKED pending the allowed-domain update and confirmation that the available credential has GitHub Packages `read:packages` access.

## Phase 0.2: official source integration

All source checkouts are under the ignored `.gradle/morphe-sources` directory. No third-party source, jar, token, or APK is committed. `./scripts/setup-morphe-sources.sh` fetches and verifies the following official commits and refuses to reuse a checkout with another origin, HEAD, or local changes:

| Repository | Pinned commit |
| --- | --- |
| `MorpheApp/morphe-patcher` | `f3997dc1011b84a301c1ffe426fd9dfdd85095ba` |
| `MorpheApp/ARSCLib` | `4695b583ef51890ce283f3f2e0f6f63dff230ef0` |
| `MorpheApp/smali` | `ac700e1942d26a7374166dce35f6da049a10e1a5` |

The unmodified Patcher `settings.gradle.kts` includes sibling ARSCLib and smali as Gradle composite builds. Its `build.gradle.kts` declares `mavenLocal()`, Maven Central, Google Maven, JitPack, and a dummy Morphe GitHub Packages registry. ARSCLib and smali use Maven Central for their own build dependencies; smali requires JGit `6.10.0.202406032230-r`. The composite builds replace the JitPack ARSCLib/smali coordinates with compilation of the pinned source. Direct curl requests to `jitpack.io` and `maven.pkg.github.com` returned proxy CONNECT 403, while Maven Central and Google Maven responded. The successful composite build did not require GitHub Packages.

The machine initially had Java 21 runtime modules but no `javac`. Without a complete JDK, composite `assemble` failed at `:ARSCLib:compileJava` and `:smali:dexlib2:compileJava` with `JAVA_COMPILER` unavailable. `./scripts/prepare-morphe-jdk.sh` downloaded the matching Debian `openjdk-21-jdk-headless` package through signed apt metadata, verified its version against the installed runtime, and assembled a complete JDK in the ignored cache. `javac 21.0.12.1` then ran successfully. An initial offline composite attempt also failed because JGit was not yet cached; the subsequent online build resolved it.

| Layer | Command and observed result |
| --- | --- |
| L1 source | `./scripts/setup-morphe-sources.sh` fetched all three full SHAs above through GitHub HTTPS: **PASS**. |
| L2 dependencies | Online `./gradlew --no-daemon --max-workers=2 assemble` in the isolated official Patcher checkout, with sibling composite builds and a complete JDK, resolved required dependencies: **PASS**. |
| L3 official build | The same official `assemble` completed with `BUILD SUCCESSFUL` (12 actionable tasks; ARSCLib/smali compiled): **PASS**. |
| L4 real API compile | `./scripts/build-morphe-source.sh` assembled the pinned official source and ran `verifyMorpheSourceApi`; `compileMorpheApiProbeKotlin` compiled a direct import of `app.morphe.patcher.Patcher` with `BUILD SUCCESSFUL`: **PASS**. |
| L5 existing tests | `./scripts/test.sh` reran Kotlin/JVM compilation and 2 tests with 0 failures, 0 errors, 0 skipped: **PASS**. |

`./scripts/build-morphe-source.sh` is the repeatable entry point. It fetches the pinned official source, prepares a matching complete JDK when needed, runs the official `assemble`, and compiles this project's API probe through a Gradle composite substitution. It was run successfully with the default project cache and no published Cloud settings. `verifyMorphePatcherApi` remains a separate GitHub Packages check; use `-PskipMorpheSourceComposite=true` so that it cannot mistakenly pass by resolving the local source build.
