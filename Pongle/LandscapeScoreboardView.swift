import SwiftUI

struct LandscapeScoreboardView: View {
    @ObservedObject var store: PhoneScoreStore
    let onRequestReset: () -> Void

    /// Display-only starting-side preference. The live layout also flips after
    /// odd-numbered completed games so it tracks player side changes.
    @State private var isManualPlayerOrderFlipped = false
    @State private var isNameEditorPresented = false

    var body: some View {
        GeometryReader { geometry in
            let height = geometry.size.height
            let nameFontSize = clamp(height * 0.13, lo: 42, hi: 96)
            let scoreFontSize = clamp(height * 0.62, lo: 140, hi: 320)
            let winnerTitleFontSize = clamp(height * 0.18, lo: 58, hi: 128)
            let winnerLabelFontSize = clamp(height * 0.038, lo: 13, hi: 22)
            let usesProminentControls = height >= 520

            let isAutomaticPlayerOrderFlipped = !store.game.completedGames.count.isMultiple(of: 2)
            let isPlayerOrderFlipped = isManualPlayerOrderFlipped != isAutomaticPlayerOrderFlipped
            let leftPlayer: Player = isPlayerOrderFlipped ? .playerTwo : .playerOne
            let rightPlayer: Player = isPlayerOrderFlipped ? .playerOne : .playerTwo
            let awaitingServeChoice = store.game.awaitingFirstServerChoice

            ZStack(alignment: .top) {
                HStack(spacing: 0) {
                    panel(
                        for: leftPlayer,
                        serveIndicatorEdge: .leading,
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
                        serveIndicatorEdge: .trailing,
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

                if awaitingServeChoice {
                    FirstServerChoicePrompt(
                        playerOneName: displayName(for: .playerOne),
                        playerTwoName: displayName(for: .playerTwo),
                        inputMode: firstServerChoiceInputMode,
                        isCompact: false
                    )
                    .padding(.horizontal, 44)
                    .padding(.top, max(height * 0.19, 150))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .allowsHitTesting(false)
                    .zIndex(2.5)
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

                if usesProminentControls {
                    landscapeControls(usesProminentLayout: true)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .padding(.top, 96)
                        .padding(.bottom, 116)
                        .zIndex(2)
                } else {
                    landscapeControls(usesProminentLayout: false)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .padding(.top, 76)
                        .padding(.bottom, 88)
                        .zIndex(2)
                }

                HStack {
                    Spacer()

                    Button {
                        isNameEditorPresented = true
                    } label: {
                        landscapeCornerIcon(systemName: "pencil")
                    }
                    .accessibilityLabel("Edit player names")
                    .padding(.top, 12)
                    .padding(.trailing, 16)
                }
                .zIndex(3)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .sheet(isPresented: $isNameEditorPresented) {
            PlayerNameEditorSheet(settings: store.settings)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color(red: 0.055, green: 0.06, blue: 0.065))
        }
    }

    @ViewBuilder
    private func panel(
        for player: Player,
        serveIndicatorEdge: ServeIndicatorEdge,
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
            serveIndicatorEdge: serveIndicatorEdge,
            onLongPress: store.game.canUndo ? { store.undo() } : nil,
            onTap: store.effectiveTapInputEnabled ? {
                if isAwaitingServeChoice {
                    store.setFirstServer(player)
                } else {
                    store.addPoint(to: player)
                }
            } : nil
        )
    }

    @ViewBuilder
    private func landscapeControls(usesProminentLayout: Bool) -> some View {
        if usesProminentLayout {
            VStack(spacing: 12) {
                controlButtons(usesProminentLayout: true)
            }
            .padding(9)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color.black.opacity(0.42))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.34), radius: 16, x: 0, y: 8)
        } else {
            HStack(spacing: 10) {
                controlButtons(usesProminentLayout: false)
            }
            .padding(8)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.34))
            )
        }
    }

    @ViewBuilder
    private func controlButtons(usesProminentLayout: Bool) -> some View {
        LandscapeControlButton(
            title: "Swap",
            systemName: "arrow.left.arrow.right",
            isEnabled: true,
            usesProminentLayout: usesProminentLayout
        ) {
            isManualPlayerOrderFlipped.toggle()
        }
        .accessibilityLabel("Swap player sides")

        LandscapeControlButton(
            title: "Reset",
            systemName: "arrow.counterclockwise",
            isEnabled: store.game.hasScore,
            usesProminentLayout: usesProminentLayout,
            action: onRequestReset
        )
        .accessibilityLabel("Reset match")
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

    private var firstServerChoiceInputMode: FirstServerChoiceInputMode {
        FirstServerChoiceInputMode.mode(
            tapInputEnabled: store.effectiveTapInputEnabled,
            externalInputAvailable: store.externalInputAvailable,
            dualInputsAssigned: store.hasDualInputsAssigned
        )
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

    private func landscapeCornerIcon(systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(.white.opacity(0.72))
            .frame(width: 38, height: 38)
            .background(Circle().fill(Color.black.opacity(0.28)))
            .overlay(Circle().stroke(Color.white.opacity(0.14), lineWidth: 1))
            .shadow(color: Color.black.opacity(0.24), radius: 8, x: 0, y: 4)
    }
}

struct PlayerNameEditorSheet: View {
    @ObservedObject var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedNameField: PlayerNameEditorFieldFocus?

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("Player Names")
                    .font(.system(.title3, design: .rounded, weight: .heavy))
                    .foregroundStyle(.white)

                Spacer()

                Button("Done") {
                    focusedNameField = nil
                    dismiss()
                }
                .font(.system(.subheadline, design: .rounded, weight: .heavy))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color.white.opacity(0.12)))
            }

            VStack(spacing: 12) {
                nameField(title: "Player 1", player: .playerOne)
                nameField(title: "Player 2", player: .playerTwo)
            }
        }
        .padding(24)
    }

    private func nameField(title: String, player: Player) -> some View {
        let focusID = PlayerNameEditorFieldFocus(player: player)

        return VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.system(.caption, design: .rounded, weight: .heavy))
                .foregroundStyle(.white.opacity(0.62))

            ZStack(alignment: .trailing) {
                TextField(
                    title,
                    text: nameBinding(for: player),
                    prompt: Text(title).foregroundColor(.white.opacity(0.72))
                )
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .foregroundStyle(.white)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .focused($focusedNameField, equals: focusID)
                .onSubmit {
                    focusedNameField = nil
                }
                .accessibilityLabel("\(title) name")
                .padding(.leading, 14)
                .padding(.trailing, 42)
                .padding(.vertical, 12)

                Image(systemName: "pencil")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.trailing, 14)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.white.opacity(0.095))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
            )
            .tint(.pongleAccent)
            .contentShape(Rectangle())
            .simultaneousGesture(
                TapGesture().onEnded {
                    focusedNameField = focusID
                }
            )
        }
    }

    private func nameBinding(for player: Player) -> Binding<String> {
        Binding(
            get: {
                switch player {
                case .playerOne: settings.playerOneName
                case .playerTwo: settings.playerTwoName
                }
            },
            set: { settings.setName($0, for: player) }
        )
    }
}

