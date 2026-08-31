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
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

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

        fun showNow(
            context: Context,
            notificationId: Int,
            title: String,
            body: String,
            kind: String,
        ) {
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
                .setAutoCancel(true)
                .setPriority(if (milestone) NotificationCompat.PRIORITY_HIGH else NotificationCompat.PRIORITY_DEFAULT)
                .build()
            NotificationManagerCompat.from(context).notify(notificationId, notification)
        }
    }
}
