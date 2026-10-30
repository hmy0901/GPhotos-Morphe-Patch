package dev.hmy0901.gphotospatch

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith

class ArtifactCoordinateTest {
    @Test
    fun `parses Maven coordinates without changing components`() {
        val coordinate = ArtifactCoordinate.parse("app.morphe:morphe-patcher:2.1.0")

        assertEquals("app.morphe", coordinate.group)
        assertEquals("morphe-patcher", coordinate.artifact)
        assertEquals("2.1.0", coordinate.version)
        assertEquals("app.morphe:morphe-patcher:2.1.0", coordinate.toString())
    }

    @Test
    fun `rejects incomplete or empty Maven coordinates`() {
        assertFailsWith<IllegalArgumentException> { ArtifactCoordinate.parse("app.morphe:morphe-patcher") }
        assertFailsWith<IllegalArgumentException> { ArtifactCoordinate.parse("app.morphe::2.1.0") }
    }
}
