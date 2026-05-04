@preconcurrency import AVFoundation
import Combine
import Foundation
import os
@preconcurrency import WatchConnectivity

private let announceLog = Logger(subsystem: "com.pongle.app", category: "ANNOUNCE")

private struct ScoreAnnouncementState: Equatable {
    let text: String
    let playerOneScore: Int
    let playerTwoScore: Int
    let playerOneGames: Int
    let playerTwoGames: Int
    let completedGamesCount: Int
}

@MainActor
final class PhoneScoreStore: NSObject, ObservableObject {
    @Published private(set) var game = GameState()
    @Published private(set) var isWatchReachable = false
    @Published private(set) var lastConnectivityError: String?

    let settings: AppSettings
    lazy var flicInput = FlicInputController(settings: settings) { [weak self] event in
        self?.apply(event, source: .flic)
    }

    private let announcer = ScoreAnnouncer()
    private var session: WCSession?
    private var lastAppliedWatchSequence: Int64 = 0
    // Seed with wall-clock ms so sequences stay monotonic across phone relaunches.
    // Prevents the watch from dropping a fresh snapshot because it remembers a
    // higher sequence from a previous session.
    private var phoneSequence = PhoneScoreStore.makeInitialSequence()
    private var cancellables: Set<AnyCancellable> = []
    private var lastAnnouncedScoreState: ScoreAnnouncementState?

    init(settings: AppSettings, activatesConnectivity: Bool = true) {
        self.settings = settings
        super.init()

        announcer.configureAudioSession()
        settings.onAnnouncementsChanged = { [weak self] enabled in
            Task { @MainActor [weak self] in
                self?.lastAnnouncedScoreState = nil
                if enabled {
                    self?.announcer.refresh()
                } else {
                    self?.announcer.stop()
                }
            }
        }
        applySettingsToGame(resetOnChange: false)
        observeSettings()
        flicInput.restoreIfEnabled()

        guard activatesConnectivity, WCSession.isSupported() else {
            return
        }

        let session = WCSession.default
        self.session = session
        session.delegate = self
        session.activate()
    }

    var isAudioEnabled: Bool {
        settings.announcementsEnabled
    }

    var statusText: String {
        if let lastConnectivityError {
            return lastConnectivityError
        }

        if let matchWinner = game.matchWinner {
            return "Match - \(settings.displayName(for: matchWinner))"
        }

        if let gameWinner = game.gameWinner {
            return "Game - \(settings.displayName(for: gameWinner))"
        }

        let rules = settings.scoringRules
        let base = "First to \(rules.pointsToWin), win by \(rules.winningMargin)"
        let serverText = "Serve: \(settings.displayName(for: game.currentServer))"
        return "\(base) · Games \(game.playerOneGames)-\(game.playerTwoGames) · \(serverText)"
    }

    func addPoint(to player: Player) {
        apply(.point(player: player), source: .iphone)
    }

    func undo() {
        apply(.undo, source: .iphone)
    }

    func reset() {
        apply(.reset, source: .iphone)
    }

    /// Sets the first server for the current game from a UI tap. The
    /// underlying `GameState` ignores the request unless the game is at 0–0,
    /// so calling this mid-game is a safe no-op.
    func setFirstServer(_ player: Player) {
        apply(.firstServer(player: player), source: .iphone)
    }

    func toggleAudio() {
        settings.announcementsEnabled.toggle()

        if !settings.announcementsEnabled {
            announcer.stop()
        }
        objectWillChange.send()
    }

    @discardableResult
    func apply(_ event: ScoreEvent, source _: ScoreEventSource) -> Bool {
        let accepted: Bool

        switch event {
        case .point(let player):
            accepted = game.awaitingFirstServerChoice
                ? selectFirstServer(player)
                : addPoint(to: player)

        case .firstServer(let player):
            accepted = selectFirstServer(player)

        case .undo:
            let previousGame = game
            let hadScoredPoint = !game.history.isEmpty
            game.undoLastPoint()
            accepted = game != previousGame

            if accepted && hadScoredPoint {
                if previousGame.completedGames.count != game.completedGames.count ||
                    previousGame.matchWinner != game.matchWinner {
                    resetAnnouncementState()
                }
                announceUndo()
            }

        case .reset:
            game.reset()
            lastAnnouncedScoreState = nil
            announcer.stop()
            accepted = true
        }

        if accepted {
            broadcastCurrentStateToWatch()
        }

        return accepted
    }

