package nl.dragonhaven.app

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import org.json.JSONObject

internal data class DragonHavenScheduledNotification(
    val id: String,
    val at: Long,
    val title: String,
    val body: String,
    val kind: String,
)

internal object DragonHavenAlarmScheduler {
    private const val PREFERENCES = "dragonhaven_scheduled_notifications"

    fun exactAlarmAllowed(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return true
        val alarm = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        return alarm.canScheduleExactAlarms()
    }

    fun schedule(context: Context, notification: DragonHavenScheduledNotification) {
        if (notification.at <= System.currentTimeMillis()) {
            removePersisted(context, notification.id)
            return
        }
        persist(context, notification)
        val pending = PendingIntent.getBroadcast(
            context,
            notification.id.hashCode(),
            notificationIntent(context, notification),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val alarm = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        if (exactAlarmAllowed(context)) {
            try {
                alarm.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    notification.at,
                    pending,
                )
                return
            } catch (_: SecurityException) {
                // A device policy can change between the permission check and
                // scheduling. Keep a no-earlier-than fallback instead.
            }
        }
        alarm.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, notification.at, pending)
    }

    fun cancel(context: Context, id: String) {
        removePersisted(context, id)
        val pending = PendingIntent.getBroadcast(
            context,
            id.hashCode(),
            Intent(context, DragonHavenNotificationReceiver::class.java),
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE,
        ) ?: return
        val alarm = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarm.cancel(pending)
        pending.cancel()
    }

    fun markDelivered(context: Context, id: String?) {
        if (id != null) removePersisted(context, id)
    }

    fun reschedulePending(context: Context) {
        val preferences = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
        val now = System.currentTimeMillis()
        for ((id, raw) in preferences.all) {
            val notification = decode(id, raw as? String)
            if (notification == null || notification.at <= now) {
                removePersisted(context, id)
                continue
            }
            schedule(context, notification)
        }
    }

    private fun notificationIntent(
        context: Context,
        notification: DragonHavenScheduledNotification,
    ) = Intent(context, DragonHavenNotificationReceiver::class.java).apply {
        putExtra("scheduleId", notification.id)
        putExtra("scheduledAt", notification.at)
        putExtra("title", notification.title)
        putExtra("body", notification.body)
        putExtra("kind", notification.kind)
        putExtra("notificationId", notification.id.hashCode())
    }

    private fun persist(context: Context, notification: DragonHavenScheduledNotification) {
        val encoded = JSONObject()
            .put("at", notification.at)
            .put("title", notification.title)
            .put("body", notification.body)
            .put("kind", notification.kind)
            .toString()
        context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
            .edit()
            .putString(notification.id, encoded)
            .apply()
    }

    private fun removePersisted(context: Context, id: String) {
        context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
            .edit()
            .remove(id)
            .apply()
    }

    private fun decode(id: String, raw: String?): DragonHavenScheduledNotification? {
        if (raw == null) return null
        return try {
            val json = JSONObject(raw)
            DragonHavenScheduledNotification(
                id = id,
                at = json.getLong("at"),
                title = json.getString("title"),
                body = json.getString("body"),
                kind = json.optString("kind", "event"),
            )
        } catch (_: Exception) {
            null
        }
    }
}
