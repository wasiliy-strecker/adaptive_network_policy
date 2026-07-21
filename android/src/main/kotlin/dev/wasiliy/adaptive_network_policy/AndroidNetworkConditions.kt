package dev.wasiliy.adaptive_network_policy

import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.os.Build
import android.os.Handler
import android.os.Looper

private const val SCHEMA_VERSION = 1L
private const val API_28 = 28
private const val API_30 = 30
private const val API_31 = 31
private const val API_34 = 34
private const val API_35 = 35
private const val API_36 = 36

internal data class NetworkFacts(
    val hasNetwork: Boolean,
    val hasInternetCapability: Boolean = false,
    val isValidated: Boolean = false,
    val hasCaptivePortal: Boolean = false,
    val isNotMetered: Boolean = false,
    val isTemporarilyNotMetered: Boolean = false,
    val isNotBandwidthConstrained: Boolean? = null,
    val isNotRoaming: Boolean? = null,
    val isNotCongested: Boolean? = null,
    val isNotSuspended: Boolean? = null,
    val backgroundDataStatus: Int = ConnectivityManager.RESTRICT_BACKGROUND_STATUS_DISABLED,
    val transports: List<NativeNetworkTransport> = emptyList(),
    val downlinkKbps: Long? = null,
    val uplinkKbps: Long? = null,
)

internal object NetworkSnapshotMapper {
    fun map(facts: NetworkFacts, observedAtMillis: Long): NativeNetworkSnapshot {
        val availability = when {
            !facts.hasNetwork -> NativeNetworkAvailability.UNAVAILABLE
            facts.hasCaptivePortal -> NativeNetworkAvailability.CAPTIVE_PORTAL
            facts.isValidated -> NativeNetworkAvailability.VALIDATED_INTERNET
            facts.hasInternetCapability -> NativeNetworkAvailability.INTERNET_CONFIGURED
            else -> NativeNetworkAvailability.LOCAL_ONLY
        }
        val cost = when {
            !facts.hasNetwork -> NativeNetworkCost.UNKNOWN
            facts.isTemporarilyNotMetered -> NativeNetworkCost.TEMPORARILY_UNMETERED
            facts.isNotMetered -> NativeNetworkCost.UNMETERED
            else -> NativeNetworkCost.METERED
        }
        val constraint = when (facts.isNotBandwidthConstrained) {
            true -> NativeNetworkConstraint.UNCONSTRAINED
            false -> NativeNetworkConstraint.CONSTRAINED
            null -> NativeNetworkConstraint.UNKNOWN
        }

        return NativeNetworkSnapshot(
            schemaVersion = SCHEMA_VERSION,
            availability = availability,
            transports = facts.transports.distinct(),
            cost = cost,
            constraint = constraint,
            isRoaming = inverseFlag(facts.isNotRoaming),
            isCongested = inverseFlag(facts.isNotCongested),
            isSuspended = inverseFlag(facts.isNotSuspended),
            backgroundData = backgroundData(facts.backgroundDataStatus),
            downlinkKbps = facts.downlinkKbps,
            uplinkKbps = facts.uplinkKbps,
            observedAtMillis = observedAtMillis,
        )
    }

    private fun inverseFlag(negatedValue: Boolean?): NativeNetworkFlag = when (negatedValue) {
        true -> NativeNetworkFlag.NO
        false -> NativeNetworkFlag.YES
        null -> NativeNetworkFlag.UNKNOWN
    }

    private fun backgroundData(status: Int): NativeBackgroundDataStatus = when (status) {
        ConnectivityManager.RESTRICT_BACKGROUND_STATUS_ENABLED ->
            NativeBackgroundDataStatus.RESTRICTED
        ConnectivityManager.RESTRICT_BACKGROUND_STATUS_WHITELISTED ->
            NativeBackgroundDataStatus.EXEMPT
        ConnectivityManager.RESTRICT_BACKGROUND_STATUS_DISABLED ->
            NativeBackgroundDataStatus.ALLOWED
        else -> NativeBackgroundDataStatus.UNKNOWN
    }
}

