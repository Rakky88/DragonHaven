package nl.dragonhaven.app

import android.app.AlarmManager
import android.app.Application
import android.app.Notification
import android.app.NotificationManager
import android.content.Context
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28], application = Application::class)
class DragonHavenNotificationsTest {
    private lateinit var context: Context
    private lateinit var manager: NotificationManager

    @Before fun setup() {
        context = RuntimeEnvironment.getApplication()
        manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    }

    private fun show(id: Int, kind: String, tag: String? = null) {
        DragonHavenNotificationReceiver.showNow(context, id, "Return $id", "Ready", kind, tag)
    }

    @Test fun successiveAdventureReturnsReplaceTheCardAndKeepOtherKinds() {
        show(1, "egg")
        show(2, "achievement")
        show(3, "friend_message", "friend-message-3")
        show(4, "adventure_complete")
        show(5, "adventure_complete")
        show(6, "adventure_complete")

        assertEquals(4, manager.activeNotifications.size)
        assertEquals(setOf("Return 1", "Return 2", "Return 3", "Return 6"),
            manager.activeNotifications.map {
                it.notification.extras.getString(Notification.EXTRA_TITLE)
            }.toSet())
        val latest = manager.activeNotifications.single { it.tag == "dragonhaven.adventure_complete" }
        assertEquals("adventure_complete", shadowOf(latest.notification.contentIntent)
            .savedIntent.getStringExtra(MainActivity.NOTIFICATION_KIND_EXTRA))
    }

    @Test fun cancellingAnOlderAdventureCannotRemoveTheLatestReturn() {
        show(4, "adventure_complete")
        show(5, "adventure_complete")
        DragonHavenNotificationReceiver.cancelDisplayed(context, 4)
        assertEquals(1, manager.activeNotifications.size)
        DragonHavenNotificationReceiver.cancelDisplayed(context, 5)
        assertEquals(0, manager.activeNotifications.size)
    }

    @Test fun dismissedPushCannotReappearDuringInboxSyncButNewMessagesCan() {
        show(3, "friend_message", "friend-message-3")
        DragonHavenNotificationReceiver.clearDisplayed(context)
        // Use a fresh Context as on a recreated activity. Suppression is stored
        // on the device, independent of a particular activity instance.
        val reopened = context.createPackageContext(context.packageName, 0)
        DragonHavenNotificationReceiver.showNow(reopened, 3, "Old message", "Ready",
            "friend_message", "friend-message-3")
        assertTrue(manager.activeNotifications.isEmpty())
        show(4, "friend_message", "friend-message-4")
        assertEquals("Return 4", manager.activeNotifications.single()
            .notification.extras.getString(Notification.EXTRA_TITLE))
    }

    @Test fun openingTheAppClearsLocalAndPushCardsButKeepsFutureReminders() {
        val future = System.currentTimeMillis() + 120_000
        for ((id, kind) in listOf("next-adventure" to "adventure_complete", "next-egg" to "egg")) {
            DragonHavenAlarmScheduler.schedule(context,
                DragonHavenScheduledNotification(id, future, "Later", "Ready", kind))
        }
        show(1, "egg")
        show(2, "adventure_complete")
        show(3, "friend_message", "friend-message-3")
        val alarms = shadowOf(context.getSystemService(Context.ALARM_SERVICE) as AlarmManager)
        val before = alarms.scheduledAlarms.map { it.operation }.toSet()
        assertEquals(2, before.size)

        DragonHavenNotificationReceiver.clearDisplayed(context)
        DragonHavenNotificationReceiver.clearDisplayed(context)

        assertTrue(manager.activeNotifications.isEmpty())
        assertEquals(before, alarms.scheduledAlarms.map { it.operation }.toSet())
        val saved = context.getSharedPreferences("dragonhaven_scheduled_notifications", Context.MODE_PRIVATE)
        assertEquals(setOf("next-adventure", "next-egg"), saved.all.keys)
        // The next completion can still post after the player leaves the app.
        show(4, "adventure_complete")
        assertEquals(1, manager.activeNotifications.size)
    }
}