    private func observeSettings() {
        Publishers.MergeMany(
            settings.$scoringMode.dropFirst().map { _ in }.eraseToAnyPublisher(),
            settings.$matchLength.dropFirst().map { _ in }.eraseToAnyPublisher()
        )
        // `@Published` fires during `willSet`; hop to the next runloop so
        // scoringRules reflects the post-mutation values before reconfiguring.
        .receive(on: DispatchQueue.main)
        .sink { [weak self] _ in self?.applySettingsToGame(resetOnChange: true) }
        .store(in: &cancellables)

        Publishers.MergeMany(
            settings.$playerOneName.dropFirst().map { _ in }.eraseToAnyPublisher(),
            settings.$playerTwoName.dropFirst().map { _ in }.eraseToAnyPublisher(),
            settings.$playerOneBatColor.dropFirst().map { _ in }.eraseToAnyPublisher(),
            settings.$playerTwoBatColor.dropFirst().map { _ in }.eraseToAnyPublisher()
        )
        // `@Published` fires during `willSet`; hop to the next runloop so the
        // broadcast reads the post-mutation value instead of the stale one.
        .receive(on: DispatchQueue.main)
        .sink { [weak self] _ in self?.broadcastCurrentStateToWatch() }
        .store(in: &cancellables)

        // Forward settings mutations as store updates so SwiftUI re-renders chips/statusText.
        settings.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    private func applySettingsToGame(resetOnChange: Bool) {
        game.configure(
            rules: settings.scoringRules,
            gamesToWin: settings.matchLength.gamesToWin
        )

        if resetOnChange {
            game.reset()
            lastAnnouncedScoreState = nil
            announcer.stop()
            broadcastCurrentStateToWatch()
        }
    }

    private func applyRemoteScoreEvent(from message: [String: Any]) {
        guard let watchSequence = Self.sequenceValue(from: message, key: ConnectivityKey.watchSequence),
              watchSequence > lastAppliedWatchSequence,
              let rawAction = message[ConnectivityKey.action] as? String,
              let action = ScoreAction(rawValue: rawAction) else {
            return
        }

        lastAppliedWatchSequence = watchSequence

        switch action {
        case .point, .firstServer:
            guard let rawPlayer = message[ConnectivityKey.player] as? Int,
                  let player = Player(rawValue: rawPlayer) else {
                return
            }

            switch action {
            case .point:
                apply(.point(player: player), source: .watch)
            case .firstServer:
                apply(.firstServer(player: player), source: .watch)
            case .undo, .reset:
                break
            }

        case .undo:
            apply(.undo, source: .watch)

        case .reset:
            apply(.reset, source: .watch)
        }
    }

    @discardableResult
    private func selectFirstServer(_ player: Player) -> Bool {
        let previousFirstServer = game.firstServer
        game.setFirstServer(player)
        return game.firstServer != previousFirstServer
    }

    @discardableResult
    private func addPoint(to player: Player) -> Bool {
        let previousHistoryCount = game.history.count
        let previousCompletedGamesCount = game.completedGames.count
        let previousMatchWinner = game.matchWinner
        game.addPoint(for: player)
        guard game.history.count > previousHistoryCount else {
            return false
        }

        announceAcceptedPoint(
            previousCompletedGamesCount: previousCompletedGamesCount,
            previousMatchWinner: previousMatchWinner
        )
        return true
    }

    private func applyRemoteSnapshot(from message: [String: Any]) {
        guard (message[ConnectivityKey.source] as? String) == ConnectivitySource.watch,
              let watchSequence = Self.sequenceValue(from: message, key: ConnectivityKey.watchSequence),
              watchSequence > lastAppliedWatchSequence else {
            return
        }

        lastAppliedWatchSequence = watchSequence
        let previousGame = game
        var didReplaceHistory = false

        if let rawHistory = message[ConnectivityKey.history] as? [Int] {
            let newHistory = rawHistory.compactMap(Player.init(rawValue:))
            didReplaceHistory = newHistory != game.history
            game.replace(withHistory: newHistory)
        }

        if let raw = message[ConnectivityKey.firstServer] as? Int {
            game.syncFirstServerForCurrentGame(raw < 0 ? nil : Player(rawValue: raw))
        }

        if didReplaceHistory {
            announceRemoteSnapshotChange(from: previousGame)
        }
    }

    private func announceRemoteSnapshotChange(from previousGame: GameState) {
        if game.history.count > previousGame.history.count {
            announceAcceptedPoint(
                previousCompletedGamesCount: previousGame.completedGames.count,
                previousMatchWinner: previousGame.matchWinner
            )
        } else if game.history.count < previousGame.history.count {
            if previousGame.completedGames.count != game.completedGames.count ||
                previousGame.matchWinner != game.matchWinner {
                resetAnnouncementState()
            }
            announceUndo()
        }
    }

    private func handleConnectivityPayload(_ payload: [String: Any]) {
        guard let kind = payload[ConnectivityKey.kind] as? String else {
            return
        }

        switch kind {
        case ConnectivityKind.scoreEvent:
            applyRemoteScoreEvent(from: payload)
        case ConnectivityKind.stateSnapshot:
            applyRemoteSnapshot(from: payload)
        default:
            break
        }
    }

    private func announceAcceptedPoint(previousCompletedGamesCount: Int, previousMatchWinner: Player?) {
        guard settings.announcementsEnabled else {
            return
        }

        if let matchWinner = game.matchWinner, matchWinner != previousMatchWinner {
            resetAnnouncementState()
            if settings.announceWinner {
                announcer.speak("Match, \(settings.displayName(for: matchWinner))", voiceIdentifier: settings.voiceIdentifier)
            }
            return
        }

        if game.completedGames.count > previousCompletedGamesCount,
           let gameWinner = game.completedGames.last?.winner {
            resetAnnouncementState()
            if settings.announceWinner {
                announcer.speak("Game, \(settings.displayName(for: gameWinner))", voiceIdentifier: settings.voiceIdentifier)
            }
            return
        }

        if settings.announceScore {
            announceCurrentScoreState()
        }
    }

    private func announceUndo() {
        guard settings.announcementsEnabled, settings.announceScore else {
            return
        }

        announceCurrentScoreState()
    }

    private func announceCurrentScoreState() {
        guard game.matchWinner == nil else {
            return
        }

        let text = compactScoreAnnouncementText()
        let state = ScoreAnnouncementState(
            text: text,
            playerOneScore: game.playerOneScore,
            playerTwoScore: game.playerTwoScore,
            playerOneGames: game.playerOneGames,
            playerTwoGames: game.playerTwoGames,
            completedGamesCount: game.completedGames.count
        )

        guard state != lastAnnouncedScoreState else {
            return
        }

        lastAnnouncedScoreState = state
        announcer.speak(text, voiceIdentifier: settings.voiceIdentifier)
    }

    private func compactScoreAnnouncementText() -> String {
        if isMatchPoint {
            return "Match Point"
        }

        if isSetPoint {
            return "Set Point"
        }

        if isDeuce {
            return "Deuce"
        }

        return "\(spokenScore(game.playerOneScore)) \(spokenScore(game.playerTwoScore))"
    }

    private var isMatchPoint: Bool {
        guard let pointPlayer = gamePointPlayer else {
            return false
        }

        return gamesWon(by: pointPlayer) + 1 >= max(game.gamesToWin, 1)
    }

    private var isSetPoint: Bool {
        guard gamePointPlayer != nil else {
            return false
        }

        return !isMatchPoint
    }

    private var isDeuce: Bool {
        let threshold = max(game.winningScore - 1, 1)
        return game.playerOneScore == game.playerTwoScore && game.playerOneScore >= threshold
    }

    private var gamePointPlayer: Player? {
        let candidates = Player.allCases.filter { player in
            gameWinnerIfPointAdded(to: player) == player
        }

        return candidates.count == 1 ? candidates[0] : nil
    }

    private func gameWinnerIfPointAdded(to player: Player) -> Player? {
        let playerOneScore = game.playerOneScore + (player == .playerOne ? 1 : 0)
        let playerTwoScore = game.playerTwoScore + (player == .playerTwo ? 1 : 0)
        let highScore = max(playerOneScore, playerTwoScore)
        let margin = abs(playerOneScore - playerTwoScore)

        guard highScore >= game.winningScore, margin >= game.winBy else {
            return nil
        }

        return playerOneScore > playerTwoScore ? .playerOne : .playerTwo
    }

    private func gamesWon(by player: Player) -> Int {
        switch player {
        case .playerOne:
            game.playerOneGames
        case .playerTwo:
            game.playerTwoGames
        }
    }

    private func spokenScore(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.numberStyle = .spellOut
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    private func resetAnnouncementState() {
        lastAnnouncedScoreState = nil
        guard settings.announcementsEnabled else {
            return
        }
        announcer.refresh()
    }

    private func broadcastCurrentStateToWatch() {
        phoneSequence += 1

        let payload: [String: Any] = [
            ConnectivityKey.kind: ConnectivityKind.stateSnapshot,
            ConnectivityKey.source: ConnectivitySource.phone,
            ConnectivityKey.phoneSequence: phoneSequence,
            ConnectivityKey.winningScore: game.winningScore,
            ConnectivityKey.winBy: game.winBy,
            ConnectivityKey.serveSwitchInterval: game.serveSwitchInterval,
            ConnectivityKey.switchesServeEveryPointFromDeuce: game.switchesServeEveryPointFromDeuce,
            ConnectivityKey.currentServer: game.currentServer.rawValue,
            ConnectivityKey.firstServer: game.firstServer?.rawValue ?? -1,
            ConnectivityKey.gamesToWin: game.gamesToWin,
            ConnectivityKey.playerOneScore: game.playerOneScore,
            ConnectivityKey.playerTwoScore: game.playerTwoScore,
            ConnectivityKey.playerOneName: settings.displayName(for: .playerOne),
            ConnectivityKey.playerTwoName: settings.displayName(for: .playerTwo),
            ConnectivityKey.playerOneColorID: settings.playerOneBatColor.rawValue,
            ConnectivityKey.playerTwoColorID: settings.playerTwoBatColor.rawValue,
            ConnectivityKey.history: game.history.map(\.rawValue)
        ]

        guard let session else {
            return
        }

        do {
            try session.updateApplicationContext(payload)
        } catch {
            lastConnectivityError = error.localizedDescription
        }

        guard session.isReachable else {
            isWatchReachable = false
            return
        }

        session.sendMessage(payload, replyHandler: nil) { [weak self] error in
            Task { @MainActor in
                self?.lastConnectivityError = error.localizedDescription
            }
        }
    }

    private static func makeInitialSequence() -> Int64 {
        Int64(Date().timeIntervalSince1970 * 1000)
    }

    private static func sequenceValue(from payload: [String: Any], key: String) -> Int64? {
        switch payload[key] {
        case let value as Int64:
            return value
        case let value as Int:
            return Int64(value)
        case let value as NSNumber:
            return value.int64Value
        default:
            return nil
        }
    }
}

extension PhoneScoreStore: WCSessionDelegate {
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        let isReachable = session.isReachable
        let errorMessage = error?.localizedDescription

        Task { @MainActor [weak self] in
            self?.isWatchReachable = isReachable
            self?.lastConnectivityError = errorMessage
            self?.broadcastCurrentStateToWatch()
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {
        Task { @MainActor [weak self] in
            self?.isWatchReachable = false
        }
    }

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()

        Task { @MainActor [weak self] in
            self?.isWatchReachable = session.isReachable
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        let isReachable = session.isReachable

        Task { @MainActor [weak self] in
            self?.isWatchReachable = isReachable
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Task { @MainActor [weak self] in
            self?.isWatchReachable = session.isReachable
            self?.handleConnectivityPayload(message)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        Task { @MainActor [weak self] in
            self?.isWatchReachable = session.isReachable
            self?.handleConnectivityPayload(applicationContext)
        }
    }
}

@MainActor
private final class ScoreAnnouncer: NSObject, AVSpeechSynthesizerDelegate {
    private struct AnnouncementRequest {
        let text: String
        let voiceIdentifier: String
    }

    private var synthesizer = AVSpeechSynthesizer()
    private var isAudioSessionReady = false
    private var wasSpeakingBeforeInterruption = false
    private var interruptionCancellable: AnyCancellable?

    /// Single-slot "latest state wins" pending request. Any new request
    /// overwrites the previous one so stale intermediate announcements are
    /// discarded during rapid input bursts.
    private var pendingRequest: AnnouncementRequest?
    private var isCancelling = false
    private var debounceTask: Task<Void, Never>?
    private var watchdogTask: Task<Void, Never>?

    private static let debounceDelay: UInt64 = 120_000_000 // 120ms
    private static let cancelWatchdogDelay: UInt64 = 500_000_000 // 500ms

    override init() {
        super.init()
        synthesizer.delegate = self
        interruptionCancellable = NotificationCenter.default
            .publisher(
                for: AVAudioSession.interruptionNotification,
                object: AVAudioSession.sharedInstance()
            )
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                Task { @MainActor in
                    self?.handleInterruption(notification)
                }
            }
    }

    func speak(_ text: String, voiceIdentifier: String = "") {
        enqueue(text: text, voiceIdentifier: voiceIdentifier)
    }

    private func enqueue(text: String, voiceIdentifier: String) {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleaned.isEmpty else { return }

        configureAudioSession()

        announceLog.log("enqueue text=\"\(cleaned, privacy: .public)\" speaking=\(self.synthesizer.isSpeaking) cancelling=\(self.isCancelling)")

        pendingRequest = AnnouncementRequest(
            text: cleaned,
            voiceIdentifier: voiceIdentifier
        )

        debounceTask?.cancel()

        if synthesizer.isSpeaking || isCancelling {
            requestCancel()
            return
        }

        debounceTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: Self.debounceDelay)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self?.dispatchPending()
            }
        }
    }

    private func dispatchPending() {
        guard pendingRequest != nil else {
            announceLog.log("dispatch skipped: no pending request")
            return
        }

        announceLog.log("dispatch speaking=\(self.synthesizer.isSpeaking) cancelling=\(self.isCancelling)")

        if synthesizer.isSpeaking {
            // Don't speak in the same runloop tick as stopSpeaking — that
            // races and can leave the synthesizer permanently silent.
            // Defer until didCancel fires (or watchdog times out).
            requestCancel()
        } else {
            flush()
        }
    }

    private func requestCancel() {
        guard !isCancelling else {
            announceLog.log("requestCancel skipped: already cancelling")
            return
        }
        isCancelling = true
        announceLog.log("requestCancel: stopSpeaking(.immediate)")
        synthesizer.stopSpeaking(at: .immediate)

        // Watchdog: AVSpeechSynthesizer occasionally fails to deliver
        // didCancel after stopSpeaking, which would otherwise wedge the
        // announcer permanently. If that happens we flush ourselves.
        watchdogTask?.cancel()
        watchdogTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: Self.cancelWatchdogDelay)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard let self else { return }
                if self.isCancelling {
                    announceLog.error("WATCHDOG fired — didCancel never arrived; forcing flush")
                    self.isCancelling = false
                    self.flush()
                }
            }
        }
    }

    private func flush() {
        watchdogTask?.cancel()
        watchdogTask = nil
        isCancelling = false

        guard let request = pendingRequest else {
            announceLog.log("flush skipped: no pending request")
            return
        }
        pendingRequest = nil
        announceLog.log("flush speaking text=\"\(request.text, privacy: .public)\"")

        let utterance = AVSpeechUtterance(string: request.text)
        utterance.rate = min(AVSpeechUtteranceDefaultSpeechRate + 0.06, 0.58)
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        utterance.postUtteranceDelay = 0
        utterance.voice = Self.preferredVoice(fallbackIdentifier: request.voiceIdentifier)
        synthesizer.speak(utterance)
    }

    func stop() {
        announceLog.log("stop()")
        debounceTask?.cancel()
        debounceTask = nil
        watchdogTask?.cancel()
        watchdogTask = nil
        pendingRequest = nil
        isCancelling = false
        synthesizer.stopSpeaking(at: .immediate)
    }

    func refresh() {
        announceLog.log("refresh() — rebuilding synthesizer")
        // Hard reset: rebuild the synthesizer to recover from any wedged
        // internal state (e.g. when toggling Announcements OFF/ON after a
        // rapid-input lockup).
        debounceTask?.cancel()
        debounceTask = nil
        watchdogTask?.cancel()
        watchdogTask = nil
        pendingRequest = nil
        isCancelling = false
        synthesizer.stopSpeaking(at: .immediate)
        synthesizer.delegate = nil
        synthesizer = AVSpeechSynthesizer()
        synthesizer.delegate = self
        isAudioSessionReady = false
        configureAudioSession()
    }

    func configureAudioSession() {
        guard !isAudioSessionReady else {
            return
        }

        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .spokenAudio, options: [.mixWithOthers])
            try audioSession.setActive(true)
            isAudioSessionReady = true
        } catch {
            isAudioSessionReady = false
        }
    }

    private func handleSpeechFinishedOrCancelled() {
        if isCancelling, synthesizer.isSpeaking {
            announceLog.log("callback while cancellation still settling; watchdog remains armed")
            return
        }

        watchdogTask?.cancel()
        watchdogTask = nil
        isCancelling = false

        // Only flush when there is a fresh pending request waiting and the
        // synthesizer is fully idle after a finish/cancel callback.
        if pendingRequest != nil, !synthesizer.isSpeaking {
            flush()
        }
    }

    nonisolated func speechSynthesizer(_: AVSpeechSynthesizer, didCancel _: AVSpeechUtterance) {
        Task { @MainActor [weak self] in
            announceLog.log("delegate didCancel")
            self?.handleSpeechFinishedOrCancelled()
        }
    }

    nonisolated func speechSynthesizer(_: AVSpeechSynthesizer, didFinish _: AVSpeechUtterance) {
        Task { @MainActor [weak self] in
            announceLog.log("delegate didFinish")
            self?.handleSpeechFinishedOrCancelled()
        }
    }

    private static func preferredVoice(fallbackIdentifier: String) -> AVSpeechSynthesisVoice? {
        if let samantha = samanthaVoice() {
            return samantha
        }

        if !fallbackIdentifier.isEmpty,
           let voice = AVSpeechSynthesisVoice(identifier: fallbackIdentifier) {
            return voice
        }

        return AVSpeechSynthesisVoice(language: "en-US")
            ?? AVSpeechSynthesisVoice(language: AVSpeechSynthesisVoice.currentLanguageCode())
    }

    private static func samanthaVoice() -> AVSpeechSynthesisVoice? {
        AVSpeechSynthesisVoice.speechVoices()
            .first { $0.name == "Samantha" && $0.language.hasPrefix("en") }
    }

    private func handleInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }

        switch type {
        case .began:
            wasSpeakingBeforeInterruption = synthesizer.isSpeaking
            isAudioSessionReady = false

        case .ended:
            configureAudioSession()

            let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue ?? 0)
            if wasSpeakingBeforeInterruption || options.contains(.shouldResume), synthesizer.isPaused {
                synthesizer.continueSpeaking()
            }
            wasSpeakingBeforeInterruption = false

        @unknown default:
            break
        }
    }
}

private enum ConnectivityKey {
    static let kind = "kind"
    static let source = "source"
    static let watchSequence = "watchSequence"
    static let phoneSequence = "phoneSequence"
    static let action = "action"
    static let player = "player"
    static let winningScore = "winningScore"
    static let winBy = "winBy"
    static let serveSwitchInterval = "serveSwitchInterval"
    static let switchesServeEveryPointFromDeuce = "switchesServeEveryPointFromDeuce"
    static let currentServer = "currentServer"
    static let firstServer = "firstServer"
    static let gamesToWin = "gamesToWin"
    static let playerOneScore = "playerOneScore"
    static let playerTwoScore = "playerTwoScore"
    static let playerOneName = "playerOneName"
    static let playerTwoName = "playerTwoName"
    static let playerOneColorID = "playerOneColorID"
    static let playerTwoColorID = "playerTwoColorID"
    static let history = "history"
}

private enum ConnectivityKind {
    static let scoreEvent = "scoreEvent"
    static let stateSnapshot = "stateSnapshot"
}

private enum ConnectivitySource {
    static let phone = "phone"
    static let watch = "watch"
}

enum ScoreEventSource {
    case iphone
    case watch
    case flic
}
