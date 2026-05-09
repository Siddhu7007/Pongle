import XCTest
@testable import Pongle

@MainActor
final class AnnouncementReliabilityTests: XCTestCase {
    func testAdvancedAnnouncementSettingsPersistAndDefaultToCurrentBehavior() {
        resetAnnouncementDefaults()

        let defaults = AppSettings()
        XCTAssertFalse(defaults.announcePointWinner)
        XCTAssertFalse(defaults.announceNextServer)
        XCTAssertTrue(defaults.announceCurrentScore)
        XCTAssertTrue(defaults.announceCriticalPoints)
        XCTAssertTrue(defaults.announceDeuce)
        XCTAssertEqual(defaults.announcementSpeed, .oneX)

        defaults.announcePointWinner = true
        defaults.announceNextServer = true
        defaults.announceCurrentScore = false
        defaults.announceCriticalPoints = false
        defaults.announceDeuce = false
        defaults.announcementSpeed = .twoPointFiveX

        let reloaded = AppSettings()
        XCTAssertTrue(reloaded.announcePointWinner)
        XCTAssertTrue(reloaded.announceNextServer)
        XCTAssertFalse(reloaded.announceCurrentScore)
        XCTAssertFalse(reloaded.announceCriticalPoints)
        XCTAssertFalse(reloaded.announceDeuce)
        XCTAssertEqual(reloaded.announcementSpeed, .twoPointFiveX)

        resetAnnouncementDefaults()
    }

    func testAllTogglesOnOrdersPointServerScoreAndCriticalState() {
        let settings = makeSettings(
            pointWinner: true,
            nextServer: true,
            currentScore: true,
            critical: true,
            deuce: true,
            playerOneName: "Cody",
            playerTwoName: "Brent"
        )

        let text = ScoreAnnouncementText.text(
            for: game(repeating: [(.playerOne, 10), (.playerTwo, 9)]),
            settings: settings,
            pointWinner: .playerOne
        )

        XCTAssertEqual(text, "Point Cody, Brent serves, nine serving ten, Set Point")
    }

    func testIndividualAnnouncementElementsSpeakAlone() {
        XCTAssertEqual(
            ScoreAnnouncementText.text(
                for: game([.playerOne]),
                settings: makeSettings(pointWinner: true, currentScore: false, critical: false, deuce: false, playerOneName: "Cody"),
                pointWinner: .playerOne
            ),
            "Point Cody"
        )

        XCTAssertEqual(
            ScoreAnnouncementText.text(
                for: game([.playerOne]),
                settings: makeSettings(nextServer: true, currentScore: false, critical: false, deuce: false, playerOneName: "Cody"),
                pointWinner: .playerOne
            ),
            "Cody serves"
        )

        XCTAssertEqual(
            ScoreAnnouncementText.text(
                for: game([.playerOne, .playerTwo, .playerOne]),
                settings: makeSettings(pointWinner: false, nextServer: false, currentScore: true, critical: false, deuce: false),
                pointWinner: .playerOne
            ),
            "one serving two"
        )
    }

    func testDeuceOnlySpeaksOnlyAtDeuce() {
        let settings = makeSettings(currentScore: false, critical: false, deuce: true)

        XCTAssertNil(ScoreAnnouncementText.text(for: game([.playerOne]), settings: settings, pointWinner: .playerOne))
        XCTAssertEqual(ScoreAnnouncementText.text(for: game(score: (10, 10)), settings: settings), "Deuce")
        XCTAssertEqual(ScoreAnnouncementText.text(for: game(score: (11, 11)), settings: settings), "Deuce")
        XCTAssertEqual(ScoreAnnouncementText.text(for: game(score: (12, 12)), settings: settings), "Deuce")
    }

    func testCriticalOnlySpeaksSetAndMatchPoint() {
        let settings = makeSettings(currentScore: false, critical: true, deuce: false)
        let matchPointHistory = Array(repeating: Player.playerOne, count: 11)
            + Array(repeating: Player.playerOne, count: 10)
            + Array(repeating: Player.playerTwo, count: 9)

        XCTAssertEqual(
            ScoreAnnouncementText.text(for: game(repeating: [(.playerOne, 10), (.playerTwo, 9)]), settings: settings),
            "Set Point"
        )
        XCTAssertEqual(ScoreAnnouncementText.text(for: game(matchPointHistory), settings: settings), "Match Point")
    }

