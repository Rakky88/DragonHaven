package nl.dragonhaven.app

import android.content.Intent
import android.app.AlarmManager
import android.app.PendingIntent
import android.Manifest
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaPlayer
import android.media.audiofx.LoudnessEnhancer
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import androidx.core.app.NotificationManagerCompat

class MainActivity : FlutterActivity() {
    private data class ScheduledNotification(
        val id: String,
        val at: Long,
        val title: String,
        val body: String,
        val kind: String,
    )

    private var activityInForeground = false
    private var musicEnabled = true
    private var effectsEnabled = true
    private var musicPlayer: MediaPlayer? = null
    private var musicEnhancer: LoudnessEnhancer? = null
    private var musicScene: String? = null
    private var fadeGeneration = 0
    private var notificationPermissionRequestPending = false
    private val notificationsWaitingForPermission = linkedMapOf<String, ScheduledNotification>()
    private val mainHandler = Handler(Looper.getMainLooper())
    private val audioManager by lazy { getSystemService(AUDIO_SERVICE) as AudioManager }
    private val musicAttributes = AudioAttributes.Builder()
        .setUsage(AudioAttributes.USAGE_GAME)
        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
        .build()
    private val effectsAttributes = AudioAttributes.Builder()
        .setUsage(AudioAttributes.USAGE_GAME)
        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
        .build()
    private val audioFocusListener = AudioManager.OnAudioFocusChangeListener { change ->
        when (change) {
            AudioManager.AUDIOFOCUS_GAIN -> {
                if (musicEnabled) {
                    musicPlayer?.let { player ->
                        if (!player.isPlaying) player.start()
                        fadeMusic(player, MUSIC_VOLUME)
                    } ?: musicScene?.let(::startMusic)
                }
            }
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK ->
                musicPlayer?.let { fadeMusic(it, DUCKED_VOLUME) }
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT ->
                musicPlayer?.let { player -> fadeMusic(player, 0f) { player.pause() } }
            AudioManager.AUDIOFOCUS_LOSS -> stopMusic()
        }
    }
    private val audioFocusRequest: AudioFocusRequest? by lazy {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
                .setAudioAttributes(musicAttributes)
                .setOnAudioFocusChangeListener(audioFocusListener)
                .setWillPauseWhenDucked(false)
                .build()
        } else {
            null
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "openUrl" -> {
                    val url = call.argument<String>("url")
                    val uri = url?.let(Uri::parse)
                    if (uri == null || (uri.scheme != "https" && uri.scheme != "http")) {
                        result.error("invalid_url", "Alleen veilige webadressen kunnen worden geopend.", null)
                        return@setMethodCallHandler
                    }
                    try {
                        startActivity(Intent(Intent.ACTION_VIEW, uri))
                        result.success(true)
                    } catch (_: Exception) {
                        result.error("open_failed", "Er is geen app gevonden die deze downloadlink kan openen.", null)
                    }
                }

                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AUDIO_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "setPreferences" -> {
                    val wasMusicEnabled = musicEnabled
                    musicEnabled = call.argument<Boolean>("music") ?: true
                    effectsEnabled = call.argument<Boolean>("effects") ?: true
                    musicScene = call.argument<String>("scene") ?: musicScene
                    if (!musicEnabled) {
                        fadeOutAndStopMusic()
                    } else if (!wasMusicEnabled || musicPlayer == null) {
                        musicScene?.let(::startMusic)
                    }
                    result.success(true)
                }
                "playSound" -> {
                    val id = call.argument<String>("id")
                    result.success(id != null && playOneShot(id))
                }
                "setMusicScene" -> {
                    val id = call.argument<String>("id")
                    musicScene = id
                    if (id != null && musicPlayer != null) {
                        musicPlayer?.let { player ->
                            if (!player.isPlaying) player.start()
                            player.setVolume(MUSIC_VOLUME, MUSIC_VOLUME)
                        }
                        result.success(true)
                    } else {
                        result.success(id != null && startMusic(id))
                    }
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NOTIFICATION_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "schedule" -> {
                    val id = call.argument<String>("id")
                    val at = call.argument<Long>("at")
                    val title = call.argument<String>("title")
                    val body = call.argument<String>("body")
                    val kind = call.argument<String>("kind") ?: "event"
                    if (id == null || at == null || title == null || body == null) {
                        result.error("invalid_notification", "Missing notification data.", null)
                        return@setMethodCallHandler
                    }
                    val notification = ScheduledNotification(id, at, title, body, kind)
                    // Always install a fallback alarm. If the runtime notification
                    // permission is granted from the prompt below, the same
                    // PendingIntent is immediately upgraded to the most precise
                    // alarm Android allows for this device.
                    scheduleNotification(notification)
                    if (!hasNotificationPermission()) {
                        notificationsWaitingForPermission[id] = notification
                        requestNotificationPermissionIfNeeded()
                    }
                    result.success(true)
                }
                "showWhenBackground" -> {
                    val id = call.argument<String>("id")
                    val title = call.argument<String>("title")
                    val body = call.argument<String>("body")
                    val kind = call.argument<String>("kind") ?: "milestone"
                    if (id == null || title == null || body == null) {
                        result.error("invalid_notification", "Missing notification data.", null)
                        return@setMethodCallHandler
                    }
                    if (activityInForeground || !hasNotificationPermission()) {
                        result.success(false)
                        return@setMethodCallHandler
                    }
                    DragonHavenNotificationReceiver.showNow(
                        context = this,
                        notificationId = id.hashCode(),
                        title = title,
                        body = body,
                        kind = kind,
                    )
                    result.success(true)
                }
                "showNow" -> {
                    val id = call.argument<String>("id")
                    val title = call.argument<String>("title")
                    val body = call.argument<String>("body")
                    val kind = call.argument<String>("kind") ?: "event"
                    if (id == null || title == null || body == null) {
                        result.error("invalid_notification", "Missing notification data.", null)
                        return@setMethodCallHandler
                    }
                    if (!hasNotificationPermission()) {
                        result.success(false)
                        return@setMethodCallHandler
                    }
                    DragonHavenNotificationReceiver.showNow(
                        context = this,
                        notificationId = id.hashCode(),
                        title = title,
                        body = body,
                        kind = kind,
                    )
                    result.success(true)
                }
                "cancel" -> {
                    val id = call.argument<String>("id")
                    if (id == null) {
                        result.error("invalid_notification", "Missing notification id.", null)
                        return@setMethodCallHandler
                    }
                    cancelNotification(id)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    // Keep these references explicit. Android's release resource shrinker
    // cannot see resources reached only through getIdentifier(), which used
    // to remove every music track and sound effect from public APKs.
    private fun rawResourceId(id: String): Int = when (id) {
        "achievement" -> R.raw.achievement
        "adventure_return" -> R.raw.adventure_return
        "adventure_start" -> R.raw.adventure_start
        // Higher chest tiers use distinct reveals. Mythical has an original
        // ascending orchestral flourish; Sinister has a low cavernous laugh.
        "chest_dragon" -> R.raw.hatch_reveal
        "chest_dragon_legacy" -> R.raw.chest_dragon
        "chest_gold" -> R.raw.chest_gold
        "chest_mythical" -> R.raw.chest_mythical
        "chest_mythical_legacy" -> R.raw.chest_mythical_legacy
        "chest_silver" -> R.raw.chest_silver
        "chest_sinister" -> R.raw.chest_sinister
        "chest_sinister_legacy" -> R.raw.chest_sinister_legacy
        "chest_wooden" -> R.raw.chest_wooden
        "evolution_ascended" -> R.raw.evolution_ascended
        "evolution_young" -> R.raw.evolution_young
        "floor_built" -> R.raw.floor_built
        "hatch_build" -> R.raw.hatch_build
        "hatch_crack_1" -> R.raw.hatch_crack_1
        "hatch_crack_2" -> R.raw.hatch_crack_2
        "hatch_crack_3" -> R.raw.hatch_crack_3
        "hatch_reveal" -> R.raw.hatch_reveal
        "reveal" -> R.raw.reveal
        "reverie" -> R.raw.reverie
        "room" -> R.raw.room
        "spectral_reveal" -> R.raw.spectral_reveal
        "tower_day" -> R.raw.tower_day
        "tower_night" -> R.raw.tower_night
        "ui_confirm" -> R.raw.ui_confirm
        else -> 0
    }

    private fun hasNotificationPermission(): Boolean =
        Build.VERSION.SDK_INT < 33 ||
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
            android.content.pm.PackageManager.PERMISSION_GRANTED

    private fun requestNotificationPermissionIfNeeded() {
        if (Build.VERSION.SDK_INT < 33 || notificationPermissionRequestPending) return
        notificationPermissionRequestPending = true
        requestPermissions(
            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
            NOTIFICATION_PERMISSION_REQUEST,
        )
    }

    private fun scheduleNotification(notification: ScheduledNotification) {
        val intent = Intent(this, DragonHavenNotificationReceiver::class.java).apply {
            putExtra("title", notification.title)
            putExtra("body", notification.body)
            putExtra("kind", notification.kind)
            putExtra("notificationId", notification.id.hashCode())
        }
        val pending = PendingIntent.getBroadcast(
            this,
            notification.id.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val alarm = getSystemService(ALARM_SERVICE) as AlarmManager
        val exactAllowed = Build.VERSION.SDK_INT < Build.VERSION_CODES.S ||
            alarm.canScheduleExactAlarms()
        if (exactAllowed) {
            try {
                alarm.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    notification.at,
                    pending,
                )
                return
            } catch (_: SecurityException) {
                // Device policy can still reject exact alarms; retain a safe
                // inexact fallback instead of losing the hatch reminder.
            }
        }
        alarm.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, notification.at, pending)
    }

    private fun cancelNotification(id: String) {
        notificationsWaitingForPermission.remove(id)
        val intent = Intent(this, DragonHavenNotificationReceiver::class.java)
        val pending = PendingIntent.getBroadcast(
            this,
            id.hashCode(),
            intent,
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE,
        )
        if (pending != null) {
            val alarm = getSystemService(ALARM_SERVICE) as AlarmManager
            alarm.cancel(pending)
            pending.cancel()
        }
        NotificationManagerCompat.from(this).cancel(id.hashCode())
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != NOTIFICATION_PERMISSION_REQUEST) return
        notificationPermissionRequestPending = false
        if (hasNotificationPermission()) {
            notificationsWaitingForPermission.values.forEach(::scheduleNotification)
        }
        notificationsWaitingForPermission.clear()
    }

    private fun playOneShot(id: String): Boolean {
        if (!effectsEnabled) return false
        val resource = rawResourceId(id)
        if (resource == 0) return false
        val player = MediaPlayer.create(this, resource, effectsAttributes, 0) ?: return false
        player.setVolume(EFFECTS_VOLUME, EFFECTS_VOLUME)
        player.setOnCompletionListener { completed -> completed.release() }
        player.setOnErrorListener { failed, _, _ ->
            failed.release()
            true
        }
        player.start()
        return true
    }

    private fun startMusic(id: String): Boolean {
        if (!musicEnabled) return false
        val resource = rawResourceId("reverie")
        if (resource == 0) return false
        if (!requestMusicFocus()) return false
        releaseMusicPlayer()
        musicPlayer = MediaPlayer.create(this, resource, musicAttributes, 0)?.apply {
            // The bundled tracks are authored as calm ambient loops. Android's
            // native looping avoids the audible pause that completion/restart
            // callbacks introduce between tracks.
            isLooping = true
            setVolume(0f, 0f)
            attachMusicEnhancer(this)
            start()
            fadeMusic(this, MUSIC_VOLUME)
        }
        return musicPlayer != null
    }

    private fun requestMusicFocus(): Boolean {
        val result = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            audioManager.requestAudioFocus(audioFocusRequest!!)
        } else {
            @Suppress("DEPRECATION")
            audioManager.requestAudioFocus(
                audioFocusListener,
                AudioManager.STREAM_MUSIC,
                AudioManager.AUDIOFOCUS_GAIN,
            )
        }
        return result == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
    }

