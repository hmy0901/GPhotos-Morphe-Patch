package dev.hmy0901.gphotospatch

import app.morphe.patcher.Patcher

/** Compile-only proof that the real Morphe Patcher public API is available. */
internal fun officialPatcherType(): Class<Patcher> = Patcher::class.java
