package nl.dragonhaven.app

import android.app.Activity
import android.content.ComponentName
import android.content.Context
import android.content.pm.PackageManager
import android.os.Looper
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import java.time.Duration

class BrandingTestActivity : Activity() {
    var changingConfiguration = false
    override fun isChangingConfigurations(): Boolean = changingConfiguration
}

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28], application = DragonHavenApplication::class)
class EventBrandingLifecycleTest {
    private val context: Context = RuntimeEnvironment.getApplication()
    private val manager = context.packageManager
    private fun component(logo: String) =
        ComponentName(context, "${context.packageName}.Launcher_$logo")

    private fun schedulePendingIcon() {
        val now = System.currentTimeMillis()
        EventBranding.setSchedule(context, listOf(mapOf(
            "logo" to "halloween",
            "key" to "lifecycle-test",
            "start" to now - 10_000L,
            "end" to now + 3_600_000L,
        )))
    }

    private fun assertPendingIconUnchanged() {
        assertEquals(PackageManager.COMPONENT_ENABLED_STATE_DEFAULT,
            manager.getComponentEnabledSetting(component("default")))
        assertEquals(PackageManager.COMPONENT_ENABLED_STATE_DEFAULT,
            manager.getComponentEnabledSetting(component("halloween")))
    }

    private fun assertPendingIconApplied() {
        assertFalse(EventBranding.activityVisible)
        assertEquals(PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
            manager.getComponentEnabledSetting(component("default")))
        assertEquals(PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
            manager.getComponentEnabledSetting(component("halloween")))
    }

    @Test fun anSdkOverlayKeepsTheLauncherAliasStableAfterTheGameStops() {
        val game = Robolectric.buildActivity(BrandingTestActivity::class.java)
            .create().start().resume()
        schedulePendingIcon()
        assertPendingIconUnchanged()

        // Lifecycle of an SDK full-screen activity, e.g. Google's AdActivity.
        val overlay = Robolectric.buildActivity(Activity::class.java)
            .create().start().resume()
        game.pause().stop()
        shadowOf(Looper.getMainLooper()).idleFor(Duration.ofSeconds(2))
        assertTrue(EventBranding.activityVisible)
        EventBranding.refresh(context)
        assertPendingIconUnchanged()

        overlay.pause().stop()
        shadowOf(Looper.getMainLooper()).idleFor(Duration.ofSeconds(1))
        assertPendingIconApplied()
        overlay.destroy()
        game.destroy()
    }

    @Test fun configurationRecreationDoesNotChangeTheLaunchingAlias() {
        val game = Robolectric.buildActivity(BrandingTestActivity::class.java)
            .create().start().resume()
        schedulePendingIcon()
        game.get().changingConfiguration = true
        game.pause().stop().destroy()
        shadowOf(Looper.getMainLooper()).idleFor(Duration.ofSeconds(2))
        assertTrue(EventBranding.activityVisible)
        assertPendingIconUnchanged()

        val replacement = Robolectric.buildActivity(BrandingTestActivity::class.java)
            .create().start().resume()
        replacement.pause().stop()
        shadowOf(Looper.getMainLooper()).idleFor(Duration.ofSeconds(1))
        assertPendingIconApplied()
        replacement.destroy()
    }

    @Test fun aBriefActivityHandoffDefersThePendingIconUntilBackground() {
        val game = Robolectric.buildActivity(BrandingTestActivity::class.java)
            .create().start().resume()
        schedulePendingIcon()
        game.pause().stop()
        shadowOf(Looper.getMainLooper()).idleFor(Duration.ofMillis(300))
        val replacement = Robolectric.buildActivity(Activity::class.java)
            .create().start().resume()
        shadowOf(Looper.getMainLooper()).idleFor(Duration.ofSeconds(1))
        assertTrue(EventBranding.activityVisible)
        assertPendingIconUnchanged()

        replacement.pause().stop()
        shadowOf(Looper.getMainLooper()).idleFor(Duration.ofSeconds(1))
        assertPendingIconApplied()
        replacement.destroy()
        game.destroy()
    }
}
