import Foundation

enum Player: Int, CaseIterable, Identifiable {
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

struct GameState: Equatable {
    var winningScore: Int = 11
    var gamesToWin: Int = 2
    let winBy = 2

    private(set) var history: [Player] = []

    var playerOneScore: Int { tally.playerOnePoints }
    var playerTwoScore: Int { tally.playerTwoPoints }
    var playerOneGames: Int { tally.playerOneGames }
    var playerTwoGames: Int { tally.playerTwoGames }

    /// Winner of the current in-progress game, if its points reached the threshold.
    /// When a game closes in a multi-game match, its points are rolled into the games tally
    /// and this becomes nil again until the next game ends.
    var gameWinner: Player? { tally.currentGameWinner }

    /// Winner of the whole match (first to `gamesToWin`), or nil if match still in progress.
    var matchWinner: Player? { tally.matchWinner }

    /// Combined "is something won right now?" — matches previous `winner` API so the UI can highlight.
    var winner: Player? { matchWinner ?? gameWinner }

    var canUndo: Bool {
        !history.isEmpty
    }

    var hasScore: Bool {
        !history.isEmpty
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

    // MARK: - Tally (replayed from history)

    private struct Tally {
        var playerOnePoints = 0
        var playerTwoPoints = 0
        var playerOneGames = 0
        var playerTwoGames = 0
        var currentGameWinner: Player?
        var matchWinner: Player?
    }

    private var tally: Tally {
        var t = Tally()

        for player in history {
            if t.matchWinner != nil {
                break
            }

            // If the previous point closed a game in a multi-game match, roll it now
            // so this new point starts the next game from 0–0.
            if t.currentGameWinner != nil && gamesToWin > 1 {
                switch t.currentGameWinner! {
                case .playerOne: t.playerOneGames += 1
                case .playerTwo: t.playerTwoGames += 1
                }
                t.playerOnePoints = 0
                t.playerTwoPoints = 0
                t.currentGameWinner = nil

                if t.playerOneGames >= gamesToWin {
                    t.matchWinner = .playerOne
                    break
                }
                if t.playerTwoGames >= gamesToWin {
                    t.matchWinner = .playerTwo
                    break
                }
            }

            switch player {
            case .playerOne: t.playerOnePoints += 1
            case .playerTwo: t.playerTwoPoints += 1
            }

            t.currentGameWinner = computeGameWinner(
                p1: t.playerOnePoints,
                p2: t.playerTwoPoints
            )
        }

        // Final match-close check (covers the single-game case and the final game of a match).
        if let gw = t.currentGameWinner, t.matchWinner == nil {
            if gamesToWin <= 1 {
                t.matchWinner = gw
            } else {
                let projectedOne = t.playerOneGames + (gw == .playerOne ? 1 : 0)
                let projectedTwo = t.playerTwoGames + (gw == .playerTwo ? 1 : 0)
                if projectedOne >= gamesToWin {
                    t.matchWinner = .playerOne
                } else if projectedTwo >= gamesToWin {
                    t.matchWinner = .playerTwo
                }
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
}
