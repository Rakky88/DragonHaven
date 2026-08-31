package nl.dragonhaven.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class DragonHavenAlarmRescheduleReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        DragonHavenAlarmScheduler.reschedulePending(context)
    }
}