    private fun fadeMusic(
        player: MediaPlayer,
        target: Float,
        onComplete: (() -> Unit)? = null,
    ) {
        val generation = ++fadeGeneration
        val start = if (target == 0f) MUSIC_VOLUME else 0f
        repeat(FADE_STEPS) { index ->
            mainHandler.postDelayed({
                if (generation != fadeGeneration || musicPlayer !== player) return@postDelayed
                val progress = (index + 1).toFloat() / FADE_STEPS
                val volume = start + (target - start) * progress
                player.setVolume(volume, volume)
                if (index == FADE_STEPS - 1) onComplete?.invoke()
            }, FADE_DURATION_MS * (index + 1) / FADE_STEPS)
        }
    }

    private fun fadeOutAndStopMusic() {
        val player = musicPlayer ?: return
        fadeMusic(player, 0f) { stopMusic() }
    }

    private fun releaseMusicPlayer() {
        fadeGeneration++
        musicEnhancer?.runCatching { release() }
        musicEnhancer = null
        musicPlayer?.release()
        musicPlayer = null
    }

    private fun attachMusicEnhancer(player: MediaPlayer) {
        musicEnhancer?.runCatching { release() }
        musicEnhancer = runCatching {
            LoudnessEnhancer(player.audioSessionId).apply {
                setTargetGain(MUSIC_GAIN_MILLIBELS)
                enabled = true
            }
        }.getOrNull()
    }

