package nl.dragonhaven.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build

object DragonHavenNotificationChannels {
    const val EVENTS_ID = "dragonhaven_events"
    const val MILESTONES_ID = "dragonhaven_milestones"

    fun ensureCreated(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.createNotificationChannels(
            listOf(
                NotificationChannel(
                    EVENTS_ID,
                    "DragonHaven events",
                    NotificationManager.IMPORTANCE_DEFAULT,
                ).apply {
                    description = "Eggs, completed Adventures and social updates"
                },
                NotificationChannel(
                    MILESTONES_ID,
                    "Achievements & evolutions",
                    NotificationManager.IMPORTANCE_HIGH,
                ).apply {
                    description = "Unlocked achievements and new dragon evolutions"
                },
            ),
        )
    }

    fun eventsEnabled(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return true
        ensureCreated(context)
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        return manager.getNotificationChannel(EVENTS_ID)?.importance !=
            NotificationManager.IMPORTANCE_NONE
    }
}