    func testCriticalPrioritySuppressesLowerPriorityPhrases() {
        let settings = makeSettings(currentScore: false, critical: true, deuce: true)
        let matchPointHistory = Array(repeating: Player.playerOne, count: 11)
            + Array(repeating: Player.playerOne, count: 10)
            + Array(repeating: Player.playerTwo, count: 9)

        XCTAssertEqual(ScoreAnnouncementText.text(for: game(matchPointHistory), settings: settings), "Match Point")
        XCTAssertEqual(
            ScoreAnnouncementText.text(for: game(repeating: [(.playerOne, 10), (.playerTwo, 9)]), settings: settings),
            "Set Point"
        )
        XCTAssertEqual(ScoreAnnouncementText.text(for: game(score: (10, 10)), settings: settings), "Deuce")
    }

    func testAllAdvancedPointTogglesOffSuppressesPointSpeechThroughStore() {
        let announcer = FakeAnnouncer()
        let store = makeStore(announcer: announcer)
        store.settings.announcePointWinner = false
        store.settings.announceNextServer = false
        store.settings.announceCurrentScore = false
        store.settings.announceCriticalPoints = false
        store.settings.announceDeuce = false

        store.apply(.firstServer(player: .playerOne), source: .iphone)
        store.apply(.point(player: .playerOne), source: .iphone)

        XCTAssertEqual(announcer.spokenTexts, [])
    }

    func testStoreSpeaksCurrentScoreAndLatestStateThroughApply() {
        let announcer = FakeAnnouncer()
        let store = makeStore(announcer: announcer)

        store.apply(.firstServer(player: .playerOne), source: .iphone)
        store.apply(.point(player: .playerOne), source: .iphone)
        store.apply(.point(player: .playerOne), source: .flic)
        store.apply(.point(player: .playerTwo), source: .watch)

        XCTAssertEqual(announcer.spokenTexts, ["one serving zero", "zero serving two", "one serving two"])
        XCTAssertFalse(announcer.spokenTexts.contains { $0.contains("+1") || $0.contains("Point ") || $0.contains("serves") })
    }

    func testSpeechContinuesFromGameOneIntoGameTwo() {
        let announcer = FakeAnnouncer()
        let store = makeStore(announcer: announcer)

        store.apply(.firstServer(player: .playerOne), source: .iphone)
        score(store, player: .playerOne, count: 11)
        store.apply(.point(player: .playerTwo), source: .iphone)

        XCTAssertTrue(announcer.spokenTexts.contains("Game, Player 1"))
        XCTAssertEqual(announcer.spokenTexts.last, "one serving zero")
        XCTAssertGreaterThanOrEqual(announcer.refreshCallCount, 1)
    }

    func testUndoFromPriorityStatesClearsStaleState() {
        let announcer = FakeAnnouncer()
        let store = makeStore(announcer: announcer)

        store.apply(.firstServer(player: .playerOne), source: .iphone)
        score(store, player: .playerOne, count: 9)
        score(store, player: .playerTwo, count: 9)
        store.apply(.point(player: .playerOne), source: .iphone)
        XCTAssertEqual(announcer.spokenTexts.last, "nine serving ten, Set Point")

        store.apply(.point(player: .playerTwo), source: .iphone)
        XCTAssertEqual(announcer.spokenTexts.last, "ten serving ten, Deuce")

        store.apply(.undo, source: .watch)
        XCTAssertEqual(announcer.spokenTexts.last, "nine serving ten, Set Point")

        store.apply(.undo, source: .flic)
        XCTAssertEqual(announcer.spokenTexts.last, "nine serving nine")
    }