internal class AndroidNetworkConditionsReader(
    private val connectivityManager: ConnectivityManager,
) {
    fun current(observedAtMillis: Long = System.currentTimeMillis()): NativeNetworkSnapshot {
        val backgroundStatus = connectivityManager.restrictBackgroundStatus
        val network = connectivityManager.activeNetwork
            ?: return NetworkSnapshotMapper.map(
                NetworkFacts(
                    hasNetwork = false,
                    backgroundDataStatus = backgroundStatus,
                ),
                observedAtMillis,
            )
        val capabilities = connectivityManager.getNetworkCapabilities(network)
            ?: return NetworkSnapshotMapper.map(
                NetworkFacts(
                    hasNetwork = false,
                    backgroundDataStatus = backgroundStatus,
                ),
                observedAtMillis,
            )

        return NetworkSnapshotMapper.map(
            NetworkFacts(
                hasNetwork = true,
                hasInternetCapability = capabilities.hasCapability(
                    NetworkCapabilities.NET_CAPABILITY_INTERNET,
                ),
                isValidated = capabilities.hasCapability(
                    NetworkCapabilities.NET_CAPABILITY_VALIDATED,
                ),
                hasCaptivePortal = capabilities.hasCapability(
                    NetworkCapabilities.NET_CAPABILITY_CAPTIVE_PORTAL,
                ),
                isNotMetered = capabilities.hasCapability(
                    NetworkCapabilities.NET_CAPABILITY_NOT_METERED,
                ),
                isTemporarilyNotMetered = Build.VERSION.SDK_INT >= API_30 &&
                    capabilities.hasCapability(
                        NetworkCapabilities.NET_CAPABILITY_TEMPORARILY_NOT_METERED,
                    ),
                isNotBandwidthConstrained = if (Build.VERSION.SDK_INT >= API_36) {
                    capabilities.hasCapability(
                        NetworkCapabilities.NET_CAPABILITY_NOT_BANDWIDTH_CONSTRAINED,
                    )
                } else {
                    null
                },
                isNotRoaming = capabilityFromApi(
                    capabilities,
                    API_28,
                    NetworkCapabilities.NET_CAPABILITY_NOT_ROAMING,
                ),
                isNotCongested = capabilityFromApi(
                    capabilities,
                    API_28,
                    NetworkCapabilities.NET_CAPABILITY_NOT_CONGESTED,
                ),
                isNotSuspended = capabilityFromApi(
                    capabilities,
                    API_28,
                    NetworkCapabilities.NET_CAPABILITY_NOT_SUSPENDED,
                ),
                backgroundDataStatus = backgroundStatus,
                transports = transports(capabilities),
                downlinkKbps = capabilities.linkDownstreamBandwidthKbps
                    .takeIf { it > 0 }
                    ?.toLong(),
                uplinkKbps = capabilities.linkUpstreamBandwidthKbps
                    .takeIf { it > 0 }
                    ?.toLong(),
            ),
            observedAtMillis,
        )
    }

    fun register(callback: ConnectivityManager.NetworkCallback) {
        connectivityManager.registerDefaultNetworkCallback(callback)
    }

    fun unregister(callback: ConnectivityManager.NetworkCallback) {
        connectivityManager.unregisterNetworkCallback(callback)
    }

    private fun capabilityFromApi(
        capabilities: NetworkCapabilities,
        minimumApi: Int,
        capability: Int,
    ): Boolean? = if (Build.VERSION.SDK_INT >= minimumApi) {
        capabilities.hasCapability(capability)
    } else {
        null
    }

    private fun transports(capabilities: NetworkCapabilities): List<NativeNetworkTransport> {
        val result = mutableListOf<NativeNetworkTransport>()
        if (capabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)) {
            result += NativeNetworkTransport.WIFI
        }
        if (capabilities.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR)) {
            result += NativeNetworkTransport.CELLULAR
        }
        if (capabilities.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET)) {
            result += NativeNetworkTransport.ETHERNET
        }
        if (capabilities.hasTransport(NetworkCapabilities.TRANSPORT_VPN)) {
            result += NativeNetworkTransport.VPN
        }
        val hasOther = capabilities.hasTransport(NetworkCapabilities.TRANSPORT_BLUETOOTH) ||
            (Build.VERSION.SDK_INT >= 26 &&
                capabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI_AWARE)) ||
            (Build.VERSION.SDK_INT >= 27 &&
                capabilities.hasTransport(NetworkCapabilities.TRANSPORT_LOWPAN)) ||
            (Build.VERSION.SDK_INT >= API_31 &&
                capabilities.hasTransport(NetworkCapabilities.TRANSPORT_USB)) ||
            (Build.VERSION.SDK_INT >= API_34 &&
                capabilities.hasTransport(NetworkCapabilities.TRANSPORT_THREAD)) ||
            (Build.VERSION.SDK_INT >= API_35 &&
                capabilities.hasTransport(NetworkCapabilities.TRANSPORT_SATELLITE))
        if (hasOther) {
            result += NativeNetworkTransport.OTHER
        }
        return result
    }
}

internal class AndroidNetworkConditionsHostApi(
    private val reader: AndroidNetworkConditionsReader,
) : NativeNetworkConditionsApi {
    override fun current(): NativeNetworkSnapshot = try {
        reader.current()
    } catch (error: SecurityException) {
        throw FlutterError(
            code = "permission-denied",
            message = "ACCESS_NETWORK_STATE is required to observe network conditions.",
            details = error.message,
        )
    }
}

internal class AndroidNetworkConditionsEventHandler(
    private val reader: AndroidNetworkConditionsReader,
) : WatchStreamHandler() {
    private val mainHandler = Handler(Looper.getMainLooper())
    private var sink: PigeonEventSink<NativeNetworkSnapshot>? = null
    private var callback: ConnectivityManager.NetworkCallback? = null

    override fun onListen(p0: Any?, sink: PigeonEventSink<NativeNetworkSnapshot>) {
        dispose()
        this.sink = sink
        val networkCallback = object : ConnectivityManager.NetworkCallback() {
            override fun onAvailable(network: Network) = emitCurrent()

            override fun onLost(network: Network) = emitCurrent()

            override fun onCapabilitiesChanged(
                network: Network,
                networkCapabilities: NetworkCapabilities,
            ) = emitCurrent()

            override fun onBlockedStatusChanged(network: Network, blocked: Boolean) = emitCurrent()
        }
        callback = networkCallback
        try {
            reader.register(networkCallback)
            emitCurrent()
        } catch (error: SecurityException) {
            sink.error(
                "permission-denied",
                "ACCESS_NETWORK_STATE is required to observe network conditions.",
                error.message,
            )
        } catch (error: RuntimeException) {
            sink.error("native-failure", error.message, null)
        }
    }

    override fun onCancel(p0: Any?) {
        dispose()
    }

    fun dispose() {
        callback?.let {
            try {
                reader.unregister(it)
            } catch (_: IllegalArgumentException) {
                // The callback was already removed by the platform.
            }
        }
        callback = null
        sink = null
    }

    private fun emitCurrent() {
        mainHandler.post {
            val currentSink = sink ?: return@post
            try {
                currentSink.success(reader.current())
            } catch (error: SecurityException) {
                currentSink.error("permission-denied", error.message, null)
            } catch (error: RuntimeException) {
                currentSink.error("native-failure", error.message, null)
            }
        }
    }
}
