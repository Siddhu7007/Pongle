import Combine
import Foundation
@preconcurrency import WatchConnectivity
import WatchKit

@MainActor
final class WatchScoreStore: NSObject, ObservableObject {
    @Published private(set) var game = GameState()
    @Published private(set) var isPhoneReachable = false
    @Published private(set) var eventText = "Ready"
    @Published private(set) var playerOneName = Player.playerOne.displayName
    @Published private(set) var playerTwoName = Player.playerTwo.displayName
    @Published private(set) var playerOneColorID = "teal"
    @Published private(set) var playerTwoColorID = "orange"

    private var session: WCSession?
    private var pendingTapTask: Task<Void, Never>?
    private var watchSequence = 0
    private var lastAppliedPhoneSequence = 0
    private static let validColorIDs: Set<String> = ["teal", "orange", "blue", "red", "lime", "purple"]

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

    func registerTap() {
        guard game.winner == nil else {
            return
        }

        if pendingTapTask != nil {
            pendingTapTask?.cancel()
            pendingTapTask = nil
            commitPoint(for: .playerTwo)
            return
        }

        pendingTapTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 300_000_000)

            guard !Task.isCancelled else {
                return
            }

            await MainActor.run {
                self?.pendingTapTask = nil
                self?.commitPoint(for: .playerOne)
            }
        }
    }

    func undo() {
        pendingTapTask?.cancel()
        pendingTapTask = nil

        guard game.canUndo else {
            return
        }

        game.undoLastPoint()
        eventText = game.winner.map { "Game - \(displayName(for: $0))" } ?? "Undo"
        watchSequence += 1
        sendScoreEvent(action: .undo, player: nil)
        publishCurrentState()
        WKInterfaceDevice.current().play(.notification)
    }

    func displayName(for player: Player) -> String {
        let candidate: String
        switch player {
        case .playerOne:
            candidate = playerOneName
        case .playerTwo:
            candidate = playerTwoName
        }

        let trimmed = candidate.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return player.displayName
        }
        return String(trimmed.prefix(18))
    }

    func colorID(for player: Player) -> String {
        switch player {
        case .playerOne: playerOneColorID
        case .playerTwo: playerTwoColorID
        }
    }

    private func commitPoint(for player: Player) {
        game.addPoint(for: player)
        eventText = game.winner.map { "Game - \(displayName(for: $0))" } ?? "\(displayName(for: player)) +1"
        watchSequence += 1

        sendScoreEvent(action: .point, player: player)
        publishCurrentState()
        playPointHaptic(for: player)
    }

    private func sendScoreEvent(action: ScoreAction, player: Player?) {
        var payload: [String: Any] = [
            ConnectivityKey.kind: ConnectivityKind.scoreEvent,
            ConnectivityKey.source: ConnectivitySource.watch,
            ConnectivityKey.watchSequence: watchSequence,
            ConnectivityKey.action: action.rawValue
        ]

        if let player {
            payload[ConnectivityKey.player] = player.rawValue
        }

        guard let session else {
            return
        }

        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil) { [weak self] _ in
                Task { @MainActor in
                    self?.isPhoneReachable = false
                }
            }
        } else {
            isPhoneReachable = false
        }
    }

    private func publishCurrentState() {
        let payload: [String: Any] = [
            ConnectivityKey.kind: ConnectivityKind.stateSnapshot,
            ConnectivityKey.source: ConnectivitySource.watch,
            ConnectivityKey.watchSequence: watchSequence,
            ConnectivityKey.playerOneScore: game.playerOneScore,
            ConnectivityKey.playerTwoScore: game.playerTwoScore,
            ConnectivityKey.history: game.history.map(\.rawValue)
        ]

        do {
            try session?.updateApplicationContext(payload)
        } catch {
            eventText = "Sync paused"
        }
    }

    private func applyPhoneSnapshot(from payload: [String: Any]) {
        guard (payload[ConnectivityKey.source] as? String) == ConnectivitySource.phone,
              let phoneSequence = payload[ConnectivityKey.phoneSequence] as? Int,
              phoneSequence > lastAppliedPhoneSequence else {
            return
        }

        lastAppliedPhoneSequence = phoneSequence

        if let rawHistory = payload[ConnectivityKey.history] as? [Int] {
            game.replace(withHistory: rawHistory.compactMap(Player.init(rawValue:)))
        }

        if let name = payload[ConnectivityKey.playerOneName] as? String {
            playerOneName = Self.limitedName(name)
        }

        if let name = payload[ConnectivityKey.playerTwoName] as? String {
            playerTwoName = Self.limitedName(name)
        }

        if let colorID = payload[ConnectivityKey.playerOneColorID] as? String,
           Self.validColorIDs.contains(colorID) {
            playerOneColorID = colorID
        }

        if let colorID = payload[ConnectivityKey.playerTwoColorID] as? String,
           Self.validColorIDs.contains(colorID) {
            playerTwoColorID = colorID
        }

        eventText = game.winner.map { "Game - \(displayName(for: $0))" } ?? "Synced"
    }

    private func handleConnectivityPayload(_ payload: [String: Any]) {
        guard (payload[ConnectivityKey.kind] as? String) == ConnectivityKind.stateSnapshot else {
            return
        }

        applyPhoneSnapshot(from: payload)
    }

    private func playPointHaptic(for player: Player) {
        switch player {
        case .playerOne:
            WKInterfaceDevice.current().play(.success)
        case .playerTwo:
            WKInterfaceDevice.current().play(.directionUp)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.13) {
                WKInterfaceDevice.current().play(.directionUp)
            }
        }
    }

    private static func limitedName(_ name: String) -> String {
        String(name.prefix(18))
    }
}

extension WatchScoreStore: WCSessionDelegate {
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        let isReachable = session.isReachable

        Task { @MainActor [weak self] in
            self?.isPhoneReachable = isReachable
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        let isReachable = session.isReachable

        Task { @MainActor [weak self] in
            self?.isPhoneReachable = isReachable
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Task { @MainActor [weak self] in
            self?.isPhoneReachable = session.isReachable
            self?.handleConnectivityPayload(message)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        Task { @MainActor [weak self] in
            self?.isPhoneReachable = session.isReachable
            self?.handleConnectivityPayload(applicationContext)
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
