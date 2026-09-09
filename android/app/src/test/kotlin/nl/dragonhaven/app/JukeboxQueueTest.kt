package nl.dragonhaven.app

import org.junit.Assert.*
import org.junit.Test

class JukeboxQueueTest {
    @Test fun replacingEventRestoresEverySelectedTrackWithoutRepeat() {
        val q = JukeboxQueue()
        q.configure(listOf("event"), false, false, null)
        assertEquals("event", q.next())
        q.configure(listOf("reverie", "newly_collected"), false, false, "event")
        assertEquals("reverie", q.next())
        assertEquals("newly_collected", q.next())
        assertNull(q.next())
    }

    @Test fun selectionChangesKeepCurrentAndPlayEachRemainingTrackOnce() {
        val q = JukeboxQueue()
        q.configure(listOf("a", "b"), false, false, null)
        assertEquals("a", q.next())
        q.configure(listOf("a", "b", "c"), false, false, "a")
        assertEquals("b", q.next())
        assertEquals("c", q.next())
        assertNull(q.next())
        assertNull(q.next())
        q.restartIfFinished()
        assertEquals("a", q.next())
    }

    @Test fun unchangedKeepalivesDoNotResetNonRepeatingCycle() {
        val q = JukeboxQueue()
        q.configure(listOf("a", "b"), false, false, null)
        assertEquals("a", q.next())
        q.configure(listOf("a", "b"), false, false, "a")
        assertEquals("b", q.next())
        assertNull(q.next())
        q.configure(listOf("a", "b"), false, false, null)
        assertNull(q.next())
    }

    @Test fun allOffThenOnAndRepeatingShufflePlayCompleteCycles() {
        val q = JukeboxQueue()
        q.configure(emptyList(), false, false, null)
        assertNull(q.next())
        q.configure(listOf("a", "b", "c"), true, true, null)
        repeat(5) {
            assertEquals(setOf("a", "b", "c"), (1..3).map { q.next() }.toSet())
        }
    }
}
