package dev.hmy0901.gphotospatch

/** A small build-time utility that validates Maven coordinates used by this project. */
data class ArtifactCoordinate(
    val group: String,
    val artifact: String,
    val version: String,
) {
    init {
        require(group.isNotBlank()) { "Maven group must not be blank" }
        require(artifact.isNotBlank()) { "Maven artifact must not be blank" }
        require(version.isNotBlank()) { "Maven version must not be blank" }
    }

    override fun toString(): String = "$group:$artifact:$version"

    companion object {
        fun parse(value: String): ArtifactCoordinate {
            val parts = value.split(':')
            require(parts.size == 3) { "Expected Maven coordinate group:artifact:version" }
            return ArtifactCoordinate(parts[0], parts[1], parts[2])
        }
    }
}
