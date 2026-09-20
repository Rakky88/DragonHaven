package nl.dragonhaven.app

import android.content.Context
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel

/** Connectivity loss closes gameplay immediately; only a server reply opens it. */
class NetworkStatusBridge(context: Context, messenger: BinaryMessenger) : EventChannel.StreamHandler {
    private val manager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
    private val main = Handler(Looper.getMainLooper())
    private val channel = EventChannel(messenger, "nl.dragonhaven.app/network")
    private var sink: EventChannel.EventSink? = null
    private var registered = false
    private fun emit() { main.post {
        val caps = manager.getNetworkCapabilities(manager.activeNetwork)
        sink?.success(caps?.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) == true &&
            caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED))
    } }
    private val callback = object : ConnectivityManager.NetworkCallback() {
        override fun onAvailable(network: Network) = emit()
        override fun onLost(network: Network) = emit()
        override fun onCapabilitiesChanged(network: Network, caps: NetworkCapabilities) = emit()
    }
    init { channel.setStreamHandler(this) }
    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        sink = events
        if (!registered) {
            if (Build.VERSION.SDK_INT >= 24) manager.registerDefaultNetworkCallback(callback)
            else manager.registerNetworkCallback(NetworkRequest.Builder()
                .addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET).build(), callback)
            registered = true
        }
        emit()
    }
    override fun onCancel(arguments: Any?) {
        sink = null
        if (registered) { manager.unregisterNetworkCallback(callback); registered = false }
    }
    fun dispose() { onCancel(null); channel.setStreamHandler(null) }
}
