package nl.dragonhaven.app

import android.content.Intent
import android.app.AlarmManager
import android.app.PendingIntent
import android.Manifest
import android.os.Build
import android.media.MediaPlayer
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var musicEnabled = true
    private var effectsEnabled = true
    private var musicPlayer: MediaPlayer? = null
    private var musicScene: String? = null

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
                    musicEnabled = call.argument<Boolean>("music") ?: true
                    effectsEnabled = call.argument<Boolean>("effects") ?: true
                    if (!musicEnabled) stopMusic() else musicScene?.let(::startMusic)
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
                else -> result.notImplemented()
            }
        }
    }

    private fun rawResourceId(id: String): Int =
        resources.getIdentifier(id, "raw", packageName)

    private fun playOneShot(id: String): Boolean {
        if (!effectsEnabled) return false
        val resource = rawResourceId(id)
        if (resource == 0) return false
        val player = MediaPlayer.create(this, resource) ?: return false
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
        val resource = rawResourceId(id)
        if (resource == 0) return false
        stopMusic()
        musicPlayer = MediaPlayer.create(this, resource)?.apply {
            isLooping = true
            setVolume(0.38f, 0.38f)
            start()
        }
        return musicPlayer != null
    }

    private fun stopMusic() {
        musicPlayer?.stop()
        musicPlayer?.release()
        musicPlayer = null
    }

    override fun onPause() {
        musicPlayer?.pause()
        super.onPause()
    }

    override fun onResume() {
        super.onResume()
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
    }
}
