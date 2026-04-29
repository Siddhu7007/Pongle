import SwiftUI

struct LandscapeScoreboardView: View {
    @ObservedObject var store: PhoneScoreStore
    let onRequestReset: () -> Void

    /// Display-only flip of the left/right player layout, so the scoreboard
    /// can match the players' physical sides of the table. Does NOT change
    /// scoring, input mapping, serve identity, or any underlying state.
    @State private var isPlayerOrderFlipped = false

    var body: some View {
        GeometryReader { geometry in
            let height = geometry.size.height
            let nameFontSize = clamp(height * 0.07, lo: 22, hi: 44)
            let scoreFontSize = clamp(height * 0.62, lo: 140, hi: 320)

            let leftPlayer: Player = isPlayerOrderFlipped ? .playerTwo : .playerOne
            let rightPlayer: Player = isPlayerOrderFlipped ? .playerOne : .playerTwo
            let awaitingServeChoice = store.game.awaitingFirstServerChoice

            ZStack(alignment: .top) {
                HStack(spacing: 0) {
                    panel(
                        for: leftPlayer,
                        nameFontSize: nameFontSize,
                        scoreFontSize: scoreFontSize,
                        isAwaitingServeChoice: awaitingServeChoice
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    Rectangle()
                        .fill(Color.white.opacity(0.06))
                        .frame(width: 1)
                        .padding(.vertical, 28)

                    panel(
                        for: rightPlayer,
                        nameFontSize: nameFontSize,
                        scoreFontSize: scoreFontSize,
                        isAwaitingServeChoice: awaitingServeChoice
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                VStack {
                    Spacer()
                    PastGamesRow(
                        completedGames: store.game.completedGames,
                        gamesToWin: store.game.gamesToWin,
                        leftPlayer: leftPlayer,
                        rightPlayer: rightPlayer,
                        leftAccent: store.settings.batColor(for: leftPlayer).accentColor,
                        rightAccent: store.settings.batColor(for: rightPlayer).accentColor
                    )
                    .padding(.bottom, 16)
                    .allowsHitTesting(false)
                }

                HStack(spacing: 8) {
                    Spacer()
                    Button {
                        isPlayerOrderFlipped.toggle()
                    } label: {
                        cornerIcon(systemName: "arrow.left.arrow.right")
                    }
                    .accessibilityLabel("Swap player sides")

                    Button(action: onRequestReset) {
                        cornerIcon(systemName: "arrow.counterclockwise")
                    }
                    .disabled(!store.game.hasScore)
                    .opacity(store.game.hasScore ? 1 : 0.35)
                    .accessibilityLabel("Reset match")
                }
                .padding(.top, 12)
                .padding(.trailing, 16)
                .zIndex(2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private func panel(
        for player: Player,
        nameFontSize: CGFloat,
        scoreFontSize: CGFloat,
        isAwaitingServeChoice: Bool
    ) -> some View {
        PlayerPanel(
            name: displayName(for: player),
            score: score(for: player),
            accent: store.settings.batColor(for: player).accentColor,
            isServing: !isAwaitingServeChoice && store.game.currentServer == player,
            isAwaitingServeChoice: isAwaitingServeChoice,
            nameFontSize: nameFontSize,
            scoreFontSize: scoreFontSize,
            onLongPress: store.game.canUndo ? { store.undo() } : nil,
            onTap: {
                if isAwaitingServeChoice {
                    store.setFirstServer(player)
                } else {
                    store.addPoint(to: player)
                }
            }
        )
    }

    private func cornerIcon(systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.white.opacity(0.6))
            .frame(width: 34, height: 34)
            .background(Circle().fill(Color.white.opacity(0.06)))
            .overlay(Circle().stroke(Color.white.opacity(0.10), lineWidth: 1))
    }

    private func displayName(for player: Player) -> String {
        let configured = store.settings.displayName(for: player)
        guard configured == player.displayName else {
            return configured
        }
        return player == .playerOne ? "You" : "Opponent"
    }

    private func score(for player: Player) -> Int {
        switch player {
        case .playerOne: store.game.playerOneScore
        case .playerTwo: store.game.playerTwoScore
        }
    }

    private func clamp(_ value: CGFloat, lo: CGFloat, hi: CGFloat) -> CGFloat {
        min(max(value, lo), hi)
    }
}

private struct PlayerPanel: View {
    let name: String
    let score: Int
    let accent: Color
    let isServing: Bool
    let isAwaitingServeChoice: Bool
    let nameFontSize: CGFloat
    let scoreFontSize: CGFloat
    let onLongPress: (() -> Void)?
    let onTap: () -> Void

    var body: some View {
        panelContent
            .scoreInputGesture(
                tapAction: onTap,
                longPressAction: onLongPress,
                accessibilityHint: accessibilityHint
            )
    }

    private var accessibilityHint: String {
        if isAwaitingServeChoice {
            return onLongPress == nil
                ? "Tap to choose \(name) to serve first"
                : "Tap to choose \(name) to serve first, or touch and hold to undo the last point"
        }

        return onLongPress == nil
            ? "Tap to add one point for \(name)"
            : "Tap to add one point for \(name), or touch and hold to undo the last point"
    }

    private var panelContent: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Text(name)
                    .font(.system(size: nameFontSize, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                if isAwaitingServeChoice {
                    ServeChoicePill(accent: accent)
                } else {
                    ServePill(accent: accent)
                        .opacity(isServing ? 1 : 0)
                }
            }
            .padding(.top, 16)

            Spacer(minLength: 0)

            Text("\(score)")
                .font(.system(size: scoreFontSize, weight: .black, design: .rounded))
                .foregroundColor(accent)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.4)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 56)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct ServePill: View {
    let accent: Color

    var body: some View {
        Text("Serve")
            .font(.system(size: 11, weight: .heavy, design: .rounded))
            .tracking(0.8)
            .textCase(.uppercase)
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(accent))
    }
}

private struct ServeChoicePill: View {
    let accent: Color

    var body: some View {
        Text("Tap to Serve")
            .font(.system(size: 11, weight: .heavy, design: .rounded))
            .tracking(0.8)
            .textCase(.uppercase)
            .foregroundColor(accent.opacity(0.85))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .stroke(
                        accent.opacity(0.55),
                        style: StrokeStyle(lineWidth: 1, dash: [3, 3])
                    )
            )
    }
}

private struct PastGamesRow: View {
    let completedGames: [CompletedGame]
    let gamesToWin: Int
    let leftPlayer: Player
    let rightPlayer: Player
    let leftAccent: Color
    let rightAccent: Color

    private var totalSlots: Int { max(gamesToWin * 2 - 1, 1) }

    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...totalSlots, id: \.self) { n in
                tile(forGameNumber: n)
            }
        }
    }

    @ViewBuilder
    private func tile(forGameNumber n: Int) -> some View {
        if let game = completedGames.first(where: { $0.gameNumber == n }) {
            let accent = game.winner == leftPlayer ? leftAccent : rightAccent
            let leftScore = score(for: leftPlayer, in: game)
            let rightScore = score(for: rightPlayer, in: game)

            HStack(spacing: 6) {
                Text("G\(n)")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
                Text("\(leftScore)–\(rightScore)")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .monospacedDigit()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.06))
            )
            .overlay(
                Capsule()
                    .stroke(accent.opacity(0.6), lineWidth: 1)
            )
        } else {
            Text("G\(n)")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.18))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.10),
                                style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                )
        }
    }

    private func score(for player: Player, in game: CompletedGame) -> Int {
        switch player {
        case .playerOne: game.player1Score
        case .playerTwo: game.player2Score
        }
    }
}
