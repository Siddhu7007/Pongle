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
    private(set) var playerOneScore = 0
    private(set) var playerTwoScore = 0
    private(set) var history: [Player] = []

    let winningScore = 11
    let winBy = 2

    var winner: Player? {
        let highScore = max(playerOneScore, playerTwoScore)
        let scoreDifference = abs(playerOneScore - playerTwoScore)

        guard highScore >= winningScore, scoreDifference >= winBy else {
            return nil
        }

        return playerOneScore > playerTwoScore ? .playerOne : .playerTwo
    }

    var canUndo: Bool {
        !history.isEmpty
    }

    var hasScore: Bool {
        playerOneScore > 0 || playerTwoScore > 0
    }

    mutating func addPoint(for player: Player) {
        guard winner == nil else {
            return
        }

        switch player {
        case .playerOne:
            playerOneScore += 1
        case .playerTwo:
            playerTwoScore += 1
        }

        history.append(player)
    }

    mutating func undoLastPoint() {
        guard let player = history.popLast() else {
            return
        }

        switch player {
        case .playerOne:
            playerOneScore = max(0, playerOneScore - 1)
        case .playerTwo:
            playerTwoScore = max(0, playerTwoScore - 1)
        }
    }

    mutating func reset() {
        playerOneScore = 0
        playerTwoScore = 0
        history.removeAll()
    }

    mutating func replace(withHistory newHistory: [Player]) {
        reset()
        for player in newHistory {
            addPoint(for: player)
        }
    }
}
