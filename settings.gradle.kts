pluginManagement {
    repositories {
        gradlePluginPortal()
        mavenCentral()
    }
}

dependencyResolutionManagement {
    repositories {
        mavenCentral()
        maven {
            name = "MorphePatcher"
            url = uri("https://maven.pkg.github.com/MorpheApp/morphe-patcher")
            credentials {
                username = providers.environmentVariable("GITHUB_ACTOR").orNull
                    ?: providers.gradleProperty("gpr.user").orNull
                password = providers.environmentVariable("GITHUB_TOKEN").orNull
                    ?: providers.environmentVariable("GH_TOKEN").orNull
                    ?: providers.gradleProperty("gpr.key").orNull
            }
        }
    }
}

rootProject.name = "gphotos-morphe-patch"

// The setup script pins and verifies these official source checkouts. The
// Patcher build itself includes sibling ARSCLib and smali builds.
val morpheSources = file(".gradle/morphe-sources")
val patcherSource = morpheSources.resolve("morphe-patcher")
if (providers.gradleProperty("skipMorpheSourceComposite").orNull != "true" &&
    patcherSource.resolve("settings.gradle.kts").isFile
) {
    includeBuild(patcherSource) {
        dependencySubstitution {
            substitute(module("app.morphe:morphe-patcher")).using(project(":"))
        }
    }
}
