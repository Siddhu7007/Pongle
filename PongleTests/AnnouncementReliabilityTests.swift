import XCTest
@testable import Pongle

@MainActor
final class AnnouncementReliabilityTests: XCTestCase {
    func testScoringModesExposeRequestedRulesAndLabels() {
        XCTAssertEqual(ScoringMode.allCases.map(\.shortLabel), ["3 points", "11 points", "21 points"])

        XCTAssertEqual(ScoringMode.three.rules.pointsToWin, 3)
        XCTAssertEqual(ScoringMode.three.rules.winningMargin, 2)
        XCTAssertEqual(ScoringMode.three.rules.serveSwitchInterval, 2)
        XCTAssertTrue(ScoringMode.three.rules.switchesServeEveryPointFromDeuce)

        XCTAssertEqual(ScoringMode.twentyOne.rules.pointsToWin, 21)
        XCTAssertEqual(ScoringMode.twentyOne.rules.winningMargin, 2)
        XCTAssertEqual(ScoringMode.twentyOne.rules.serveSwitchInterval, 5)
        XCTAssertTrue(ScoringMode.twentyOne.rules.switchesServeEveryPointFromDeuce)
    }

    func testMatchLengthsExposeRequestedLabelsAndGamesToWin() {
        XCTAssertEqual(MatchLength.allCases.map(\.shortLabel), ["1 game", "Best of 3", "Best of 5", "Best of 7"])
        XCTAssertEqual(MatchLength.allCases.map(\.gamesToWin), [1, 2, 3, 4])
    }

    func testScoringAndMatchLengthSettingsPersistAcrossReloads() {
        resetAnnouncementDefaults()

        let settings = AppSettings()
        settings.scoringMode = .twentyOne
        settings.matchLength = .bestOfSeven

        let reloaded = AppSettings()
        XCTAssertEqual(reloaded.scoringMode, .twentyOne)
        XCTAssertEqual(reloaded.matchLength, .bestOfSeven)

        resetAnnouncementDefaults()
    }

    func testMissingScoringAndMatchLengthSettingsDefaultToElevenAndBestOfThree() {
        resetAnnouncementDefaults()

        let settings = AppSettings()
        XCTAssertEqual(settings.scoringMode, .eleven)
        XCTAssertEqual(settings.matchLength, .bestOfThree)

        resetAnnouncementDefaults()
    }

    func testTwentyOnePointModeSwitchesServeEveryFiveThenEveryPointFromDeuce() {
        var game = GameState()
        game.configure(rules: ScoringMode.twentyOne.rules, gamesToWin: MatchLength.oneSet.gamesToWin)
        game.setFirstServer(.playerOne)

        XCTAssertEqual(game.currentServer, .playerOne)
        addPoints(5, to: .playerOne, in: &game)
        XCTAssertEqual(game.currentServer, .playerTwo)
        addPoints(5, to: .playerOne, in: &game)
        XCTAssertEqual(game.currentServer, .playerOne)
        addPoints(5, to: .playerOne, in: &game)
        XCTAssertEqual(game.currentServer, .playerTwo)
        addPoints(5, to: .playerTwo, in: &game)
        XCTAssertEqual(game.currentServer, .playerOne)

        game.reset()
        game.setFirstServer(.playerOne)
        for _ in 0..<20 {
            game.addPoint(for: .playerOne)
            game.addPoint(for: .playerTwo)
        }

        XCTAssertEqual(game.playerOneScore, 20)
        XCTAssertEqual(game.playerTwoScore, 20)
        XCTAssertEqual(game.currentServer, .playerOne)

        game.addPoint(for: .playerOne)
        XCTAssertEqual(game.currentServer, .playerTwo)

        game.addPoint(for: .playerTwo)
        XCTAssertEqual(game.currentServer, .playerOne)
    }

    func testThreePointModeUsesWinByTwoAndDeuceServeSwitching() {
        var game = GameState()
        game.configure(rules: ScoringMode.three.rules, gamesToWin: MatchLength.oneSet.gamesToWin)
        game.setFirstServer(.playerOne)

        game.addPoint(for: .playerOne)
        game.addPoint(for: .playerTwo)
        game.addPoint(for: .playerOne)
        game.addPoint(for: .playerTwo)

        XCTAssertEqual(game.playerOneScore, 2)
        XCTAssertEqual(game.playerTwoScore, 2)
        XCTAssertNil(game.gameWinner)
        XCTAssertEqual(game.currentServer, .playerOne)

        game.addPoint(for: .playerOne)
        XCTAssertEqual(game.playerOneScore, 3)
        XCTAssertEqual(game.playerTwoScore, 2)
        XCTAssertNil(game.gameWinner)
        XCTAssertEqual(game.currentServer, .playerTwo)

        game.addPoint(for: .playerOne)
        XCTAssertEqual(game.completedGames.last?.winner, .playerOne)
        XCTAssertEqual(game.matchWinner, .playerOne)
    }

