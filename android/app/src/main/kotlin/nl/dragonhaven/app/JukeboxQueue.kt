package nl.dragonhaven.app

import kotlin.random.Random

/** Playlist state only; lifecycle and Android focus never advance a song. */
internal class JukeboxQueue {
    var tracks = listOf("music_reverie")
        private set
    var shuffle = false
        private set
    var repeat = true
        private set
    private var remaining = mutableListOf<String>()
    private var cycleStarted = false
    private var finished = false

    fun configure(selected: List<String>, shuffle: Boolean, repeat: Boolean, current: String?) {
        if (selected == tracks && shuffle == this.shuffle && repeat == this.repeat) return
        tracks = selected
        this.shuffle = shuffle
        this.repeat = repeat
        // A removed (for example seasonal) song cannot consume a new playlist cycle.
        cycleStarted = current != null && current in tracks
        finished = false
        rebuild(current)
    }

    fun restartIfFinished() {
        if (!finished) return
        finished = false
        cycleStarted = false
        remaining.clear()
    }

    fun next(): String? {
        if (tracks.isEmpty() || finished) return null
        if (remaining.isEmpty()) {
            if (cycleStarted && !repeat) {
                finished = true
                return null
            }
            rebuild(null)
        }
        cycleStarted = true
        return remaining.removeAt(0)
    }

    private fun rebuild(excluding: String?) {
        remaining = tracks.filter { it != excluding }.toMutableList()
        if (shuffle) remaining.shuffle(Random.Default)
    }
}
