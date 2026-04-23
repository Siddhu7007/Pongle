@preconcurrency import AVFoundation
import Combine
import Foundation
@preconcurrency import WatchConnectivity

@MainActor
final class PhoneScoreStore: NSObject, ObservableObject {
    @Published private(set) var game = GameState()
    @Published private(set) var isWatchReachable = false
    @Published private(set) var lastConnectivityError: String?

    let settings: AppSettings

    private let announcer = ScoreAnnouncer()
    private var session: WCSession?
    private var lastAppliedWatchSequence: Int64 = 0
    // Seed with wall-clock ms so sequences stay monotonic across phone relaunches.
    // Prevents the watch from dropping a fresh snapshot because it remembers a
    // higher sequence from a previous session.
    private var phoneSequence = PhoneScoreStore.makeInitialSequence()
    private var cancellables: Set<AnyCancellable> = []

    init(settings: AppSettings, activatesConnectivity: Bool = true) {
        self.settings = settings
        super.init()

        applySettingsToGame(resetOnChange: false)
        observeSettings()

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

        let base = "First to \(settings.pointsToWin.rawValue), win by 2"
        guard settings.matchLength != .single else {
            return base
        }
        return "\(base) · Games \(game.playerOneGames)–\(game.playerTwoGames)"
    }

    func addPoint(to player: Player) {
        _ = addPoint(to: player, broadcastsToWatch: true)
    }

    func undo() {
        guard game.canUndo else {
            return
        }

        game.undoLastPoint()
        announceCurrentScore()
        broadcastCurrentStateToWatch()
    }

    func reset() {
        game.reset()
        announcer.stop()
        broadcastCurrentStateToWatch()
    }

    func toggleAudio() {
        settings.announcementsEnabled.toggle()

        if !settings.announcementsEnabled {
            announcer.stop()
        }
        objectWillChange.send()
    }

    private func observeSettings() {
        settings.$pointsToWin
            .dropFirst()
            .sink { [weak self] _ in self?.applySettingsToGame(resetOnChange: true) }
            .store(in: &cancellables)

        settings.$matchLength
            .dropFirst()
            .sink { [weak self] _ in self?.applySettingsToGame(resetOnChange: true) }
            .store(in: &cancellables)

        Publishers.MergeMany(
            settings.$playerOneName.dropFirst().map { _ in }.eraseToAnyPublisher(),
            settings.$playerTwoName.dropFirst().map { _ in }.eraseToAnyPublisher(),
            settings.$playerOneBatColor.dropFirst().map { _ in }.eraseToAnyPublisher(),
            settings.$playerTwoBatColor.dropFirst().map { _ in }.eraseToAnyPublisher(),
            settings.$watchMode.dropFirst().map { _ in }.eraseToAnyPublisher(),
            settings.$watchSwipeEnabled.dropFirst().map { _ in }.eraseToAnyPublisher()
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
            winningScore: settings.pointsToWin.rawValue,
            gamesToWin: settings.matchLength.gamesToWin
        )

        if resetOnChange {
            game.reset()
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
        case .point:
            guard let rawPlayer = message[ConnectivityKey.player] as? Int,
                  let player = Player(rawValue: rawPlayer) else {
                return
            }
            _ = addPoint(to: player, broadcastsToWatch: false)

        case .undo:
            let previousHistoryCount = game.history.count
            game.undoLastPoint()
            if game.history.count < previousHistoryCount {
                announceCurrentScore()
            }

        case .reset:
            game.reset()
            announcer.stop()
        }

        broadcastCurrentStateToWatch()
    }

    @discardableResult
    private func addPoint(to player: Player, broadcastsToWatch: Bool) -> Bool {
        let previousHistoryCount = game.history.count
        game.addPoint(for: player)
        guard game.history.count > previousHistoryCount else {
            return false
        }

        announceCurrentScore()

        if broadcastsToWatch {
            broadcastCurrentStateToWatch()
        }

        return true
    }

    private func applyRemoteSnapshot(from message: [String: Any]) {
        guard (message[ConnectivityKey.source] as? String) == ConnectivitySource.watch,
              let watchSequence = Self.sequenceValue(from: message, key: ConnectivityKey.watchSequence),
              watchSequence > lastAppliedWatchSequence else {
            return
        }

        lastAppliedWatchSequence = watchSequence

        if let rawHistory = message[ConnectivityKey.history] as? [Int] {
            game.replace(withHistory: rawHistory.compactMap(Player.init(rawValue:)))
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

    private func announceCurrentScore() {
        guard settings.announcementsEnabled else {
            return
        }

        if let matchWinner = game.matchWinner {
            if settings.announceWinner {
                announcer.speak("Match, \(settings.displayName(for: matchWinner))", voiceIdentifier: settings.voiceIdentifier)
            }
            return
        }

        if let gameWinner = game.gameWinner {
            if settings.announceWinner {
                announcer.speak("Game, \(settings.displayName(for: gameWinner))", voiceIdentifier: settings.voiceIdentifier)
            }
            return
        }

        if settings.announceScore {
            announcer.speak(
                "\(game.playerOneScore) \(game.playerTwoScore)",
                voiceIdentifier: settings.voiceIdentifier
            )
        }
    }

    private func broadcastCurrentStateToWatch() {
        phoneSequence += 1

        let payload: [String: Any] = [
            ConnectivityKey.kind: ConnectivityKind.stateSnapshot,
            ConnectivityKey.source: ConnectivitySource.phone,
            ConnectivityKey.phoneSequence: phoneSequence,
            ConnectivityKey.winningScore: game.winningScore,
            ConnectivityKey.gamesToWin: game.gamesToWin,
            ConnectivityKey.playerOneScore: game.playerOneScore,
            ConnectivityKey.playerTwoScore: game.playerTwoScore,
            ConnectivityKey.playerOneName: settings.displayName(for: .playerOne),
            ConnectivityKey.playerTwoName: settings.displayName(for: .playerTwo),
            ConnectivityKey.playerOneColorID: settings.playerOneBatColor.rawValue,
            ConnectivityKey.playerTwoColorID: settings.playerTwoBatColor.rawValue,
            ConnectivityKey.watchMode: settings.watchMode.rawValue,
            ConnectivityKey.watchSwipeEnabled: settings.watchSwipeEnabled,
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
private final class ScoreAnnouncer {
    private let synthesizer = AVSpeechSynthesizer()
    private var isAudioSessionReady = false

    func speak(_ text: String, voiceIdentifier: String = "") {
        prepareAudioSessionIfNeeded()

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        if !voiceIdentifier.isEmpty,
           let voice = AVSpeechSynthesisVoice(identifier: voiceIdentifier) {
            utterance.voice = voice
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: AVSpeechSynthesisVoice.currentLanguageCode())
        }
        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    private func prepareAudioSessionIfNeeded() {
        guard !isAudioSessionReady else {
            return
        }

        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try audioSession.setActive(true)
            isAudioSessionReady = true
        } catch {
            isAudioSessionReady = false
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
    static let gamesToWin = "gamesToWin"
    static let playerOneScore = "playerOneScore"
    static let playerTwoScore = "playerTwoScore"
    static let playerOneName = "playerOneName"
    static let playerTwoName = "playerTwoName"
    static let playerOneColorID = "playerOneColorID"
    static let playerTwoColorID = "playerTwoColorID"
    static let watchMode = "watchMode"
    static let watchSwipeEnabled = "watchSwipeEnabled"
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
