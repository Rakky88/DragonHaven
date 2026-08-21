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
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var activityInForeground = false
    private var musicEnabled = true
    private var effectsEnabled = true
    private var musicPlayer: MediaPlayer? = null
    private var musicScene: String? = null
    private var musicTrackIndex = 0
    private var fadeGeneration = 0
    private val mainHandler = Handler(Looper.getMainLooper())
    private val audioManager by lazy { getSystemService(AUDIO_SERVICE) as AudioManager }
    private val musicAttributes = AudioAttributes.Builder()
        .setUsage(AudioAttributes.USAGE_GAME)
        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
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
                    result.success(id != null && startMusic(id))
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
                    if (id == null || at == null || title == null || body == null) {
                        result.error("invalid_notification", "Missing notification data.", null)
                        return@setMethodCallHandler
                    }
                    if (Build.VERSION.SDK_INT >= 33 &&
                        checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != android.content.pm.PackageManager.PERMISSION_GRANTED) {
                        requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 781)
                    }
                    val intent = Intent(this, DragonHavenNotificationReceiver::class.java).apply {
                        putExtra("title", title)
                        putExtra("body", body)
                        putExtra("notificationId", id.hashCode())
                    }
                    val pending = PendingIntent.getBroadcast(
                        this,
                        id.hashCode(),
                        intent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                    )
                    val alarm = getSystemService(ALARM_SERVICE) as AlarmManager
                    alarm.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pending)
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
                else -> result.notImplemented()
            }
        }
    }

    private fun rawResourceId(id: String): Int =
        resources.getIdentifier(id, "raw", packageName)

    private fun hasNotificationPermission(): Boolean =
        Build.VERSION.SDK_INT < 33 ||
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
            android.content.pm.PackageManager.PERMISSION_GRANTED

    private fun playOneShot(id: String): Boolean {
        if (!effectsEnabled) return false
        val resource = rawResourceId(id)
        if (resource == 0) return false
        val player = MediaPlayer.create(this, resource) ?: return false
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
        val choices = when (id) {
            "tower_day" -> listOf("tower_day", "room")
            "tower_night" -> listOf("tower_night", "room")
            "room" -> listOf("room", "tower_day")
            else -> listOf(id)
        }
        val resource = rawResourceId(choices[musicTrackIndex++ % choices.size])
        if (resource == 0) return false
        if (!requestMusicFocus()) return false
        releaseMusicPlayer()
        musicPlayer = MediaPlayer.create(this, resource)?.apply {
            isLooping = false
            setVolume(0f, 0f)
            setOnCompletionListener { completed ->
                if (musicPlayer === completed) {
                    releaseMusicPlayer()
                    if (musicEnabled && musicScene == id) {
                        mainHandler.postDelayed({ startMusic(id) }, 900)
                    }
                } else {
                    completed.release()
                }
            }
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
        musicPlayer?.release()
        musicPlayer = null
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
        if (musicEnabled && musicPlayer?.isPlaying == false) musicPlayer?.start()
    }

    override fun onDestroy() {
        stopMusic()
        super.onDestroy()
    }

    companion object {
        private const val CHANNEL = "nl.dragonhaven.app/platform"
        private const val AUDIO_CHANNEL = "nl.dragonhaven.app/audio"
        private const val NOTIFICATION_CHANNEL = "nl.dragonhaven.app/notifications"
        private const val MUSIC_VOLUME = 0.34f
        private const val DUCKED_VOLUME = 0.10f
        private const val EFFECTS_VOLUME = 0.72f
        private const val FADE_STEPS = 10
        private const val FADE_DURATION_MS = 320L
    }
}