    func testUndoAcrossCompletedGameResetsSpeechStateAndAnnouncesCorrectScore() {
        let announcer = FakeAnnouncer()
        let store = makeStore(announcer: announcer)

        store.apply(.firstServer(player: .playerOne), source: .iphone)
        score(store, player: .playerOne, count: 11)
        XCTAssertEqual(announcer.spokenTexts.last, "Game, Player 1")

        store.apply(.undo, source: .iphone)

        XCTAssertEqual(announcer.spokenTexts.last, "zero serving ten, Set Point")
        XCTAssertGreaterThanOrEqual(announcer.refreshCallCount, 2)
    }

    func testResetStopsAndAllowsFutureSpeech() {
        let announcer = FakeAnnouncer()
        let store = makeStore(announcer: announcer)

        store.apply(.firstServer(player: .playerOne), source: .iphone)
        store.apply(.point(player: .playerOne), source: .iphone)
        store.apply(.reset, source: .iphone)
        store.apply(.firstServer(player: .playerOne), source: .iphone)
        store.apply(.point(player: .playerTwo), source: .iphone)

        XCTAssertEqual(announcer.stopCallCount, 1)
        XCTAssertEqual(Array(announcer.spokenTexts.suffix(2)), ["one serving zero", "zero serving one"])
    }

    func testAnnouncementToggleStopsRefreshesAndSuppressesSpeech() async {
        let announcer = FakeAnnouncer()
        let store = makeStore(announcer: announcer)

        store.apply(.firstServer(player: .playerOne), source: .iphone)
        store.settings.announcementsEnabled = false
        await Task.yield()
        store.apply(.point(player: .playerOne), source: .iphone)

        XCTAssertEqual(announcer.stopCallCount, 1)
        XCTAssertEqual(announcer.spokenTexts, [])

        store.settings.announcementsEnabled = true
        await Task.yield()
        store.apply(.point(player: .playerOne), source: .iphone)

        XCTAssertEqual(announcer.refreshCallCount, 1)
        XCTAssertEqual(announcer.spokenTexts, ["zero serving two"])
    }

    func testScoreAndWinnerTogglesAreIndependent() {
        let scoreSuppressedAnnouncer = FakeAnnouncer()
        let scoreSuppressedStore = makeStore(announcer: scoreSuppressedAnnouncer)
        scoreSuppressedStore.settings.announceScore = false
        scoreSuppressedStore.apply(.firstServer(player: .playerOne), source: .iphone)
        score(scoreSuppressedStore, player: .playerOne, count: 11)

        XCTAssertEqual(scoreSuppressedAnnouncer.spokenTexts, ["Game, Player 1"])

        let winnerSuppressedAnnouncer = FakeAnnouncer()
        let winnerSuppressedStore = makeStore(announcer: winnerSuppressedAnnouncer)
        winnerSuppressedStore.settings.announceWinner = false
        winnerSuppressedStore.apply(.firstServer(player: .playerOne), source: .iphone)
        score(winnerSuppressedStore, player: .playerOne, count: 11)

        XCTAssertFalse(winnerSuppressedAnnouncer.spokenTexts.contains("Game, Player 1"))
        XCTAssertEqual(winnerSuppressedAnnouncer.spokenTexts.last, "zero serving ten, Set Point")
    }

    func testSpeedSettingPersistsAndStorePassesSelectedRate() {
        resetAnnouncementDefaults()

        let settings = AppSettings()
        for speed in AnnouncementSpeed.allCases {
            settings.announcementSpeed = speed
            XCTAssertEqual(AppSettings().announcementSpeed, speed)
        }

        XCTAssertLessThan(AnnouncementSpeed.oneX.speechRate, AnnouncementSpeed.onePointFiveX.speechRate)
        XCTAssertLessThan(AnnouncementSpeed.onePointFiveX.speechRate, AnnouncementSpeed.twoX.speechRate)
        XCTAssertLessThan(AnnouncementSpeed.twoX.speechRate, AnnouncementSpeed.twoPointFiveX.speechRate)

        settings.announcementsEnabled = true
        settings.announceScore = true
        settings.announceWinner = true
        settings.announcementSpeed = .oneX
        settings.playerOneName = ""
        settings.playerTwoName = ""

        let announcer = FakeAnnouncer()
        let store = PhoneScoreStore(settings: settings, announcer: announcer, activatesConnectivity: false)
        store.apply(.firstServer(player: .playerOne), source: .iphone)
        store.apply(.point(player: .playerOne), source: .iphone)

        settings.announcementSpeed = .twoPointFiveX
        store.apply(.point(player: .playerOne), source: .iphone)

        XCTAssertEqual(announcer.spokenRates.count, 2)
        XCTAssertEqual(announcer.spokenRates[0], AnnouncementSpeed.oneX.speechRate, accuracy: 0.0001)
        XCTAssertEqual(announcer.spokenRates[1], AnnouncementSpeed.twoPointFiveX.speechRate, accuracy: 0.0001)

        resetAnnouncementDefaults()
    }