    func testAdvancedAnnouncementSettingsPersistAndDefaultToCurrentBehavior() {
        resetAnnouncementDefaults()

        let defaults = AppSettings()
        XCTAssertFalse(defaults.announcePointWinner)
        XCTAssertFalse(defaults.announceNextServer)
        XCTAssertTrue(defaults.announceCurrentScore)
        XCTAssertTrue(defaults.announceCriticalPoints)
        XCTAssertTrue(defaults.announceDeuce)
        XCTAssertTrue(defaults.announceUndoLastPoint)
        XCTAssertEqual(defaults.announcementSpeed, .oneX)

        defaults.announcePointWinner = true
        defaults.announceNextServer = true
        defaults.announceCurrentScore = false
        defaults.announceCriticalPoints = false
        defaults.announceDeuce = false
        defaults.announceUndoLastPoint = false
        defaults.announcementSpeed = .twoPointFiveX

        let reloaded = AppSettings()
        XCTAssertTrue(reloaded.announcePointWinner)
        XCTAssertTrue(reloaded.announceNextServer)
        XCTAssertFalse(reloaded.announceCurrentScore)
        XCTAssertFalse(reloaded.announceCriticalPoints)
        XCTAssertFalse(reloaded.announceDeuce)
        XCTAssertFalse(reloaded.announceUndoLastPoint)
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

    func testFirstServerPromptLanguageMatchesInputMode() {
        XCTAssertEqual(
            FirstServerChoiceInputMode.mode(tapInputEnabled: true, externalInputAvailable: false)
                .instructionLines(playerOneName: "Cody", playerTwoName: "Brent"),
            ["Tap Cody or Brent to choose who serves first"]
        )

        XCTAssertEqual(
            FirstServerChoiceInputMode.mode(tapInputEnabled: false, externalInputAvailable: true)
                .instructionLines(playerOneName: "Cody", playerTwoName: "Brent"),
            [
                "Single press = Cody serves",
                "Double press = Brent serves"
            ]
        )

        XCTAssertEqual(
            FirstServerChoiceInputMode.mode(tapInputEnabled: true, externalInputAvailable: true)
                .instructionLines(playerOneName: "Cody", playerTwoName: "Brent"),
            ["Tap a player or use single/double press to choose who serves first"]
        )

        XCTAssertEqual(
            FirstServerChoiceInputMode.mode(tapInputEnabled: false, externalInputAvailable: false, dualInputsAssigned: true)
                .instructionLines(playerOneName: "Cody", playerTwoName: "Brent"),
            ["Each player uses their own button or watch to choose who serves first"]
        )
    }

    func testNewMatchAwaitsFirstServerAndPointInputSelectsWithoutScoring() {
        let announcer = FakeAnnouncer()
        let store = makeStore(announcer: announcer)
        store.settings.playerOneName = "Cody"
        store.settings.playerTwoName = "Brent"

        XCTAssertTrue(store.game.awaitingFirstServerChoice)
        XCTAssertEqual(store.game.playerOneScore, 0)
        XCTAssertEqual(store.game.playerTwoScore, 0)

        XCTAssertTrue(store.apply(.point(player: .playerOne), source: .iphone))

        XCTAssertFalse(store.game.awaitingFirstServerChoice)
        XCTAssertEqual(store.game.firstServer, .playerOne)
        XCTAssertEqual(store.game.history, [])
        XCTAssertEqual(store.game.playerOneScore, 0)
        XCTAssertEqual(store.game.playerTwoScore, 0)
        XCTAssertEqual(announcer.spokenTexts, ["Cody serves"])
    }

    func testFirstServerSelectionAnnouncementUsesGlobalAnnouncementToggleOnly() {
        let playerOneAnnouncer = FakeAnnouncer()
        let playerOneStore = makeStore(announcer: playerOneAnnouncer)
        playerOneStore.settings.playerOneName = "Cody"
        playerOneStore.settings.announceNextServer = false

        playerOneStore.apply(.firstServer(player: .playerOne), source: .iphone)
        XCTAssertEqual(playerOneAnnouncer.spokenTexts, ["Cody serves"])

        let playerTwoAnnouncer = FakeAnnouncer()
        let playerTwoStore = makeStore(announcer: playerTwoAnnouncer)
        playerTwoStore.settings.playerTwoName = "Brent"
        playerTwoStore.settings.announceNextServer = false

        playerTwoStore.apply(.point(player: .playerTwo), source: .flic)
        XCTAssertEqual(playerTwoStore.game.firstServer, .playerTwo)
        XCTAssertEqual(playerTwoStore.game.history, [])
        XCTAssertEqual(playerTwoAnnouncer.spokenTexts, ["Brent serves"])

        let mutedAnnouncer = FakeAnnouncer()
        let mutedStore = makeStore(announcer: mutedAnnouncer)
        mutedStore.settings.announcementsEnabled = false
        mutedStore.apply(.firstServer(player: .playerOne), source: .iphone)

        XCTAssertEqual(mutedAnnouncer.spokenTexts, [])
    }

    func testWatchSnapshotAnnouncesFirstServerWhenScoreEventNeverArrives() {
        let announcer = FakeAnnouncer()
        let store = makeStore(announcer: announcer)
        store.settings.playerOneName = "Cody"

        store.applyRemoteSnapshot(from: watchSnapshotPayload(
            sequence: 1_000,
            firstServer: .playerOne,
            history: []
        ))

        XCTAssertEqual(store.game.firstServer, .playerOne)
        XCTAssertEqual(announcer.spokenTexts, ["Cody serves"])
    }

    func testWatchSnapshotDoesNotReAnnounceWhenFirstServerAlreadyKnown() {
        let announcer = FakeAnnouncer()
        let store = makeStore(announcer: announcer)
        store.settings.playerOneName = "Cody"

        store.apply(.firstServer(player: .playerOne), source: .iphone)
        XCTAssertEqual(announcer.spokenTexts, ["Cody serves"])

        store.applyRemoteSnapshot(from: watchSnapshotPayload(
            sequence: 1_000,
            firstServer: .playerOne,
            history: []
        ))

        XCTAssertEqual(announcer.spokenTexts, ["Cody serves"])
    }

    func testWatchSnapshotSuppressesFirstServerAnnouncementWhenPointsAlreadyScored() {
        let announcer = FakeAnnouncer()
        let store = makeStore(announcer: announcer)
        store.settings.playerOneName = "Cody"

        store.applyRemoteSnapshot(from: watchSnapshotPayload(
            sequence: 1_000,
            firstServer: .playerOne,
            history: [.playerOne]
        ))

        XCTAssertEqual(store.game.firstServer, .playerOne)
        XCTAssertEqual(store.game.history, [.playerOne])
        XCTAssertFalse(announcer.spokenTexts.contains("Cody serves"))
    }

    func testEffectiveTapInputForcesOnWhenNoExternalInputDeviceAvailable() {
        let store = makeStore(announcer: FakeAnnouncer())
        store.settings.iphoneTapInputEnabled = false
        store.settings.flicInputEnabled = false

        // makeStore uses activatesConnectivity: false, so `isWatchAppAvailable`
        // stays at its initial false. With no Flic either, there's no external
        // input device — taps must work or the user is stuck.
        XCTAssertFalse(store.externalInputAvailable)
        XCTAssertTrue(store.effectiveTapInputEnabled)
    }

    func testEffectiveTapInputHonorsStoredPreferenceWhenFlicIsAvailable() {
        let store = makeStore(announcer: FakeAnnouncer())
        store.settings.iphoneTapInputEnabled = false
        store.settings.flicInputEnabled = true

        XCTAssertTrue(store.externalInputAvailable)
        XCTAssertFalse(store.effectiveTapInputEnabled)
    }

    func testEffectiveTapInputStaysOnWhenUserExplicitlyEnabledIt() {
        let store = makeStore(announcer: FakeAnnouncer())
        store.settings.iphoneTapInputEnabled = true
        store.settings.flicInputEnabled = true

        XCTAssertTrue(store.externalInputAvailable)
        XCTAssertTrue(store.effectiveTapInputEnabled)
    }

    func testUndoAnnouncementCombinesPostUndoServerAndScore() {
        let announcer = FakeAnnouncer()
        let store = makeStore(announcer: announcer)
        store.settings.playerOneName = "Cody"
        store.settings.playerTwoName = "Brent"
        store.settings.announceNextServer = true

        advanceToFiveSevenAfterNextUndo(store)
        store.apply(.undo, source: .iphone)

        XCTAssertEqual(announcer.spokenTexts.last, "Undo Last Point, Cody serves, five serving seven")
    }

    func testUndoAnnouncementToggleCombinations() {
        let undoOnlyAnnouncer = FakeAnnouncer()
        let undoOnlyStore = makeStore(announcer: undoOnlyAnnouncer)
        undoOnlyStore.settings.announceNextServer = false
        undoOnlyStore.settings.announceCurrentScore = false
        advanceToFiveSevenAfterNextUndo(undoOnlyStore)
        undoOnlyStore.apply(.undo, source: .iphone)
        XCTAssertEqual(undoOnlyAnnouncer.spokenTexts.last, "Undo Last Point")

        let serverOnlyAnnouncer = FakeAnnouncer()
        let serverOnlyStore = makeStore(announcer: serverOnlyAnnouncer)
        serverOnlyStore.settings.playerOneName = "Cody"
        serverOnlyStore.settings.announceNextServer = true
        serverOnlyStore.settings.announceCurrentScore = false
        advanceToFiveSevenAfterNextUndo(serverOnlyStore)
        serverOnlyStore.apply(.undo, source: .iphone)
        XCTAssertEqual(serverOnlyAnnouncer.spokenTexts.last, "Undo Last Point, Cody serves")

        let undoDisabledAnnouncer = FakeAnnouncer()
        let undoDisabledStore = makeStore(announcer: undoDisabledAnnouncer)
        undoDisabledStore.settings.playerOneName = "Cody"
        undoDisabledStore.settings.announceUndoLastPoint = false
        undoDisabledStore.settings.announceNextServer = true
        undoDisabledStore.settings.announceCurrentScore = true
        advanceToFiveSevenAfterNextUndo(undoDisabledStore)
        undoDisabledStore.apply(.undo, source: .iphone)
        XCTAssertEqual(undoDisabledAnnouncer.spokenTexts.last, "Cody serves, five serving seven")
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

        XCTAssertEqual(announcer.spokenTexts, ["Player 1 serves"])
    }

    func testStoreSpeaksCurrentScoreAndLatestStateThroughApply() {
        let announcer = FakeAnnouncer()
        let store = makeStore(announcer: announcer)

        store.apply(.firstServer(player: .playerOne), source: .iphone)
        store.apply(.point(player: .playerOne), source: .iphone)
        store.apply(.point(player: .playerOne), source: .flic)
        store.apply(.point(player: .playerTwo), source: .watch)

        XCTAssertEqual(announcer.spokenTexts, ["Player 1 serves", "one serving zero", "zero serving two", "one serving two"])
        XCTAssertFalse(announcer.spokenTexts.contains { $0.contains("+1") || $0.contains("Point ") })
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
        XCTAssertEqual(announcer.spokenTexts.last, "Undo Last Point, nine serving ten, Set Point")

        store.apply(.undo, source: .flic)
        XCTAssertEqual(announcer.spokenTexts.last, "Undo Last Point, nine serving nine")
    }

    func testUndoAcrossCompletedGameResetsSpeechStateAndAnnouncesCorrectScore() {
        let announcer = FakeAnnouncer()
        let store = makeStore(announcer: announcer)

        store.apply(.firstServer(player: .playerOne), source: .iphone)
        score(store, player: .playerOne, count: 11)
        XCTAssertEqual(announcer.spokenTexts.last, "Game, Player 1")

        store.apply(.undo, source: .iphone)

        XCTAssertEqual(announcer.spokenTexts.last, "Undo Last Point, zero serving ten, Set Point")
        XCTAssertGreaterThanOrEqual(announcer.refreshCallCount, 2)
    }

    func testUndoAcrossMatchWinningPointAnnouncesPostUndoMatchPoint() {
        let announcer = FakeAnnouncer()
        let store = makeStore(announcer: announcer)

        store.apply(.firstServer(player: .playerOne), source: .iphone)
        score(store, player: .playerOne, count: 11)
        score(store, player: .playerOne, count: 10)
        score(store, player: .playerTwo, count: 9)
        store.apply(.point(player: .playerOne), source: .iphone)
        XCTAssertEqual(announcer.spokenTexts.last, "Match, Player 1")

        store.apply(.undo, source: .iphone)

        XCTAssertEqual(announcer.spokenTexts.last, "Undo Last Point, ten serving nine, Match Point")
        XCTAssertNil(store.game.matchWinner)
    }

    func testUndoFirstServerChoiceReturnsToPromptStateWithoutInvalidScoreAnnouncement() {
        let announcer = FakeAnnouncer()
        let store = makeStore(announcer: announcer)

        store.apply(.firstServer(player: .playerOne), source: .iphone)
        store.apply(.undo, source: .iphone)

        XCTAssertTrue(store.game.awaitingFirstServerChoice)
        XCTAssertNil(store.game.firstServer)
        XCTAssertEqual(store.game.playerOneScore, 0)
        XCTAssertEqual(store.game.playerTwoScore, 0)
        XCTAssertEqual(store.game.history, [])
        XCTAssertEqual(announcer.spokenTexts, ["Player 1 serves"])
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
        XCTAssertEqual(Array(announcer.spokenTexts.suffix(2)), ["Player 1 serves", "zero serving one"])
    }

    func testAnnouncementToggleStopsRefreshesAndSuppressesSpeech() async {
        let announcer = FakeAnnouncer()
        let store = makeStore(announcer: announcer)

        store.apply(.firstServer(player: .playerOne), source: .iphone)
        store.settings.announcementsEnabled = false
        await Task.yield()
        store.apply(.point(player: .playerOne), source: .iphone)

        XCTAssertEqual(announcer.stopCallCount, 1)
        XCTAssertEqual(announcer.spokenTexts, ["Player 1 serves"])

        store.settings.announcementsEnabled = true
        await Task.yield()
        store.apply(.point(player: .playerOne), source: .iphone)

        XCTAssertEqual(announcer.refreshCallCount, 1)
        XCTAssertEqual(announcer.spokenTexts, ["Player 1 serves", "zero serving two"])
    }

    func testScoreAndWinnerTogglesAreIndependent() {
        let scoreSuppressedAnnouncer = FakeAnnouncer()
        let scoreSuppressedStore = makeStore(announcer: scoreSuppressedAnnouncer)
        scoreSuppressedStore.settings.announceScore = false
        scoreSuppressedStore.apply(.firstServer(player: .playerOne), source: .iphone)
        score(scoreSuppressedStore, player: .playerOne, count: 11)

        XCTAssertEqual(scoreSuppressedAnnouncer.spokenTexts, ["Player 1 serves", "Game, Player 1"])

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

        XCTAssertEqual(announcer.spokenRates.count, 3)
        XCTAssertEqual(announcer.spokenRates[0], AnnouncementSpeed.oneX.speechRate, accuracy: 0.0001)
        XCTAssertEqual(announcer.spokenRates[1], AnnouncementSpeed.oneX.speechRate, accuracy: 0.0001)
        XCTAssertEqual(announcer.spokenRates[2], AnnouncementSpeed.twoPointFiveX.speechRate, accuracy: 0.0001)

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
        settings.announceUndoLastPoint = true
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
        undoLastPoint: Bool = true,
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
        settings.announceUndoLastPoint = undoLastPoint
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

    private func addPoints(_ count: Int, to player: Player, in game: inout GameState) {
        for _ in 0..<count {
            game.addPoint(for: player)
        }
    }

    /// Mirrors the payload the watch builds in `WatchScoreStore.publishCurrentState`.
    /// Raw string keys are intentional — `ConnectivityKey` is fileprivate in the
    /// store and unreachable from tests, but the wire format is what the
    /// snapshot handler ultimately reads.
    private func watchSnapshotPayload(
        sequence: Int64,
        firstServer: Player?,
        history: [Player]
    ) -> [String: Any] {
        [
            "kind": "stateSnapshot",
            "source": "watch",
            "watchSequence": sequence,
            "firstServer": firstServer?.rawValue ?? -1,
            "history": history.map(\.rawValue)
        ]
    }

    private func advanceToFiveSevenAfterNextUndo(_ store: PhoneScoreStore) {
        store.apply(.firstServer(player: .playerOne), source: .iphone)
        score(store, player: .playerOne, count: 5)
        score(store, player: .playerTwo, count: 8)
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
            "pongle.announceUndoLastPoint",
            "pongle.announcementSpeed",
            "pongle.playerOneName",
            "pongle.playerTwoName",
            "pongle.scoringMode",
            "pongle.matchLength"
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
