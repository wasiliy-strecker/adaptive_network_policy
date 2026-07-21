package dev.wasiliy.adaptive_network_policy

import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BinaryMessenger

/** Registers the native condition reader and event stream with Flutter. */
class AdaptiveNetworkPolicyPlugin : FlutterPlugin {
    private var messenger: BinaryMessenger? = null
    private var eventHandler: AndroidNetworkConditionsEventHandler? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        val reader = AndroidNetworkConditionsReader(
            binding.applicationContext.getSystemService(Context.CONNECTIVITY_SERVICE)
                as android.net.ConnectivityManager,
        )
        val binaryMessenger = binding.binaryMessenger
        messenger = binaryMessenger
        NativeNetworkConditionsApi.setUp(
            binaryMessenger,
            AndroidNetworkConditionsHostApi(reader),
        )
        eventHandler = AndroidNetworkConditionsEventHandler(reader).also {
            WatchStreamHandler.register(binaryMessenger, it)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        eventHandler?.dispose()
        eventHandler = null
        messenger?.let { NativeNetworkConditionsApi.setUp(it, null) }
        messenger = null
    }
}
