import XCTest
@testable import Pongle

@MainActor
final class FlicButtonAssignmentTests: XCTestCase {
    private static let keys = [
        "pongle.oneInputPerPlayer",
        "pongle.flicButtonAssignments",
        "pongle.watchAssignedPlayer"
    ]

    override func setUp() {
        super.setUp()
        Self.keys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
    }

    override func tearDown() {
        Self.keys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
        super.tearDown()
    }

    func testOneInputPerPlayerDefaultsFalse() {
        XCTAssertFalse(AppSettings().oneInputPerPlayer)
    }

    func testAssignFlicReplaceSemantics() {
        let settings = AppSettings()
        settings.assignFlicButton("A", to: .playerOne)
        settings.assignFlicButton("B", to: .playerOne)

        XCTAssertNil(settings.player(forFlicButtonID: "A"))
        XCTAssertEqual(settings.player(forFlicButtonID: "B"), .playerOne)
        XCTAssertEqual(settings.assignedFlicButtonID(for: .playerOne), "B")
    }

    func testAssignWatchClearsFlicAndIsSingleWatch() {
        let settings = AppSettings()
        settings.assignFlicButton("A", to: .playerOne)
        settings.assignWatch(to: .playerOne)

        XCTAssertNil(settings.assignedFlicButtonID(for: .playerOne))
        XCTAssertTrue(settings.usesWatch(.playerOne))

        // The single watch moves to the other player rather than being duplicated.
        settings.assignWatch(to: .playerTwo)
        XCTAssertFalse(settings.usesWatch(.playerOne))
        XCTAssertTrue(settings.usesWatch(.playerTwo))
    }

    func testAssignFlicClearsWatchFromThatPlayer() {
        let settings = AppSettings()
        settings.assignWatch(to: .playerOne)
        settings.assignFlicButton("A", to: .playerOne)

        XCTAssertFalse(settings.usesWatch(.playerOne))
        XCTAssertEqual(settings.player(forFlicButtonID: "A"), .playerOne)
    }

    func testBothPlayersHaveInputFlicPlusWatch() {
        let settings = AppSettings()
        XCTAssertFalse(settings.bothPlayersHaveInput)

        settings.assignFlicButton("A", to: .playerTwo)
        settings.assignWatch(to: .playerOne)
        XCTAssertTrue(settings.bothPlayersHaveInput)
    }

    func testClearInputRemovesBothSources() {
        let settings = AppSettings()
        settings.assignFlicButton("A", to: .playerOne)
        settings.clearInput(for: .playerOne)
        XCTAssertFalse(settings.hasInput(for: .playerOne))

        settings.assignWatch(to: .playerTwo)
        settings.clearInput(for: .playerTwo)
        XCTAssertFalse(settings.hasInput(for: .playerTwo))
    }

    func testPersistenceRoundTrip() {
        let settings = AppSettings()
        settings.oneInputPerPlayer = true
        settings.assignFlicButton("A", to: .playerOne)
        settings.assignWatch(to: .playerTwo)

        let reloaded = AppSettings()
        XCTAssertTrue(reloaded.oneInputPerPlayer)
        XCTAssertEqual(reloaded.player(forFlicButtonID: "A"), .playerOne)
        XCTAssertTrue(reloaded.usesWatch(.playerTwo))
    }
}
