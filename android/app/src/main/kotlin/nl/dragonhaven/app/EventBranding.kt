package nl.dragonhaven.app

import android.app.AlarmManager
import android.app.Activity
import android.app.Application
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import org.json.JSONArray
import org.json.JSONObject

/** Local, cosmetic calendar. Never needs a network call or an exact-alarm grant. */
object EventBranding {
    private val logos = setOf("default", "halloween", "christmas", "new_year", "valentine", "pride", "golden_wings", "sunwake", "harvestmoon")
    private const val PREFS = "dragonhaven_event_branding"
    private const val REQUEST = 7047
    // Disabling the alias of a visible task can finish that task even with
    // DONT_KILL_APP. Include SDK activities such as AdActivity in this guard.
    var activityVisible = false

    fun setSchedule(context: Context, values: List<*>) {
        require(values.size <= 64) { "Too many event windows" }
        val schedule = JSONArray()
        for (value in values) {
            val row = value as? Map<*, *> ?: throw IllegalArgumentException("Invalid event window")
            val logo = row["logo"] as? String
            val key = row["key"] as? String
            val start = (row["start"] as? Number)?.toLong()
            val end = (row["end"] as? Number)?.toLong()
            require(logo in logos && logo != "default" && key != null && key.length <= 160 &&
                start != null && end != null && start >= 0 && end > start) { "Invalid event window" }
            schedule.put(JSONObject().put("logo", logo).put("key", key)
                .put("start", start).put("end", end).put("preview", row["preview"] == true))
        }
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .putString("windows", schedule.toString()).apply()
        refresh(context)
    }

    private fun windows(context: Context): List<JSONObject> = runCatching {
        val raw = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString("windows", "[]")
        val array = JSONArray(raw)
        (0 until array.length().coerceAtMost(64)).map { array.getJSONObject(it) }
            .filter { it.optString("logo") in logos && it.optLong("end") > it.optLong("start") }
    }.getOrDefault(emptyList())

    fun selectedLogo(context: Context, now: Long = System.currentTimeMillis()): String =
        windows(context).filter { it.optLong("start") <= now && now < it.optLong("end") }
            .sortedWith(compareBy<JSONObject> { if (it.optBoolean("preview")) 0 else 1 }
                .thenByDescending { it.optLong("start") }.thenBy { it.optString("key") })
            .firstOrNull()?.optString("logo") ?: "default"

    fun refresh(context: Context) {
        val now = System.currentTimeMillis()
        val selected = selectedLogo(context, now)
        val manager = context.packageManager
        val changes = logos.map { logo ->
            ComponentName(context, "${context.packageName}.Launcher_$logo") to
                if (logo == selected) PackageManager.COMPONENT_ENABLED_STATE_ENABLED
                else PackageManager.COMPONENT_ENABLED_STATE_DISABLED
        }.filter { (component, state) ->
            val current = manager.getComponentEnabledSetting(component)
            val enabled = current == PackageManager.COMPONENT_ENABLED_STATE_ENABLED ||
                (current == PackageManager.COMPONENT_ENABLED_STATE_DEFAULT && component.className.endsWith("_default"))
            enabled != (state == PackageManager.COMPONENT_ENABLED_STATE_ENABLED)
        }
        if (activityVisible) {
            // Application-wide lifecycle applies it after every activity leaves view.
        } else if (Build.VERSION.SDK_INT >= 33) {
            if (changes.isNotEmpty()) manager.setComponentEnabledSettings(changes.map { (component, state) ->
                PackageManager.ComponentEnabledSetting(component, state, PackageManager.DONT_KILL_APP)
            })
        } else {
            // Enable the replacement before disabling the old alias; MainActivity stays enabled.
            changes.sortedBy { if (it.second == PackageManager.COMPONENT_ENABLED_STATE_ENABLED) 0 else 1 }
                .forEach { (component, state) ->
                    manager.setComponentEnabledSetting(component, state, PackageManager.DONT_KILL_APP)
                }
        }
        val alarm = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pending = PendingIntent.getBroadcast(context, REQUEST,
            Intent(context, EventBrandingReceiver::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        alarm.cancel(pending)
        val next = windows(context).flatMap { listOf(it.optLong("start"), it.optLong("end")) }
            .filter { it > now }.minOrNull()
        if (next != null) alarm.setAndAllowWhileIdle(AlarmManager.RTC, next, pending)
    }
}

/** A full-screen SDK activity still belongs to the visible DragonHaven task. */
internal class EventBrandingLifecycle(private val context: Context) :
    Application.ActivityLifecycleCallbacks {
    private val starting = mutableSetOf<Activity>()
    private val started = mutableSetOf<Activity>()
    private val handler = Handler(Looper.getMainLooper())
    private val background = Runnable {
        if (starting.isEmpty() && started.isEmpty()) {
            EventBranding.activityVisible = false
            runCatching { EventBranding.refresh(context) }
        }
    }

    init {
        EventBranding.activityVisible = false
    }

    private fun visible() {
        handler.removeCallbacks(background)
        EventBranding.activityVisible = true
    }

    private fun stopped(activity: Activity) {
        starting.remove(activity)
        started.remove(activity)
        if (starting.isNotEmpty() || started.isNotEmpty()) return
        // Recreation is not a departure from the app. The replacement activity
        // owns the next genuine background transition.
        if (activity.isChangingConfigurations) return
        handler.removeCallbacks(background)
        // Bridge short Activity handoffs without touching launcher aliases.
        handler.postDelayed(background, 700L)
    }

    override fun onActivityCreated(activity: Activity, state: Bundle?) {
        starting.add(activity)
        visible()
    }

    override fun onActivityStarted(activity: Activity) {
        starting.remove(activity)
        started.add(activity)
        visible()
    }

    override fun onActivityStopped(activity: Activity) = stopped(activity)
    override fun onActivityDestroyed(activity: Activity) = stopped(activity)
    override fun onActivityResumed(activity: Activity) = Unit
    override fun onActivityPaused(activity: Activity) = Unit
    override fun onActivitySaveInstanceState(activity: Activity, state: Bundle) = Unit
}

class EventBrandingReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        runCatching { EventBranding.refresh(context) }
    }
}
