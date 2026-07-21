import Foundation
import Network

private let schemaVersion: Int64 = 1

internal enum DarwinPathStatus: Equatable {
  case unknown
  case unavailable
  case requiresConnection
  case satisfied
}

internal struct DarwinNetworkFacts {
  let status: DarwinPathStatus
  let transports: [NativeNetworkTransport]
  let isExpensive: Bool
  let isConstrained: Bool
}

internal enum DarwinNetworkSnapshotMapper {
  static func map(
    _ facts: DarwinNetworkFacts,
    observedAtMillis: Int64
  ) -> NativeNetworkSnapshot {
    let availability: NativeNetworkAvailability
    switch facts.status {
    case .unknown:
      availability = .unknown
    case .unavailable:
      availability = .unavailable
    case .requiresConnection:
      availability = .requiresConnection
    case .satisfied:
      // NWPath reports a usable route, but does not expose Android-style
      // internet validation. Keep that distinction visible to callers.
      availability = .internetConfigured
    }

    let cost: NativeNetworkCost
    if facts.status == .unavailable || facts.status == .unknown {
      cost = .unknown
    } else {
      cost = facts.isExpensive ? .metered : .unmetered
    }

    let constraint: NativeNetworkConstraint
    if facts.status == .unavailable || facts.status == .unknown {
      constraint = .unknown
    } else {
      constraint = facts.isConstrained ? .constrained : .unconstrained
    }

    return NativeNetworkSnapshot(
      schemaVersion: schemaVersion,
      availability: availability,
      transports: unique(facts.transports),
      cost: cost,
      constraint: constraint,
      isRoaming: .unknown,
      isCongested: .unknown,
      isSuspended: .unknown,
      backgroundData: .unknown,
      downlinkKbps: nil,
      uplinkKbps: nil,
      observedAtMillis: observedAtMillis
    )
  }

  private static func unique(
    _ transports: [NativeNetworkTransport]
  ) -> [NativeNetworkTransport] {
    var seen = Set<Int>()
    return transports.filter { seen.insert($0.rawValue).inserted }
  }
}

extension DarwinNetworkFacts {
  fileprivate init(path: NWPath) {
    let status: DarwinPathStatus
    switch path.status {
    case .satisfied:
      status = .satisfied
    case .requiresConnection:
      status = .requiresConnection
    case .unsatisfied:
      status = .unavailable
    @unknown default:
      status = .unavailable
    }

    var transports = [NativeNetworkTransport]()
    if path.usesInterfaceType(.wifi) {
      transports.append(.wifi)
    }
    if path.usesInterfaceType(.cellular) {
      transports.append(.cellular)
    }
    if path.usesInterfaceType(.wiredEthernet) {
      transports.append(.ethernet)
    }
    if path.usesInterfaceType(.loopback) {
      transports.append(.loopback)
    }
    if path.usesInterfaceType(.other) {
      transports.append(.other)
    }

    self.init(
      status: status,
      transports: transports,
      isExpensive: path.isExpensive,
      isConstrained: path.isConstrained
    )
  }
}

internal final class DarwinNetworkConditionsMonitor {
  typealias Observer = (NativeNetworkSnapshot) -> Void

  private let monitor = NWPathMonitor()
  private let queue = DispatchQueue(
    label: "dev.wasiliy.adaptive_network_policy.path-monitor"
  )
  private let lock = NSLock()
  private var latest: NativeNetworkSnapshot
  private var observer: Observer?
  private var started = false

  init() {
    latest = DarwinNetworkSnapshotMapper.map(
      DarwinNetworkFacts(
        status: .unknown,
        transports: [],
        isExpensive: false,
        isConstrained: false
      ),
      observedAtMillis: Self.nowMillis()
    )
  }

  deinit {
    monitor.cancel()
  }

  func start() {
    lock.lock()
    guard !started else {
      lock.unlock()
      return
    }
    started = true
    lock.unlock()

    monitor.pathUpdateHandler = { [weak self] path in
      self?.update(with: path)
    }
    monitor.start(queue: queue)
  }

  func current() -> NativeNetworkSnapshot {
    lock.lock()
    defer { lock.unlock() }
    return latest
  }

  func setObserver(_ observer: Observer?) {
    lock.lock()
    self.observer = observer
    lock.unlock()
  }

  private func update(with path: NWPath) {
    let snapshot = DarwinNetworkSnapshotMapper.map(
      DarwinNetworkFacts(path: path),
      observedAtMillis: Self.nowMillis()
    )

    lock.lock()
    latest = snapshot
    let currentObserver = observer
    lock.unlock()
    currentObserver?(snapshot)
  }

  private static func nowMillis() -> Int64 {
    Int64(Date().timeIntervalSince1970 * 1_000)
  }
}

internal final class DarwinNetworkConditionsHostApi: NativeNetworkConditionsApi {
  private let monitor: DarwinNetworkConditionsMonitor

  init(monitor: DarwinNetworkConditionsMonitor) {
    self.monitor = monitor
  }

  func current() throws -> NativeNetworkSnapshot {
    monitor.current()
  }
}

internal final class DarwinNetworkConditionsEventHandler: WatchStreamHandler {
  private let monitor: DarwinNetworkConditionsMonitor
  private var sink: PigeonEventSink<NativeNetworkSnapshot>?

  init(monitor: DarwinNetworkConditionsMonitor) {
    self.monitor = monitor
  }

  override func onListen(
    withArguments arguments: Any?,
    sink: PigeonEventSink<NativeNetworkSnapshot>
  ) {
    self.sink = sink
    monitor.setObserver { [weak self] snapshot in
      self?.emit(snapshot)
    }
    emit(monitor.current())
  }

  override func onCancel(withArguments arguments: Any?) {
    monitor.setObserver(nil)
    sink = nil
  }

  private func emit(_ snapshot: NativeNetworkSnapshot) {
    if Thread.isMainThread {
      sink?.success(snapshot)
      return
    }
    DispatchQueue.main.async { [weak self] in
      self?.sink?.success(snapshot)
    }
  }
}
