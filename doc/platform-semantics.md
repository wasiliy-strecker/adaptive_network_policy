# Platform semantics

Network APIs differ substantially. The public model preserves those differences
with `unknown` instead of manufacturing cross-platform certainty.

## Availability

Android exposes internet, validation, and captive-portal capabilities for the
active network. A validated path maps to `validatedInternet`; a path that merely
advertises internet maps to `internetConfigured`.

Apple's `NWPath.Status.satisfied` means a usable system path exists, but it does
not provide Android's validation signal. It therefore maps to
`internetConfigured`, not `validatedInternet`. `requiresConnection` is kept
distinct from an unavailable path. Until the monitor delivers its first path,
the startup snapshot is `unknown` rather than incorrectly reporting offline.

No availability value guarantees that a particular hostname, port, TLS
configuration, account, or API is usable.

## Cost and constraints

- Android cost comes from metered capabilities. Temporarily unmetered is
  available on API 30+.
- Android's bandwidth-constraint capability is available on API 36+; earlier
  versions report `unknown` rather than inferring it from metering.
- Apple cost maps from `NWPath.isExpensive`.
- Apple Low Data Mode maps from `NWPath.isConstrained`.

Metering and constraint are independent. An operation may allow a metered path
while still respecting Low Data Mode.

## Transports

Android can report VPN alongside its underlying transports. Apple does not
expose a stable VPN interface type through `NWPath`, so VPN is not inferred from
interface names. Empty transports do not override availability; they mean only
that no supported transport type was reported.

## Android-only facts

Roaming, congestion, and suspension are mapped from native capabilities on API
28+. Android Data Saver maps to `allowed`, `restricted`, or `exempt` background
status. Apple reports these fields as `unknown`.

## Bandwidth

Android link bandwidth is an OS estimate in kilobits per second. It is not a
speed test and may differ from application throughput. Apple values remain
unset because the corresponding estimate is not exposed by `NWPath`.

## Unknown capability behavior

Policies default to `UnknownCapabilityBehavior.allow`. This lets a portable
background policy reject known bad states without making all Apple paths fail
because Android-only facts are absent.

Use `defer` when an operation must prove every relevant condition. The returned
`NetworkDeferred.reasons` identifies exactly which facts were unavailable.
