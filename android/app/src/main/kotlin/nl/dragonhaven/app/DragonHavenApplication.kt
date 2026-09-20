package nl.dragonhaven.app

import android.app.Application
import android.content.Context

class DragonHavenApplication : Application() {
    override fun attachBaseContext(base: Context) {
        super.attachBaseContext(base)
        // Runs BEFORE Firebase's ContentProvider. Old releases persisted a true
        // SDK override: a manifest default alone does not reset that override.
        // These keys are from Firebase's DataCollectionArbiter/CommonUtils and
        // perf Constants. Keep aligned when updating the Firebase Android SDK.
        val enabled = base.getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
            .getBoolean("flutter.dragon_haven_diagnostics_opt_in_v1", false)
        base.getSharedPreferences("com.google.firebase.crashlytics", MODE_PRIVATE)
            .edit().putBoolean("firebase_crashlytics_collection_enabled", enabled).commit()
        base.getSharedPreferences("FirebasePerfSharedPrefs", MODE_PRIVATE)
            .edit().putBoolean("isEnabled", enabled).commit()
    }
}
