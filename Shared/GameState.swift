import Foundation

enum Player: Int, CaseIterable, Codable, Identifiable {
    case playerOne = 1
    case playerTwo = 2

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .playerOne:
            "Player 1"
        case .playerTwo:
            "Player 2"
        }
    }
}

enum ScoreAction: String {
    case point
    case undo
    case reset
}

enum ScoreEvent: Equatable {
    case point(player: Player)
    case undo
    case reset
}

struct CompletedGame: Codable, Equatable, Identifiable {
    var id: Int { gameNumber }

    let gameNumber: Int
    let player1Score: Int
    let player2Score: Int
    let winner: Player
}

enum ScoringMode: String, Codable, CaseIterable, Hashable, Identifiable {
    case eleven

    var id: String { rawValue }

    var shortLabel: String {
        switch self {
        case .eleven:
            "11 points"
        }
    }

    var rules: ScoringRules {
        switch self {
        case .eleven:
            .eleven
        }
    }
}

struct ScoringRules: Codable, Equatable {
    static let pointsToWinRange = 2...99
    static let winningMarginRange = 1...20
    static let serveSwitchIntervalRange = 1...20

    static let eleven = ScoringRules(pointsToWin: 11)

    var pointsToWin: Int
    var winningMargin: Int
    var serveSwitchInterval: Int
    var switchesServeEveryPointFromDeuce: Bool

    init(
        pointsToWin: Int,
        winningMargin: Int = 2,
        serveSwitchInterval: Int = 2,
        switchesServeEveryPointFromDeuce: Bool = true
    ) {
        self.pointsToWin = Self.clamp(pointsToWin, to: Self.pointsToWinRange)
        self.winningMargin = Self.clamp(winningMargin, to: Self.winningMarginRange)
        self.serveSwitchInterval = Self.clamp(serveSwitchInterval, to: Self.serveSwitchIntervalRange)
        self.switchesServeEveryPointFromDeuce = switchesServeEveryPointFromDeuce
    }

    var deuceThreshold: Int {
        max(pointsToWin - 1, 1)
    }

    private static func clamp(_ value: Int, to range: ClosedRange<Int>) -> Int {
        min(max(value, range.lowerBound), range.upperBound)
    }
}

struct GameState: Equatable {
    var winningScore: Int = ScoringRules.eleven.pointsToWin
    var gamesToWin: Int = 2
    var winBy: Int = ScoringRules.eleven.winningMargin
    var serveSwitchInterval: Int = ScoringRules.eleven.serveSwitchInterval
    var switchesServeEveryPointFromDeuce: Bool = ScoringRules.eleven.switchesServeEveryPointFromDeuce

    private(set) var history: [Player] = []

    var playerOneScore: Int { tally.playerOnePoints }
    var playerTwoScore: Int { tally.playerTwoPoints }
    var playerOneGames: Int { tally.playerOneGames }
    var playerTwoGames: Int { tally.playerTwoGames }
    var completedGames: [CompletedGame] { tally.completedGames }

    var gameWinner: Player? { tally.currentGameWinner }
    var matchWinner: Player? { tally.matchWinner }
    var winner: Player? { matchWinner ?? gameWinner }
    var currentServer: Player {
        server(forPlayerOneScore: playerOneScore, playerTwoScore: playerTwoScore)
    }

    var canUndo: Bool {
        !history.isEmpty
    }

    var hasScore: Bool {
        !history.isEmpty
    }

    mutating func configure(rules: ScoringRules, gamesToWin: Int) {
        self.winningScore = rules.pointsToWin
        self.winBy = rules.winningMargin
        self.serveSwitchInterval = rules.serveSwitchInterval
        self.switchesServeEveryPointFromDeuce = rules.switchesServeEveryPointFromDeuce
        self.gamesToWin = gamesToWin
    }

    mutating func addPoint(for player: Player) {
        guard matchWinner == nil else {
            return
        }
        history.append(player)
    }

    mutating func undoLastPoint() {
        _ = history.popLast()
    }

    mutating func reset() {
        history.removeAll()
    }

    mutating func replace(withHistory newHistory: [Player]) {
        history = newHistory
    }

    private struct Tally {
        var playerOnePoints = 0
        var playerTwoPoints = 0
        var playerOneGames = 0
        var playerTwoGames = 0
        var completedGames: [CompletedGame] = []
        var currentGameWinner: Player?
        var matchWinner: Player?
    }

    private var tally: Tally {
        var t = Tally()

        let requiredGamesToWin = max(gamesToWin, 1)

        for player in history {
            if t.matchWinner != nil {
                break
            }

            switch player {
            case .playerOne: t.playerOnePoints += 1
            case .playerTwo: t.playerTwoPoints += 1
            }

            guard let gameWinner = computeGameWinner(
                p1: t.playerOnePoints,
                p2: t.playerTwoPoints
            ) else {
                continue
            }

            t.currentGameWinner = gameWinner
            t.completedGames.append(
                CompletedGame(
                    gameNumber: t.completedGames.count + 1,
                    player1Score: t.playerOnePoints,
                    player2Score: t.playerTwoPoints,
                    winner: gameWinner
                )
            )

            switch gameWinner {
            case .playerOne: t.playerOneGames += 1
            case .playerTwo: t.playerTwoGames += 1
            }

            t.currentGameWinner = nil

            if t.playerOneGames >= requiredGamesToWin {
                t.matchWinner = .playerOne
            } else if t.playerTwoGames >= requiredGamesToWin {
                t.matchWinner = .playerTwo
            }

            if t.matchWinner == nil {
                t.playerOnePoints = 0
                t.playerTwoPoints = 0
            }
        }

        return t
    }

    private func computeGameWinner(p1: Int, p2: Int) -> Player? {
        let high = max(p1, p2)
        let diff = abs(p1 - p2)
        guard high >= winningScore, diff >= winBy else { return nil }
        return p1 > p2 ? .playerOne : .playerTwo
    }

    private func server(forPlayerOneScore p1: Int, playerTwoScore p2: Int) -> Player {
        let totalPoints = p1 + p2
        let interval = max(serveSwitchInterval, 1)
        let deuceStartTotal = ScoringRules(pointsToWin: winningScore).deuceThreshold * 2

        let serveSegment: Int
        if switchesServeEveryPointFromDeuce, p1 >= winningScore - 1, p2 >= winningScore - 1 {
            serveSegment = (deuceStartTotal / interval) + max(totalPoints - deuceStartTotal, 0)
        } else {
            serveSegment = totalPoints / interval
        }

        return serveSegment.isMultiple(of: 2) ? .playerOne : .playerTwo
    }
}
