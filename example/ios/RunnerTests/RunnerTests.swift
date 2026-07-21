import Flutter
import XCTest

@testable import adaptive_network_policy

final class RunnerTests: XCTestCase {
  func testMapsRequiresConnectionSeparately() {
    let snapshot = DarwinNetworkSnapshotMapper.map(
      DarwinNetworkFacts(
        status: .requiresConnection,
        transports: [.wifi],
        isExpensive: false,
        isConstrained: false
      ),
      observedAtMillis: 1
    )

    XCTAssertEqual(snapshot.availability, .requiresConnection)
    XCTAssertEqual(snapshot.cost, .unmetered)
    XCTAssertEqual(snapshot.constraint, .unconstrained)
  }
}
