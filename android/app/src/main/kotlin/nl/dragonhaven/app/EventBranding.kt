package nl.dragonhaven.app

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import org.json.JSONArray
import org.json.JSONObject

/** Local, cosmetic calendar. Never needs a network call or an exact-alarm grant. */
object EventBranding {
    private val logos = setOf("default", "halloween", "christmas", "new_year", "valentine", "pride", "golden_wings")
    private const val PREFS = "dragonhaven_event_branding"
    private const val REQUEST = 7047
    // Disabling the alias of a visible task can finish that task even with
    // DONT_KILL_APP. Apply launcher changes only after the game leaves view.
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
            .sortedWith(compareBy<JSONObject> { if (it.optBoolean("preview")) 1 else 0 }
                .thenBy { it.optLong("end") }.thenBy { it.optString("key") })
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
            // onStop applies the pending calendar after Flutter saves on pause.
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

class EventBrandingReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        runCatching { EventBranding.refresh(context) }
    }
}