    private fun stopMusic() {
        releaseMusicPlayer()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            audioFocusRequest?.let(audioManager::abandonAudioFocusRequest)
        } else {
            @Suppress("DEPRECATION")
            audioManager.abandonAudioFocus(audioFocusListener)
        }
    }

    override fun onPause() {
        activityInForeground = false
        musicPlayer?.pause()
        super.onPause()
    }

    override fun onResume() {
        super.onResume()
        activityInForeground = true
        if (musicEnabled) {
            musicPlayer?.let { player ->
                if (!player.isPlaying) player.start()
                player.setVolume(MUSIC_VOLUME, MUSIC_VOLUME)
            } ?: musicScene?.let(::startMusic)
        }
    }

    override fun onDestroy() {
        stopMusic()
        super.onDestroy()
    }

    companion object {
        private const val CHANNEL = "nl.dragonhaven.app/platform"
        private const val AUDIO_CHANNEL = "nl.dragonhaven.app/audio"
        private const val NOTIFICATION_CHANNEL = "nl.dragonhaven.app/notifications"
        private const val NOTIFICATION_PERMISSION_REQUEST = 781
        private const val MUSIC_VOLUME = 1.0f
        private const val DUCKED_VOLUME = 0.30f
        private const val MUSIC_GAIN_MILLIBELS = 1200
        private const val EFFECTS_VOLUME = 0.72f
        private const val FADE_STEPS = 10
        private const val FADE_DURATION_MS = 320L
    }
}
