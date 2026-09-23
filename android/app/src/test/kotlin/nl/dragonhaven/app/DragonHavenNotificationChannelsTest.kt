package nl.dragonhaven.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.pm.PackageManager
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28], application = DragonHavenApplication::class)
class DragonHavenNotificationChannelsTest {
    private val context: Context = RuntimeEnvironment.getApplication()
    private val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    @Test fun applicationCreatesTheFirebaseChannelBeforeAnyActivity() {
        val events = manager.getNotificationChannel(DragonHavenNotificationChannels.EVENTS_ID)
        val milestones = manager.getNotificationChannel(DragonHavenNotificationChannels.MILESTONES_ID)

        assertNotNull(events)
        assertNotNull(milestones)
        assertEquals(NotificationManager.IMPORTANCE_DEFAULT, events.importance)
        assertEquals(NotificationManager.IMPORTANCE_HIGH, milestones.importance)

        val application = context.packageManager.getApplicationInfo(
            context.packageName,
            PackageManager.GET_META_DATA,
        )
        assertEquals(
            DragonHavenNotificationChannels.EVENTS_ID,
            application.metaData.getString(
                "com.google.firebase.messaging.default_notification_channel_id",
            ),
        )
    }

    @Test fun aMutedEventsChannelMakesDeliveryUnavailable() {
        manager.deleteNotificationChannel(DragonHavenNotificationChannels.EVENTS_ID)
        manager.createNotificationChannel(
            NotificationChannel(
                DragonHavenNotificationChannels.EVENTS_ID,
                "DragonHaven events",
                NotificationManager.IMPORTANCE_NONE,
            ),
        )

        assertFalse(DragonHavenNotificationChannels.eventsEnabled(context))
    }
}