    private func makeStore(announcer: FakeAnnouncer) -> PhoneScoreStore {
        resetAnnouncementDefaults()

        let settings = AppSettings()
        settings.announcementsEnabled = true
        settings.announceScore = true
        settings.announceWinner = true
        settings.announcePointWinner = false
        settings.announceNextServer = false
        settings.announceCurrentScore = true
        settings.announceCriticalPoints = true
        settings.announceDeuce = true
        settings.announcementSpeed = .oneX
        settings.playerOneName = ""
        settings.playerTwoName = ""

        return PhoneScoreStore(
            settings: settings,
            announcer: announcer,
            activatesConnectivity: false
        )
    }

    private func makeSettings(
        pointWinner: Bool = false,
        nextServer: Bool = false,
        currentScore: Bool = true,
        critical: Bool = true,
        deuce: Bool = true,
        playerOneName: String = "",
        playerTwoName: String = ""
    ) -> AppSettings {
        resetAnnouncementDefaults()

        let settings = AppSettings()
        settings.announcePointWinner = pointWinner
        settings.announceNextServer = nextServer
        settings.announceCurrentScore = currentScore
        settings.announceCriticalPoints = critical
        settings.announceDeuce = deuce
        settings.playerOneName = playerOneName
        settings.playerTwoName = playerTwoName
        return settings
    }

    private func game(_ history: [Player]) -> GameState {
        var game = GameState()
        game.setFirstServer(.playerOne)
        history.forEach { game.addPoint(for: $0) }
        return game
    }

    private func game(repeating runs: [(Player, Int)]) -> GameState {
        game(runs.flatMap { player, count in Array(repeating: player, count: count) })
    }

    private func game(score: (playerOne: Int, playerTwo: Int)) -> GameState {
        var history: [Player] = []
        for point in 0..<max(score.playerOne, score.playerTwo) {
            if point < score.playerOne {
                history.append(.playerOne)
            }
            if point < score.playerTwo {
                history.append(.playerTwo)
            }
        }
        return game(history)
    }

    private func score(_ store: PhoneScoreStore, player: Player, count: Int) {
        for _ in 0..<count {
            store.apply(.point(player: player), source: .iphone)
        }
    }

    private func resetAnnouncementDefaults() {
        [
            "pongle.announcementsEnabled",
            "pongle.announceScore",
            "pongle.announceWinner",
            "pongle.announcePointWinner",
            "pongle.announceNextServer",
            "pongle.announceCurrentScore",
            "pongle.announceCriticalPoints",
            "pongle.announceDeuce",
            "pongle.announcementSpeed",
            "pongle.playerOneName",
            "pongle.playerTwoName"
        ].forEach { UserDefaults.standard.removeObject(forKey: $0) }
    }
}

@MainActor
private final class FakeAnnouncer: ScoreAnnouncing {
    private(set) var configuredCallCount = 0
    private(set) var spokenTexts: [String] = []
    private(set) var spokenRates: [Float] = []
    private(set) var stopCallCount = 0
    private(set) var refreshCallCount = 0

    func configureAudioSession() {
        configuredCallCount += 1
    }

    func speak(_ text: String, voiceIdentifier _: String, rate: Float) {
        spokenTexts.append(text)
        spokenRates.append(rate)
    }

    func stop() {
        stopCallCount += 1
    }

    func refresh() {
        refreshCallCount += 1
    }
}
