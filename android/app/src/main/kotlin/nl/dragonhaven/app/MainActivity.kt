package nl.dragonhaven.app

import android.content.Intent
import android.app.AlarmManager
import android.app.PendingIntent
import android.Manifest
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
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
import kotlin.random.Random

class MainActivity : FlutterActivity() {
    private data class ScheduledNotification(
        val id: String,
        val at: Long,
        val title: String,
        val body: String,
        val kind: String,
    )

    private var activityInForeground = false
    // Stay silent until Flutter has loaded and sent the persisted preference.
    private var musicEnabled = false
    private var effectsEnabled = true
    private var musicPlayer: MediaPlayer? = null
    private var musicEnhancer: LoudnessEnhancer? = null
    private var musicScene: String? = null
    private var jukeboxTracks = listOf("music_reverie")
    private var jukeboxQueue = mutableListOf<String>()
    private var jukeboxShuffle = false
    private var jukeboxRepeat = true
    private var jukeboxCycleStarted = false
    private var jukeboxFinished = false
    private var currentMusicTrack: String? = null
    private var fadeGeneration = 0
    private var notificationPermissionRequestPending = false
    private var notificationChannel: MethodChannel? = null
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
                    } ?: startNextMusic()
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
                    val tracks = call.argument<List<String>>("tracks")
                    if (tracks != null) {
                        updateJukebox(
                            tracks,
                            call.argument<Boolean>("shuffle") ?: jukeboxShuffle,
                            call.argument<Boolean>("repeat") ?: jukeboxRepeat,
                        )
                    }
                    if (!musicEnabled) {
                        fadeOutAndStopMusic()
                    } else if (musicPlayer == null) {
                        if (!wasMusicEnabled) jukeboxFinished = false
                        startNextMusic()
                    }
                    result.success(true)
                }
                "setJukebox" -> {
                    updateJukebox(
                        call.argument<List<String>>("tracks") ?: emptyList(),
                        call.argument<Boolean>("shuffle") ?: false,
                        call.argument<Boolean>("repeat") ?: true,
                    )
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
                        result.success(id != null && startNextMusic())
                    }
                }
                else -> result.notImplemented()
            }
        }

        notificationChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            NOTIFICATION_CHANNEL,
        ).also { channel -> channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "takePendingNavigation" -> {
                    val kind = intent?.getStringExtra(NOTIFICATION_KIND_EXTRA)
                    intent?.removeExtra(NOTIFICATION_KIND_EXTRA)
                    result.success(kind)
                }
                "permissionGranted" -> result.success(hasNotificationPermission())
                "openNotificationSettings" -> {
                    try {
                        startActivity(
                            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                                putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                            },
                        )
                        result.success(true)
                    } catch (_: Exception) {
                        result.success(false)
                    }
                }
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
        } }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val kind = intent.getStringExtra(NOTIFICATION_KIND_EXTRA) ?: return
        intent.removeExtra(NOTIFICATION_KIND_EXTRA)
        notificationChannel?.invokeMethod("notificationTap", mapOf("kind" to kind))
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
        "chest_special" -> R.raw.chest_special
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
        "music_clair_de_lune" -> R.raw.music_clair_de_lune
        "music_arabesque_1" -> R.raw.music_arabesque_1
        "music_reverie" -> R.raw.music_reverie
        "music_flaxen_hair" -> R.raw.music_flaxen_hair
        "music_golliwoggs_cakewalk" -> R.raw.music_golliwoggs_cakewalk
        "music_gymnopedie_1" -> R.raw.music_gymnopedie_1
        "music_gymnopedie_2" -> R.raw.music_gymnopedie_2
        "music_gymnopedie_3" -> R.raw.music_gymnopedie_3
        "music_gnossienne_1" -> R.raw.music_gnossienne_1
        "music_gnossienne_3" -> R.raw.music_gnossienne_3
        "music_je_te_veux" -> R.raw.music_je_te_veux
        "music_fur_elise" -> R.raw.music_fur_elise
        "music_moonlight_1" -> R.raw.music_moonlight_1
        "music_moonlight_3" -> R.raw.music_moonlight_3
        "music_pathetique_2" -> R.raw.music_pathetique_2
        "music_ode_to_joy" -> R.raw.music_ode_to_joy
        "music_symphony_5_1" -> R.raw.music_symphony_5_1
        "music_symphony_7_2" -> R.raw.music_symphony_7_2
        "music_eine_kleine_nachtmusik" -> R.raw.music_eine_kleine_nachtmusik
        "music_rondo_alla_turca" -> R.raw.music_rondo_alla_turca
        "music_symphony_40_1" -> R.raw.music_symphony_40_1
        "music_sonata_k545_1" -> R.raw.music_sonata_k545_1
        "music_lacrimosa" -> R.raw.music_lacrimosa
        "music_dies_irae" -> R.raw.music_dies_irae
        "music_ave_verum" -> R.raw.music_ave_verum
        "music_canon_in_d" -> R.raw.music_canon_in_d
        "music_air_g_string" -> R.raw.music_air_g_string
        "music_prelude_c_major" -> R.raw.music_prelude_c_major
        "music_toccata_fugue_d_minor" -> R.raw.music_toccata_fugue_d_minor
        "music_cello_suite_1_prelude" -> R.raw.music_cello_suite_1_prelude
        "music_jesu_joy" -> R.raw.music_jesu_joy
        "music_badinerie" -> R.raw.music_badinerie
        "music_minuet_g_major" -> R.raw.music_minuet_g_major
        "music_spring" -> R.raw.music_spring
        "music_summer_presto" -> R.raw.music_summer_presto
        "music_autumn_1" -> R.raw.music_autumn_1
        "music_winter_1" -> R.raw.music_winter_1
        "music_winter_2" -> R.raw.music_winter_2
        "music_sugar_plum" -> R.raw.music_sugar_plum
        "music_waltz_flowers" -> R.raw.music_waltz_flowers
        "music_trepak" -> R.raw.music_trepak
        "music_swan_lake_scene" -> R.raw.music_swan_lake_scene
        "music_sleeping_beauty_waltz" -> R.raw.music_sleeping_beauty_waltz
        "music_1812_finale" -> R.raw.music_1812_finale
        "music_mountain_king" -> R.raw.music_mountain_king
        "music_morning_mood" -> R.raw.music_morning_mood
        "music_anitras_dance" -> R.raw.music_anitras_dance
        "music_solveigs_song" -> R.raw.music_solveigs_song
        "music_nocturne_9_2" -> R.raw.music_nocturne_9_2
        "music_prelude_28_4" -> R.raw.music_prelude_28_4
        "music_raindrop_prelude" -> R.raw.music_raindrop_prelude
        "music_minute_waltz" -> R.raw.music_minute_waltz
        "music_funeral_march" -> R.raw.music_funeral_march
        "music_fantaisie_impromptu" -> R.raw.music_fantaisie_impromptu
        "music_hungarian_dance_5" -> R.raw.music_hungarian_dance_5
        "music_hungarian_dance_6" -> R.raw.music_hungarian_dance_6
        "music_lullaby" -> R.raw.music_lullaby
        "music_blue_danube" -> R.raw.music_blue_danube
        "music_tritsch_tratsch" -> R.raw.music_tritsch_tratsch
        "music_radetzky_march" -> R.raw.music_radetzky_march
        "music_can_can" -> R.raw.music_can_can
        "music_barcarolle" -> R.raw.music_barcarolle
        "music_ride_valkyries" -> R.raw.music_ride_valkyries
        "music_bridal_chorus" -> R.raw.music_bridal_chorus
        "music_bumblebee" -> R.raw.music_bumblebee
        "music_scheherazade_prince_princess" -> R.raw.music_scheherazade_prince_princess
        "music_procession_nobles" -> R.raw.music_procession_nobles
        "music_entertainer" -> R.raw.music_entertainer
        "music_maple_leaf_rag" -> R.raw.music_maple_leaf_rag
        "music_easy_winners" -> R.raw.music_easy_winners
        "music_solace" -> R.raw.music_solace
        "music_elite_syncopations" -> R.raw.music_elite_syncopations
        "music_greensleeves" -> R.raw.music_greensleeves
        "music_scarborough_fair" -> R.raw.music_scarborough_fair
        "music_drunken_sailor" -> R.raw.music_drunken_sailor
        "music_irish_washerwoman" -> R.raw.music_irish_washerwoman
        "music_korobeiniki" -> R.raw.music_korobeiniki
        "music_house_rising_sun" -> R.raw.music_house_rising_sun
        "music_amazing_grace" -> R.raw.music_amazing_grace
        "music_auld_lang_syne" -> R.raw.music_auld_lang_syne
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
        if (
            Build.VERSION.SDK_INT < 33 ||
            notificationPermissionRequestPending ||
            !activityInForeground ||
            !mayAutomaticallyRequestNotificationPermission()
        ) return
        notificationPermissionRequestPending = true
        notificationPreferences.edit()
            .putBoolean(NOTIFICATION_PERMISSION_PROMPT_HANDLED, true)
            .apply()
        // Scheduling can happen while Flutter is still restoring the saved
        // game. Wait until the Activity is fully resumed before showing the
        // one-time Android prompt; some Android 15 devices otherwise push the
        // app behind the launcher when PermissionController rejects it.
        mainHandler.postDelayed({
            if (!activityInForeground || isFinishing || isDestroyed) {
                notificationPermissionRequestPending = false
                return@postDelayed
            }
            requestPermissions(
                arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                NOTIFICATION_PERMISSION_REQUEST,
            )
        }, NOTIFICATION_PERMISSION_PROMPT_DELAY_MS)
    }

    private val notificationPreferences by lazy {
        getSharedPreferences(NOTIFICATION_PERMISSION_PREFERENCES, MODE_PRIVATE)
    }

    private fun mayAutomaticallyRequestNotificationPermission(): Boolean {
        if (notificationPreferences.getBoolean(
                NOTIFICATION_PERMISSION_PROMPT_HANDLED,
                false,
            )
        ) return false
        if (shouldShowRequestPermissionRationale(Manifest.permission.POST_NOTIFICATIONS)) {
            notificationPreferences.edit()
                .putBoolean(NOTIFICATION_PERMISSION_PROMPT_HANDLED, true)
                .apply()
            return false
        }
        // Older versions already asked automatically. On an upgraded install,
        // treating a missing local marker as a fresh request made every cold
        // start re-open PermissionController after the user had denied it.
        val packageInfo = packageManager.getPackageInfo(packageName, 0)
        if (packageInfo.lastUpdateTime > packageInfo.firstInstallTime) {
            notificationPreferences.edit()
                .putBoolean(NOTIFICATION_PERMISSION_PROMPT_HANDLED, true)
                .apply()
            return false
        }
        return true
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

    private fun updateJukebox(tracks: List<String>, shuffle: Boolean, repeat: Boolean) {
        val cleaned = tracks.distinct().filter { rawResourceId(it) != 0 }
        val changed = cleaned != jukeboxTracks ||
            shuffle != jukeboxShuffle || repeat != jukeboxRepeat
        if (!changed) return
        jukeboxTracks = cleaned
        jukeboxShuffle = shuffle
        jukeboxRepeat = repeat
        jukeboxCycleStarted = currentMusicTrack != null
        jukeboxFinished = false
        rebuildJukeboxQueue(excluding = currentMusicTrack)
        if (cleaned.isEmpty()) {
            fadeOutAndStopMusic()
        } else if (currentMusicTrack !in cleaned) {
            releaseMusicPlayer()
            startNextMusic()
        }
    }

    private fun rebuildJukeboxQueue(excluding: String? = null) {
        jukeboxQueue = jukeboxTracks.filter { it != excluding }.toMutableList()
        if (jukeboxShuffle) jukeboxQueue.shuffle(Random.Default)
    }

    private fun startNextMusic(): Boolean {
        if (!musicEnabled || jukeboxTracks.isEmpty() || jukeboxFinished) return false
        if (jukeboxQueue.isEmpty()) {
            if (jukeboxCycleStarted && !jukeboxRepeat) {
                jukeboxFinished = true
                releaseMusicPlayer()
                return false
            }
            rebuildJukeboxQueue()
            jukeboxCycleStarted = true
        }
        if (jukeboxQueue.isEmpty()) return false
        val next = jukeboxQueue.removeAt(0)
        return startMusic(next)
    }

    private fun startMusic(trackId: String): Boolean {
        if (!musicEnabled) return false
        val resource = rawResourceId(trackId)
        if (resource == 0) return false
        if (!requestMusicFocus()) return false
        releaseMusicPlayer()
        currentMusicTrack = trackId
        musicPlayer = MediaPlayer.create(this, resource, musicAttributes, 0)?.apply {
            isLooping = false
            setVolume(0f, 0f)
            attachMusicEnhancer(this)
            setOnCompletionListener { completed ->
                if (musicPlayer !== completed) return@setOnCompletionListener
                releaseMusicPlayer()
                startNextMusic()
            }
            setOnErrorListener { failed, _, _ ->
                if (musicPlayer === failed) releaseMusicPlayer()
                startNextMusic()
                true
            }
            start()
            fadeMusic(this, MUSIC_VOLUME)
        }
        if (musicPlayer == null) currentMusicTrack = null
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
        currentMusicTrack = null
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
        if (notificationsWaitingForPermission.isNotEmpty()) {
            requestNotificationPermissionIfNeeded()
        }
        if (musicEnabled) {
            musicPlayer?.let { player ->
                if (!player.isPlaying) player.start()
                player.setVolume(MUSIC_VOLUME, MUSIC_VOLUME)
            } ?: startNextMusic()
        }
    }

    override fun onDestroy() {
        stopMusic()
        super.onDestroy()
    }

    companion object {
        const val NOTIFICATION_KIND_EXTRA = "dragonhaven.notification_kind"
        private const val CHANNEL = "nl.dragonhaven.app/platform"
        private const val AUDIO_CHANNEL = "nl.dragonhaven.app/audio"
        private const val NOTIFICATION_CHANNEL = "nl.dragonhaven.app/notifications"
        private const val NOTIFICATION_PERMISSION_PREFERENCES =
            "dragonhaven_notification_permission"
        private const val NOTIFICATION_PERMISSION_PROMPT_HANDLED =
            "post_notifications_prompt_handled"
        private const val NOTIFICATION_PERMISSION_PROMPT_DELAY_MS = 750L
        private const val NOTIFICATION_PERMISSION_REQUEST = 781
        private const val MUSIC_VOLUME = 1.0f
        private const val DUCKED_VOLUME = 0.30f
        private const val MUSIC_GAIN_MILLIBELS = 1200
        private const val EFFECTS_VOLUME = 0.72f
        private const val FADE_STEPS = 10
        private const val FADE_DURATION_MS = 320L
    }
}
