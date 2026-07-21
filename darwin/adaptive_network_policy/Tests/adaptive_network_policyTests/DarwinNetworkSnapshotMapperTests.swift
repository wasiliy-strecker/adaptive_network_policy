import XCTest

@testable import adaptive_network_policy

final class DarwinNetworkSnapshotMapperTests: XCTestCase {
  func testMapsUnobservedPathToUnknownConditions() {
    let snapshot = DarwinNetworkSnapshotMapper.map(
      DarwinNetworkFacts(
        status: .unknown,
        transports: [],
        isExpensive: false,
        isConstrained: false
      ),
      observedAtMillis: 1
    )

    XCTAssertEqual(snapshot.availability, .unknown)
    XCTAssertEqual(snapshot.cost, .unknown)
    XCTAssertEqual(snapshot.constraint, .unknown)
  }

  func testMapsSatisfiedConstrainedCellularPath() {
    let snapshot = DarwinNetworkSnapshotMapper.map(
      DarwinNetworkFacts(
        status: .satisfied,
        transports: [.cellular, .cellular],
        isExpensive: true,
        isConstrained: true
      ),
      observedAtMillis: 1_234
    )

    XCTAssertEqual(snapshot.availability, .internetConfigured)
    XCTAssertEqual(snapshot.transports, [.cellular])
    XCTAssertEqual(snapshot.cost, .metered)
    XCTAssertEqual(snapshot.constraint, .constrained)
    XCTAssertEqual(snapshot.isRoaming, .unknown)
    XCTAssertEqual(snapshot.backgroundData, .unknown)
    XCTAssertEqual(snapshot.observedAtMillis, 1_234)
  }

  func testMapsUnavailablePathToUnknownConditions() {
    let snapshot = DarwinNetworkSnapshotMapper.map(
      DarwinNetworkFacts(
        status: .unavailable,
        transports: [],
        isExpensive: false,
        isConstrained: false
      ),
      observedAtMillis: 1
    )

    XCTAssertEqual(snapshot.availability, .unavailable)
    XCTAssertEqual(snapshot.cost, .unknown)
    XCTAssertEqual(snapshot.constraint, .unknown)
  }

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
