@preconcurrency import AVFoundation
import Combine
import Foundation
@preconcurrency import WatchConnectivity

@MainActor
final class PhoneScoreStore: NSObject, ObservableObject {
    @Published private(set) var game = GameState()
    @Published private(set) var isWatchReachable = false
    @Published private(set) var lastConnectivityError: String?
    @Published var isAudioEnabled = true

    private let announcer = ScoreAnnouncer()
    private var session: WCSession?
    private var lastAppliedWatchSequence = 0
    private var phoneSequence = 0

    init(activatesConnectivity: Bool = true) {
        super.init()

        guard activatesConnectivity, WCSession.isSupported() else {
            return
        }

        let session = WCSession.default
        self.session = session
        session.delegate = self
        session.activate()
    }

    var statusText: String {
        if let lastConnectivityError {
            return lastConnectivityError
        }

        return game.winner.map { "Game - \($0.displayName)" } ?? "First to 11, win by 2"
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
        isAudioEnabled.toggle()

        if !isAudioEnabled {
            announcer.stop()
        }
    }

    private func applyRemoteScoreEvent(from message: [String: Any]) {
        guard let watchSequence = message[ConnectivityKey.watchSequence] as? Int,
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
            game.addPoint(for: player)
            announceCurrentScore()

        case .undo:
            game.undoLastPoint()
            announceCurrentScore()

        case .reset:
            game.reset()
            announcer.stop()
        }
    }

    private func applyRemoteSnapshot(from message: [String: Any]) {
        guard (message[ConnectivityKey.source] as? String) == ConnectivitySource.watch,
              let watchSequence = message[ConnectivityKey.watchSequence] as? Int,
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
        guard isAudioEnabled else {
            return
        }

        if let winner = game.winner {
            announcer.speak("Game, \(winner.displayName)")
        } else {
            announcer.speak("\(game.playerOneScore) \(game.playerTwoScore)")
        }
    }

    private func broadcastCurrentStateToWatch() {
        phoneSequence += 1

        let payload: [String: Any] = [
            ConnectivityKey.kind: ConnectivityKind.stateSnapshot,
            ConnectivityKey.source: ConnectivitySource.phone,
            ConnectivityKey.phoneSequence: phoneSequence,
            ConnectivityKey.playerOneScore: game.playerOneScore,
            ConnectivityKey.playerTwoScore: game.playerTwoScore,
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

    func speak(_ text: String) {
        prepareAudioSessionIfNeeded()

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        utterance.voice = AVSpeechSynthesisVoice(language: AVSpeechSynthesisVoice.currentLanguageCode())
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
    static let playerOneScore = "playerOneScore"
    static let playerTwoScore = "playerTwoScore"
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
