import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    kotlin("jvm") version "2.4.21"
}

group = "dev.hmy0901.gphotospatch"
version = "0.1.0-SNAPSHOT"

kotlin {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_11)
    }
}

java {
    targetCompatibility = JavaVersion.VERSION_11
}

val morphePatcherApi = configurations.create("morphePatcherApi") {
    isCanBeConsumed = false
    isCanBeResolved = true
}

val morpheApiProbe = sourceSets.create("morpheApiProbe")

dependencies {
    testImplementation(kotlin("test-junit5"))
    testRuntimeOnly("org.junit.jupiter:junit-jupiter-engine:5.10.1")

    // Kept separate from the default compile/test classpaths because GitHub Packages
    // requires read:packages authentication. Resolve it explicitly with
    // `./scripts/gradle.sh verifyMorphePatcherApi` after configuring GITHUB_ACTOR and a token.
    add(morphePatcherApi.name, "app.morphe:morphe-patcher:2.1.0")
    add(morpheApiProbe.implementationConfigurationName, "app.morphe:morphe-patcher:2.1.0")
}

tasks.register("verifyMorpheSourceApi") {
    group = "verification"
    description = "Compiles a direct reference to the official Morphe Patcher API."
    dependsOn("compileMorpheApiProbeKotlin")
}

tasks.test {
    useJUnitPlatform()
}

tasks.register("verifyMorphePatcherApi") {
    group = "verification"
    description = "Resolves the official Morphe Patcher 2.1.0 API artifact from GitHub Packages."

    doLast {
        if (providers.gradleProperty("skipMorpheSourceComposite").orNull != "true" &&
            rootProject.file(".gradle/morphe-sources/morphe-patcher/settings.gradle.kts").isFile
        ) {
            throw GradleException(
                "Run with -PskipMorpheSourceComposite=true to check GitHub Packages; " +
                    "otherwise the local source build would satisfy this dependency."
            )
        }
        val actor = providers.environmentVariable("GITHUB_ACTOR").orNull
            ?: providers.gradleProperty("gpr.user").orNull
        val token = providers.environmentVariable("GITHUB_TOKEN").orNull
            ?: providers.environmentVariable("GH_TOKEN").orNull
            ?: providers.gradleProperty("gpr.key").orNull

        if (actor.isNullOrBlank() || token.isNullOrBlank()) {
            throw GradleException(
                "Set GITHUB_ACTOR and GITHUB_TOKEN (or gpr.user/gpr.key in ~/.gradle/gradle.properties). " +
                    "Morphe documents read:packages authentication even for public packages."
            )
        }

        val resolved = morphePatcherApi.resolve()
        check(resolved.any { it.name.startsWith("morphe-patcher-2.1.0") }) {
            "The official Morphe Patcher 2.1.0 artifact was not resolved."
        }
        logger.lifecycle("Resolved official Morphe Patcher 2.1.0 API artifact.")
    }
}
