package dev.wasiliy.adaptive_network_policy

import android.net.ConnectivityManager
import kotlin.test.Test
import kotlin.test.assertEquals

class NetworkSnapshotMapperTest {
    @Test
    fun `maps validated unmetered path`() {
        val snapshot = NetworkSnapshotMapper.map(
            NetworkFacts(
                hasNetwork = true,
                hasInternetCapability = true,
                isValidated = true,
                isNotMetered = true,
                isNotBandwidthConstrained = true,
                isNotRoaming = true,
                isNotCongested = true,
                isNotSuspended = true,
                transports = listOf(NativeNetworkTransport.WIFI),
                downlinkKbps = 100_000,
                uplinkKbps = 20_000,
            ),
            observedAtMillis = 1234,
        )

        assertEquals(NativeNetworkAvailability.VALIDATED_INTERNET, snapshot.availability)
        assertEquals(NativeNetworkCost.UNMETERED, snapshot.cost)
        assertEquals(NativeNetworkConstraint.UNCONSTRAINED, snapshot.constraint)
        assertEquals(NativeNetworkFlag.NO, snapshot.isRoaming)
        assertEquals(NativeNetworkFlag.NO, snapshot.isCongested)
        assertEquals(NativeNetworkFlag.NO, snapshot.isSuspended)
        assertEquals(listOf(NativeNetworkTransport.WIFI), snapshot.transports)
        assertEquals(100_000L, snapshot.downlinkKbps)
        assertEquals(20_000L, snapshot.uplinkKbps)
        assertEquals(1234L, snapshot.observedAtMillis)
    }

    @Test
    fun `maps constrained metered captive portal`() {
        val snapshot = NetworkSnapshotMapper.map(
            NetworkFacts(
                hasNetwork = true,
                hasInternetCapability = true,
                hasCaptivePortal = true,
                isNotBandwidthConstrained = false,
                isNotRoaming = false,
                isNotCongested = false,
                isNotSuspended = false,
                backgroundDataStatus = ConnectivityManager.RESTRICT_BACKGROUND_STATUS_ENABLED,
                transports = listOf(
                    NativeNetworkTransport.CELLULAR,
                    NativeNetworkTransport.VPN,
                ),
            ),
            observedAtMillis = 1,
        )

        assertEquals(NativeNetworkAvailability.CAPTIVE_PORTAL, snapshot.availability)
        assertEquals(NativeNetworkCost.METERED, snapshot.cost)
        assertEquals(NativeNetworkConstraint.CONSTRAINED, snapshot.constraint)
        assertEquals(NativeNetworkFlag.YES, snapshot.isRoaming)
        assertEquals(NativeNetworkFlag.YES, snapshot.isCongested)
        assertEquals(NativeNetworkFlag.YES, snapshot.isSuspended)
        assertEquals(NativeBackgroundDataStatus.RESTRICTED, snapshot.backgroundData)
    }

    @Test
    fun `keeps unavailable capabilities unknown`() {
        val snapshot = NetworkSnapshotMapper.map(
            NetworkFacts(hasNetwork = false),
            observedAtMillis = 1,
        )

        assertEquals(NativeNetworkAvailability.UNAVAILABLE, snapshot.availability)
        assertEquals(NativeNetworkCost.UNKNOWN, snapshot.cost)
        assertEquals(NativeNetworkConstraint.UNKNOWN, snapshot.constraint)
        assertEquals(NativeNetworkFlag.UNKNOWN, snapshot.isRoaming)
        assertEquals(NativeNetworkFlag.UNKNOWN, snapshot.isCongested)
        assertEquals(NativeNetworkFlag.UNKNOWN, snapshot.isSuspended)
    }

    @Test
    fun `temporarily unmetered takes precedence`() {
        val snapshot = NetworkSnapshotMapper.map(
            NetworkFacts(
                hasNetwork = true,
                isTemporarilyNotMetered = true,
            ),
            observedAtMillis = 1,
        )

        assertEquals(NativeNetworkCost.TEMPORARILY_UNMETERED, snapshot.cost)
    }
}
