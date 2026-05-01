import SwiftUI

struct LandscapeScoreboardView: View {
    @ObservedObject var store: PhoneScoreStore
    let onRequestReset: () -> Void

    /// Display-only starting-side preference. The live layout also flips after
    /// odd-numbered completed games so it tracks player side changes.
    @State private var isManualPlayerOrderFlipped = false

    var body: some View {
        GeometryReader { geometry in
            let height = geometry.size.height
            let nameFontSize = clamp(height * 0.13, lo: 42, hi: 96)
            let scoreFontSize = clamp(height * 0.62, lo: 140, hi: 320)
            let winnerTitleFontSize = clamp(height * 0.18, lo: 58, hi: 128)
            let winnerLabelFontSize = clamp(height * 0.038, lo: 13, hi: 22)

            let isAutomaticPlayerOrderFlipped = !store.game.completedGames.count.isMultiple(of: 2)
            let isPlayerOrderFlipped = isManualPlayerOrderFlipped != isAutomaticPlayerOrderFlipped
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

                if let matchWinner = store.game.matchWinner {
                    MatchWinnerBanner(
                        title: winnerTitle(for: matchWinner),
                        accent: store.settings.batColor(for: matchWinner).accentColor,
                        titleFontSize: winnerTitleFontSize,
                        labelFontSize: winnerLabelFontSize
                    )
                    .padding(.horizontal, 80)
                    .padding(.bottom, 56)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .allowsHitTesting(false)
                    .zIndex(1)
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
                        isManualPlayerOrderFlipped.toggle()
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
            score: currentScore(for: player),
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

    private func winnerTitle(for player: Player) -> String {
        let name = displayName(for: player)
        return name == "You" ? "You Win" : "\(name) Wins"
    }

    private func currentScore(for player: Player) -> Int? {
        guard store.game.matchWinner == nil else {
            return nil
        }

        switch player {
        case .playerOne:
            return store.game.playerOneScore
        case .playerTwo:
            return store.game.playerTwoScore
        }
    }

    private func clamp(_ value: CGFloat, lo: CGFloat, hi: CGFloat) -> CGFloat {
        min(max(value, lo), hi)
    }
}

private struct MatchWinnerBanner: View {
    let title: String
    let accent: Color
    let titleFontSize: CGFloat
    let labelFontSize: CGFloat

    var body: some View {
        VStack(spacing: 14) {
            Text("MATCH COMPLETE")
                .font(.system(size: labelFontSize, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.55))
                .lineLimit(1)

            Text(title)
                .font(.system(size: titleFontSize, weight: .black, design: .rounded))
                .foregroundColor(accent)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity)
                .shadow(color: .black.opacity(0.55), radius: 3, x: 0, y: 2)
                .shadow(color: accent.opacity(0.85), radius: 18, x: 0, y: 0)
                .shadow(color: accent.opacity(0.38), radius: 38, x: 0, y: 0)

            Capsule()
                .fill(accent)
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.72), lineWidth: 2)
                )
                .shadow(color: accent.opacity(0.82), radius: 14, x: 0, y: 0)
                .frame(width: min(max(titleFontSize * 2.15, 220), 460), height: min(max(titleFontSize * 0.08, 9), 15))
        }
        .multilineTextAlignment(.center)
    }
}

private struct PlayerPanel: View {
    let name: String
    let score: Int?
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
                    .font(.system(size: nameFontSize, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .layoutPriority(1)
                    .frame(maxWidth: .infinity, alignment: .center)

                if isAwaitingServeChoice {
                    ServeChoicePill(accent: accent)
                }
            }
            .padding(.top, 16)
            .frame(maxWidth: .infinity)

            Spacer(minLength: 0)

            if let score {
                Text("\(score)")
                    .font(.system(size: scoreFontSize, weight: .black, design: .rounded))
                    .foregroundColor(accent)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)

                ServeIndicatorBar(accent: accent, scoreFontSize: scoreFontSize, isVisible: isServing)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 56)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct ServeIndicatorBar: View {
    let accent: Color
    let scoreFontSize: CGFloat
    let isVisible: Bool

    private var opacity: Double {
        isVisible ? 1 : 0
    }

    var body: some View {
        let width = min(max(scoreFontSize * 1.08, 220), 380)
        let height = min(max(scoreFontSize * 0.07, 18), 30)

        Capsule()
            .fill(accent)
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.92), lineWidth: 3)
            )
            .shadow(color: accent.opacity(0.95), radius: 16, x: 0, y: 0)
            .shadow(color: Color.white.opacity(0.55), radius: 6, x: 0, y: 0)
            .frame(width: width, height: height)
            .opacity(opacity)
            .accessibilityHidden(!isVisible)
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
