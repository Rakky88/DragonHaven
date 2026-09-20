package nl.dragonhaven.app

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import org.json.JSONArray

class DragonHavenNotificationReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        DragonHavenAlarmScheduler.markDelivered(
            context,
            intent.getStringExtra("scheduleId"),
        )
        if (Build.VERSION.SDK_INT >= 33 &&
            context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
            return
        }
        showNow(
            context = context,
            notificationId = intent.getIntExtra("notificationId", 0),
            title = intent.getStringExtra("title") ?: "DragonHaven",
            body = intent.getStringExtra("body") ?: "Something awaits in your Tower.",
            kind = intent.getStringExtra("kind") ?: "event",
        )
    }

    companion object {
        private const val EVENT_CHANNEL_ID = "dragonhaven_events"
        private const val MILESTONE_CHANNEL_ID = "dragonhaven_milestones"
        private const val ADVENTURE_COMPLETE_TAG = "dragonhaven.adventure_complete"
        private const val SOURCE_ID_EXTRA = "dragonhaven.notification_source_id"
        private const val DISMISSED_PREFERENCES = "dragonhaven_dismissed_notifications"
        private const val DISMISSED_TAGS = "remote_tags"

        private fun dismissedRemoteTags(context: Context): List<String> {
            val raw = context.getSharedPreferences(DISMISSED_PREFERENCES, Context.MODE_PRIVATE)
                .getString(DISMISSED_TAGS, "[]")
            return runCatching {
                val tags = JSONArray(raw)
                (0 until tags.length()).map { tags.getString(it) }
            }.getOrDefault(emptyList())
        }

        fun clearDisplayed(context: Context) {
            val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val tags = manager.activeNotifications.mapNotNull { it.tag }
                .filter { it != ADVENTURE_COMPLETE_TAG }
            if (tags.isNotEmpty()) {
                // The authenticated inbox may redeliver an FCM event after
                // foregrounding. Keep a bounded list of dismissed identities,
                // never message text, so it cannot immediately recreate a card.
                val recent = (dismissedRemoteTags(context) + tags).distinct().takeLast(256)
                context.getSharedPreferences(DISMISSED_PREFERENCES, Context.MODE_PRIVATE)
                    .edit().putString(DISMISSED_TAGS, JSONArray(recent).toString()).apply()
            }
            // NotificationManager only clears delivered cards, not AlarmManager
            // reminders or the durable schedule used after a device restart.
            NotificationManagerCompat.from(context).cancelAll()
        }

        fun cancelDisplayed(context: Context, notificationId: Int) {
            val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.cancel(notificationId)
            // A completed adventure uses a shared card, but cancelling an older
            // run must not remove the card belonging to the latest return.
            for (active in manager.activeNotifications) {
                if (active.tag == ADVENTURE_COMPLETE_TAG &&
                    active.notification.extras.getInt(SOURCE_ID_EXTRA) == notificationId) {
                    manager.cancel(active.tag, active.id)
                }
            }
        }

        fun showNow(
            context: Context,
            notificationId: Int,
            title: String,
            body: String,
            kind: String,
            notificationTag: String? = null,
        ) {
            if (notificationTag != null && notificationTag in dismissedRemoteTags(context)) return
            if (Build.VERSION.SDK_INT >= 33 &&
                context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                return
            }
            val milestone = kind == "achievement" || kind == "evolution"
            val channelId = if (milestone) MILESTONE_CHANNEL_ID else EVENT_CHANNEL_ID
            val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                manager.createNotificationChannel(
                    NotificationChannel(
                        channelId,
                        if (milestone) "Achievements & evolutions" else "DragonHaven events",
                        if (milestone) NotificationManager.IMPORTANCE_HIGH else NotificationManager.IMPORTANCE_DEFAULT,
                    ).apply {
                        description = if (milestone) {
                            "Unlocked achievements and new dragon evolutions"
                        } else {
                            "Egg hatching and completed Adventure reminders"
                        }
                    },
                )
            }
            val launch = context.packageManager.getLaunchIntentForPackage(context.packageName)
                ?: Intent(context, MainActivity::class.java)
            launch.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            launch.putExtra(MainActivity.NOTIFICATION_KIND_EXTRA, kind)
            val pendingLaunch = PendingIntent.getActivity(
                context,
                notificationId,
                launch,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            val notification = NotificationCompat.Builder(context, channelId)
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle(title)
                .setContentText(body)
                .setStyle(NotificationCompat.BigTextStyle().bigText(body))
                .setContentIntent(pendingLaunch)
                .addExtras(Bundle().apply { putInt(SOURCE_ID_EXTRA, notificationId) })
                .setAutoCancel(true)
                .setOnlyAlertOnce(notificationTag != null)
                .setPriority(if (milestone) NotificationCompat.PRIORITY_HIGH else NotificationCompat.PRIORITY_DEFAULT)
                .build()
            if (kind == "adventure_complete") {
                // Only the displayed card is shared. Each adventure keeps its
                // own alarm and tap intent, so later returns still arrive.
                NotificationManagerCompat.from(context).notify(ADVENTURE_COMPLETE_TAG, 0, notification)
            } else if (notificationTag != null) {
                // Match FCM's (tag, 0) identity when the foreground inbox catches
                // up with a notification already displayed by Android.
                NotificationManagerCompat.from(context).notify(notificationTag, 0, notification)
            } else {
                NotificationManagerCompat.from(context).notify(notificationId, notification)
            }
        }
    }
}