private enum PlayerNameEditorFieldFocus: Hashable {
    case playerOne
    case playerTwo

    init(player: Player) {
        switch player {
        case .playerOne: self = .playerOne
        case .playerTwo: self = .playerTwo
        }
    }
}

private struct LandscapeControlButton: View {
    let title: String
    let systemName: String
    let isEnabled: Bool
    let usesProminentLayout: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            if usesProminentLayout {
                HStack(spacing: 8) {
                    Image(systemName: systemName)
                        .font(.system(size: 20, weight: .bold))

                    Text(title)
                        .font(.system(size: 17, weight: .heavy, design: .rounded))
                }
                .foregroundColor(.white.opacity(isEnabled ? 0.92 : 0.38))
                .frame(minWidth: 116, minHeight: 56)
                .background(buttonShape.fill(Color.white.opacity(isEnabled ? 0.15 : 0.06)))
                .overlay(buttonShape.stroke(Color.white.opacity(isEnabled ? 0.24 : 0.10), lineWidth: 1))
            } else {
                Image(systemName: systemName)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white.opacity(isEnabled ? 0.86 : 0.36))
                    .frame(width: 54, height: 54)
                    .background(Circle().fill(Color.white.opacity(isEnabled ? 0.14 : 0.06)))
                    .overlay(Circle().stroke(Color.white.opacity(isEnabled ? 0.22 : 0.10), lineWidth: 1))
            }
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .contentShape(Rectangle())
    }

    private var buttonShape: some InsettableShape {
        Capsule()
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
    let serveIndicatorEdge: ServeIndicatorEdge
    let onLongPress: (() -> Void)?
    let onTap: (() -> Void)?

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
            if onTap == nil {
                return onLongPress == nil
                    ? "Use the connected input device to choose the first server"
                    : "Use the connected input device to choose the first server, or touch and hold to undo the last point"
            }

            return onLongPress == nil
                ? "Tap to choose \(name) to serve first"
                : "Tap to choose \(name) to serve first, or touch and hold to undo the last point"
        }

        if onTap == nil {
            return "Touch and hold to undo the last point"
        }

        return onLongPress == nil
            ? "Tap to add one point for \(name)"
            : "Tap to add one point for \(name), or touch and hold to undo the last point"
    }

    private var panelContent: some View {
        VStack(spacing: 10) {
            VStack(spacing: 8) {
                Text(name)
                    .font(.system(size: nameFontSize, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.62)
                    .allowsTightening(true)
                    .truncationMode(.tail)
                    .layoutPriority(1)
                    .frame(maxWidth: .infinity, alignment: .center)

                if isAwaitingServeChoice {
                    Color.clear
                }
            }
            .padding(.top, 16)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)

            Spacer(minLength: 0)

            if let score {
                Text("\(score)")
                    .font(.system(size: scoreFontSize, weight: .black, design: .rounded))
                    .foregroundColor(accent)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 56)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: serveIndicatorEdge.alignment) {
            ServeIndicatorBar(accent: accent, isVisible: isServing)
                .padding(.vertical, 16)
                .padding(.horizontal, 14)
        }
    }
}

private enum ServeIndicatorEdge {
    case leading
    case trailing

    var alignment: Alignment {
        switch self {
        case .leading:
            .leading
        case .trailing:
            .trailing
        }
    }
}

private struct ServeIndicatorBar: View {
    let accent: Color
    let isVisible: Bool

    private var opacity: Double {
        isVisible ? 1 : 0
    }

    var body: some View {
        Capsule()
            .fill(accent)
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.92), lineWidth: 3)
            )
            .shadow(color: accent.opacity(0.95), radius: 16, x: 0, y: 0)
            .shadow(color: Color.white.opacity(0.55), radius: 6, x: 0, y: 0)
            .frame(width: 14)
            .frame(maxHeight: .infinity)
            .opacity(opacity)
            .accessibilityHidden(!isVisible)
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
