//
//  ContentView.swift
//  Pongle
//
//  Created by Siddhant Daigavane on 21/04/26.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var store: PhoneScoreStore
    @State private var isShowingResetConfirmation = false
    @State private var isScoreboardCompact = false
    @State private var isScoreboardTransitioning = false
    @State private var isScoreboardContentVisible = true

    private let scoreboardTransition = Animation.easeInOut(duration: 0.26)

    var body: some View {
        ZStack {
            ScoreboardBackground()

            if isScoreboardCompact {
                compactLayout
            } else {
                heroLayout
            }
        }
        .alert("Reset game?", isPresented: $isShowingResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                store.reset()
            }
        } message: {
            Text("The current game score will be cleared.")
        }
    }

    private var heroLayout: some View {
        VStack(spacing: 22) {
            topBar
            scoreboardArea
            bottomActionRail
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 20)
    }

    private var compactLayout: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    topBar
                    scoreboardArea
                        .frame(height: 240)

                    MatchControlsDock(
                        isWatchConnected: store.isWatchReachable,
                        flicInput: store.flicInput,
                        onRulesChanged: { store.reset() }
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 16)
            }

            bottomActionRail
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 20)
                .background(
                    LinearGradient(
                        colors: [Color.black.opacity(0), Color.black.opacity(0.35)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .allowsHitTesting(false)
                )
        }
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Pongle")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                Text(store.statusText)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.white.opacity(0.62))
            }

            Spacer()

            ConnectionPill(isConnected: store.isWatchReachable)
        }
    }

    private var bottomActionRail: some View {
        HStack(spacing: 12) {
            ScoreActionButton(
                title: "Undo",
                systemImage: "arrow.uturn.backward",
                isEnabled: store.game.canUndo,
                action: store.undo
            )

            ScoreActionButton(
                title: store.isAudioEnabled ? "Mute" : "Audio",
                systemImage: store.isAudioEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill",
                isEnabled: true,
                action: store.toggleAudio
            )

            ScoreActionButton(
                title: "Reset",
                systemImage: "restart",
                isEnabled: store.game.hasScore,
                role: .destructive
            ) {
                isShowingResetConfirmation = true
            }
        }
    }

    private var scoreboardArea: some View {
        GeometryReader { proxy in
            let isWide = proxy.size.width > proxy.size.height
            let compactHeight = compactScoreboardHeight(for: proxy.size)

            Group {
                if isScoreboardCompact {
                    ScoreboardPanels(
                        playerOneName: store.settings.displayName(for: .playerOne),
                        playerTwoName: store.settings.displayName(for: .playerTwo),
                        playerOneScore: store.game.playerOneScore,
                        playerTwoScore: store.game.playerTwoScore,
                        playerOneAccent: store.settings.batColor(for: .playerOne).accentColor,
                        playerTwoAccent: store.settings.batColor(for: .playerTwo).accentColor,
                        winner: store.game.winner,
                        usesHorizontalLayout: isWide,
                        isCompact: true,
                        compactHeight: compactHeight,
                        isIphoneTapInputEnabled: store.settings.iphoneTapInputEnabled,
                        onAddPoint: store.addPoint
                    )
                } else {
                    HeroScoreboardScene(
                        availableSize: proxy.size,
                        topPlayerName: heroDisplayName(for: .playerTwo),
                        topPlayerScore: store.game.playerTwoScore,
                        topPlayerAccent: store.settings.batColor(for: .playerTwo).accentColor,
                        topPlayerBatImageName: store.settings.batColor(for: .playerTwo).imageName,
                        bottomPlayerName: heroDisplayName(for: .playerOne),
                        bottomPlayerScore: store.game.playerOneScore,
                        bottomPlayerAccent: store.settings.batColor(for: .playerOne).accentColor,
                        bottomPlayerBatImageName: store.settings.batColor(for: .playerOne).imageName,
                        winner: store.game.winner,
                        isIphoneTapInputEnabled: store.settings.iphoneTapInputEnabled,
                        onAddPoint: store.addPoint
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .opacity(isScoreboardContentVisible ? 1 : 0)
            .scaleEffect(isScoreboardContentVisible ? 1 : 0.985, anchor: .top)
            .overlay(alignment: .topTrailing) {
                ScoreboardModeButton(
                    isCompact: isScoreboardCompact,
                    isTransitioning: isScoreboardTransitioning,
                    action: toggleScoreboardMode
                )
                .padding(.top, isScoreboardCompact ? 8 : 8)
                .padding(.trailing, isScoreboardCompact ? 8 : 6)
                .zIndex(20)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func compactScoreboardHeight(for size: CGSize) -> CGFloat {
        if size.width > size.height {
            return min(max(size.height * 0.62, 168), 260)
        }

        return min(max(size.width * 0.58, 224), 308)
    }

    private func heroDisplayName(for player: Player) -> String {
        let configuredName = store.settings.displayName(for: player)
        guard configuredName == player.displayName else {
            return configuredName
        }

        return player == .playerOne ? "You" : "Opponent"
    }

    private func toggleScoreboardMode() {
        guard !isScoreboardTransitioning else {
            return
        }

        isScoreboardTransitioning = true

        withAnimation(.easeOut(duration: 0.1)) {
            isScoreboardContentVisible = false
        }

        Task {
            try? await Task.sleep(nanoseconds: 110_000_000)

            await MainActor.run {
                isScoreboardCompact.toggle()

                withAnimation(scoreboardTransition) {
                    isScoreboardContentVisible = true
                }
            }

            try? await Task.sleep(nanoseconds: 300_000_000)
            await MainActor.run {
                isScoreboardTransitioning = false
            }
        }
    }
}

private struct ScoreboardBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.03, green: 0.04, blue: 0.05),
                Color(red: 0.07, green: 0.08, blue: 0.09)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

private struct HeroScoreboardScene: View {
    let availableSize: CGSize
    let topPlayerName: String
    let topPlayerScore: Int
    let topPlayerAccent: Color
    let topPlayerBatImageName: String
    let bottomPlayerName: String
    let bottomPlayerScore: Int
    let bottomPlayerAccent: Color
    let bottomPlayerBatImageName: String
    let winner: Player?
    let isIphoneTapInputEnabled: Bool
    let onAddPoint: (Player) -> Void

    var body: some View {
        let tableAspectRatio = 577.0 / 433.0
        let labelFontSize = min(max(availableSize.width * 0.04, 19), 27)
        let scoreFont = min(max(availableSize.width * 0.158, 102), 148)
        let badgeSide = min(max(scoreFont * 0.98, 96), 136)
        let scoreColumnWidth = min(max(availableSize.width * 0.19, 114), 156)
        let clusterWidth = min(max(badgeSide + scoreColumnWidth + 44, 296), 472)
        let railWidth = min(max(availableSize.width * 0.8, 272), 700)
        let tableFootprintWidth = min(max(availableSize.width * 0.9, 356), 640)
        let baseTableVisualWidth = min(max(tableFootprintWidth + 92, availableSize.width * 1.17), 800)
        let currentTableVisualWidth = min(baseTableVisualWidth * 1.25, 1120)
        let tableVisualWidth = min(currentTableVisualWidth * 1.368, 1512)
        let tableImageHeight = tableVisualWidth / tableAspectRatio
        let currentTableImageHeight = currentTableVisualWidth / tableAspectRatio
        // Table PNG has ~10% transparent padding at the top and ~17% at the bottom. Lift
        // the image so the visible top sits just below the opponent rail while the lower
        // rail only clips the feet. Both rails are drawn above the table.
        let tableBeamGap = min(max(availableSize.height * 0.014, 16), 22)
        let tableFootOverlap = min(max(tableImageHeight * 0.11, 56), 104)
        let tableTopLift = max(tableImageHeight * 0.10 - tableBeamGap, 0)
        // Make the table larger while shifting only the table down slightly; the beams
        // and player panels stay anchored because only the image offset changes here.
        let tableDrop = currentTableImageHeight * 0.07
        let tableContainerHeight = max(tableImageHeight * 0.73 - tableFootOverlap, 0)
        let horizontalPadding = min(max(availableSize.width * 0.006, 0), 6)
        let playerSpacing = min(max(availableSize.height * 0.004, 2), 6)
        let bottomRailLift = min(max(availableSize.height * 0.03, 18), 28)
        let bottomClusterPullUp = min(max(availableSize.height * 0.022, 12), 20)

        VStack(spacing: 0) {
            HeroPlayerCluster(
                playerName: topPlayerName,
                score: topPlayerScore,
                accent: topPlayerAccent,
                batImageName: topPlayerBatImageName,
                isWinner: winner == .playerTwo,
                badgeSide: badgeSide,
                labelFontSize: labelFontSize,
                scoreFont: scoreFont,
                scoreColumnWidth: scoreColumnWidth,
                clusterWidth: clusterWidth,
                isTapInputEnabled: isIphoneTapInputEnabled
            ) {
                onAddPoint(.playerTwo)
            }
            .padding(.bottom, playerSpacing)

            HeroAccentRail(accent: topPlayerAccent, emphasis: winner == .playerTwo, width: railWidth)
                .zIndex(2)

            Color.clear
                .frame(height: tableContainerHeight)
                .overlay(alignment: .top) {
                    Image("Table")
                        .resizable()
                        .scaledToFit()
                        .frame(width: tableVisualWidth)
                        .shadow(color: .black.opacity(0.42), radius: 12, x: 0, y: 6)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .offset(y: tableDrop - tableTopLift)
                }
                .zIndex(1)

            HeroAccentRail(accent: bottomPlayerAccent, emphasis: winner == .playerOne, width: railWidth)
                .padding(.top, -bottomRailLift)
                .padding(.bottom, playerSpacing)
                .zIndex(2)

            HeroPlayerCluster(
                playerName: bottomPlayerName,
                score: bottomPlayerScore,
                accent: bottomPlayerAccent,
                batImageName: bottomPlayerBatImageName,
                isWinner: winner == .playerOne,
                badgeSide: badgeSide,
                labelFontSize: labelFontSize,
                scoreFont: scoreFont,
                scoreColumnWidth: scoreColumnWidth,
                clusterWidth: clusterWidth,
                isTapInputEnabled: isIphoneTapInputEnabled
            ) {
                onAddPoint(.playerOne)
            }
            .padding(.top, -bottomClusterPullUp)
        }
        .padding(.horizontal, horizontalPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

private struct HeroPlayerCluster: View {
    let playerName: String
    let score: Int
    let accent: Color
    let batImageName: String
    let isWinner: Bool
    let badgeSide: CGFloat
    let labelFontSize: CGFloat
    let scoreFont: CGFloat
    let scoreColumnWidth: CGFloat
    let clusterWidth: CGFloat
    let isTapInputEnabled: Bool
    let action: () -> Void

    @ViewBuilder
    var body: some View {
        if isTapInputEnabled {
            Button(action: action) {
                clusterBody
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
            .accessibilityHint("Adds one point for \(playerName)")
        } else {
            clusterBody
        }
    }

    private var clusterBody: some View {
        HStack(alignment: .center, spacing: max(14, badgeSide * 0.11)) {
            PlayerBatBadge(imageName: batImageName, accent: accent)
                .frame(width: badgeSide, height: badgeSide)

            VStack(alignment: .leading, spacing: 2) {
                Text(playerName)
                    .font(.system(size: labelFontSize, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(isWinner ? 0.82 : 0.68))
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)

                HeroScoreText(score: score, accent: accent, fontSize: scoreFont, isWinner: isWinner)
                    .frame(width: scoreColumnWidth, alignment: .leading)
            }

        }
        .frame(maxWidth: clusterWidth, minHeight: badgeSide, alignment: .leading)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 1)
        .accessibilityLabel("\(playerName), score \(min(score, 99))")
    }
}

private struct PlayerBatBadge: View {
    let imageName: String
    let accent: Color

    var body: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(Color.white.opacity(0.035))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.24), radius: 10, x: 0, y: 6)
            .overlay {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .padding(9)
            }
    }

    private var borderColor: Color {
        Color.white.opacity(0.14)
    }
}

private struct HeroScoreText: View {
    let score: Int
    let accent: Color
    let fontSize: CGFloat
    let isWinner: Bool

    var body: some View {
        Text("\(min(score, 99))")
            .font(.system(size: fontSize, weight: .bold, design: .rounded))
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .tracking(score >= 10 ? -3 : -1)
            .foregroundStyle(
                LinearGradient(
                    colors: [.white, Color.white.opacity(0.82)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .shadow(color: .black.opacity(0.22), radius: 1, x: 0, y: 1)
            .shadow(color: accent.opacity(isWinner ? 0.1 : 0.04), radius: isWinner ? 6 : 3, x: 0, y: 0)
    }
}

private struct HeroAccentRail: View {
    let accent: Color
    let emphasis: Bool
    let width: CGFloat

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.white.opacity(0.05))
                .frame(width: width, height: 1.1)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            accent.opacity(0),
                            accent.opacity(emphasis ? 0.1 : 0.08),
                            accent.opacity(emphasis ? 0.24 : 0.19),
                            accent.opacity(emphasis ? 0.1 : 0.08),
                            accent.opacity(0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: width, height: 22)
                .blur(radius: emphasis ? 28 : 24)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            accent.opacity(0),
                            accent.opacity(emphasis ? 0.26 : 0.2),
                            accent.opacity(emphasis ? 0.58 : 0.48),
                            accent.opacity(emphasis ? 0.26 : 0.2),
                            accent.opacity(0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: width * 0.9, height: 7)
                .blur(radius: emphasis ? 8 : 7)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            accent.opacity(0),
                            accent.opacity(emphasis ? 0.68 : 0.58),
                            accent.opacity(emphasis ? 1 : 0.94),
                            accent.opacity(emphasis ? 0.68 : 0.58),
                            accent.opacity(0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: width * 0.74, height: 1.6)
                .shadow(color: accent.opacity(emphasis ? 0.42 : 0.34), radius: emphasis ? 12 : 9, x: 0, y: 0)
        }
        .compositingGroup()
        .frame(height: 18)
    }
}

private struct ScoreboardPanels: View {
    let playerOneName: String
    let playerTwoName: String
    let playerOneScore: Int
    let playerTwoScore: Int
    let playerOneAccent: Color
    let playerTwoAccent: Color
    let winner: Player?
    let usesHorizontalLayout: Bool
    let isCompact: Bool
    let compactHeight: CGFloat
    let isIphoneTapInputEnabled: Bool
    let onAddPoint: (Player) -> Void

    var body: some View {
        VStack(spacing: isCompact ? 8 : 10) {
            Group {
                if isCompact {
                    panelLayout(usesHorizontalLayout: true, isCompact: true)
                        .frame(height: compactHeight)
                } else {
                    panelLayout(usesHorizontalLayout: usesHorizontalLayout, isCompact: false)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func panelLayout(usesHorizontalLayout: Bool, isCompact: Bool) -> some View {
        let layout = usesHorizontalLayout
            ? AnyLayout(HStackLayout(alignment: .center, spacing: isCompact ? 14 : 16))
            : AnyLayout(VStackLayout(alignment: .center, spacing: 16))

        return layout {
            playerScorePanel(
                player: .playerOne,
                playerName: playerOneName,
                score: playerOneScore,
                accent: playerOneAccent,
                isWinner: winner == .playerOne,
                isCompact: isCompact
            )

            playerScorePanel(
                player: .playerTwo,
                playerName: playerTwoName,
                score: playerTwoScore,
                accent: playerTwoAccent,
                isWinner: winner == .playerTwo,
                isCompact: isCompact
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    @ViewBuilder
    private func playerScorePanel(
        player: Player,
        playerName: String,
        score: Int,
        accent: Color,
        isWinner: Bool,
        isCompact: Bool
    ) -> some View {
        let panel = PlayerScorePanel(
            playerName: playerName,
            score: score,
            accent: accent,
            isWinner: isWinner,
            isCompact: isCompact,
            isTapInputEnabled: isIphoneTapInputEnabled
        )

        if isIphoneTapInputEnabled {
            Button {
                onAddPoint(player)
            } label: {
                panel
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
            .accessibilityHint("Adds one point for \(playerName)")
        } else {
            panel
        }
    }
}

private struct PlayerScorePanel: View {
    let playerName: String
    let score: Int
    let accent: Color
    let isWinner: Bool
    let isCompact: Bool
    let isTapInputEnabled: Bool

    private var scoreText: String {
        String(format: "%02d", min(score, 99))
    }

    var body: some View {
        VStack(spacing: isCompact ? 10 : 18) {
            HStack(spacing: isCompact ? 8 : 12) {
                Text(playerName)
                    .font(.system(isCompact ? .subheadline : .title3, design: .rounded, weight: .bold))
                    .foregroundStyle(.white.opacity(0.72))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Spacer()

                if isWinner {
                    Label("Game", systemImage: "flag.checkered")
                        .font(.system(isCompact ? .caption : .subheadline, design: .rounded, weight: .bold))
                        .foregroundStyle(accent)
                        .labelStyle(.titleAndIcon)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }

            SplitFlapScorePanel(value: scoreText, isCompact: isCompact)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(isCompact ? 12 : 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(red: 0.075, green: 0.08, blue: 0.09))
        )
        .overlay(alignment: .top) {
            Rectangle()
                .fill(accent)
                .frame(height: isCompact ? 4 : 6)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(borderColor, lineWidth: borderWidth)
        }
        .shadow(color: accent.opacity(isWinner ? 0.2 : 0.06), radius: isWinner ? 16 : 8, x: 0, y: 0)
    }

    private var borderColor: Color {
        if isWinner {
            return accent
        }

        if isTapInputEnabled {
            return accent.opacity(0.42)
        }

        return Color.white.opacity(0.1)
    }

    private var borderWidth: CGFloat {
        isWinner || isTapInputEnabled ? 2 : 1
    }
}

private struct ScoreboardModeButton: View {
    let isCompact: Bool
    let isTransitioning: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.28))

                Circle()
                    .fill(Color.white.opacity(0.075))
                    .frame(width: isCompact ? 30 : 34, height: isCompact ? 30 : 34)

                Image(systemName: isCompact ? "arrow.up.left.and.arrow.down.right" : "arrow.down.right.and.arrow.up.left")
                    .font(.system(size: isCompact ? 11 : 13, weight: .bold))
                    .foregroundStyle(.white.opacity(0.72))
            }
            .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
        .opacity(isTransitioning ? 0.72 : 1)
        .disabled(isTransitioning)
        .overlay {
            Circle()
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                .frame(width: isCompact ? 30 : 34, height: isCompact ? 30 : 34)
        }
        .contentShape(Rectangle())
        .accessibilityLabel(isCompact ? "Expand scoreboard" : "Minimize scoreboard")
    }
}

private struct SplitFlapScorePanel: View {
    let value: String
    let isCompact: Bool

    var body: some View {
        HStack(spacing: isCompact ? 5 : 9) {
            ForEach(Array(value.enumerated()), id: \.offset) { _, digit in
                SplitFlapDigit(value: String(digit), isCompact: isCompact)
            }
        }
        .padding(isCompact ? 6 : 10)
        .background(Color(red: 0.055, green: 0.058, blue: 0.066))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.white.opacity(0.075), lineWidth: 1)
        }
    }
}

private struct SplitFlapDigit: View {
    let value: String
    let isCompact: Bool

    @State private var currentValue: String
    @State private var previousValue: String
    @State private var nextValue: String
    @State private var isFlipping = false
    @State private var showBottomFlip = false
    @State private var topRotation = 0.0
    @State private var bottomRotation = 90.0
    @State private var flipTask: Task<Void, Never>?

    init(value: String, isCompact: Bool) {
        self.value = value
        self.isCompact = isCompact
        _currentValue = State(initialValue: value)
        _previousValue = State(initialValue: value)
        _nextValue = State(initialValue: value)
    }

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let halfHeight = max(size.height / 2, 1)

            ZStack {
                VStack(spacing: 0) {
                    FlipDigitHalf(
                        text: isFlipping ? nextValue : currentValue,
                        half: .top,
                        fullSize: size,
                        isCompact: isCompact
                    )
                    .frame(height: halfHeight)

                    FlipDigitHalf(
                        text: isFlipping ? previousValue : currentValue,
                        half: .bottom,
                        fullSize: size,
                        isCompact: isCompact
                    )
                    .frame(height: halfHeight)
                }

                if isFlipping {
                    VStack(spacing: 0) {
                        FlipDigitHalf(
                            text: previousValue,
                            half: .top,
                            fullSize: size,
                            isCompact: isCompact
                        )
                        .frame(height: halfHeight)
                        .rotation3DEffect(
                            .degrees(topRotation),
                            axis: (x: 1, y: 0, z: 0),
                            anchor: .bottom,
                            perspective: 0.72
                        )
                        .shadow(color: .black.opacity(0.58), radius: 5, x: 0, y: 6)
                        .opacity(showBottomFlip ? 0 : 1)
                        .zIndex(2)

                        Spacer(minLength: 0)
                    }

                    VStack(spacing: 0) {
                        Spacer(minLength: 0)

                        FlipDigitHalf(
                            text: nextValue,
                            half: .bottom,
                            fullSize: size,
                            isCompact: isCompact
                        )
                        .frame(height: halfHeight)
                        .rotation3DEffect(
                            .degrees(bottomRotation),
                            axis: (x: 1, y: 0, z: 0),
                            anchor: .top,
                            perspective: 0.72
                        )
                        .shadow(color: .black.opacity(0.45), radius: 5, x: 0, y: -5)
                        .opacity(showBottomFlip ? 1 : 0)
                        .zIndex(3)
                    }
                }

                HingeLine()
            }
            .background(Color(red: 0.08, green: 0.08, blue: 0.09))
            .clipShape(RoundedRectangle(cornerRadius: isCompact ? 7 : 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: isCompact ? 7 : 10, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            }
        }
        .onChange(of: value) { _, newValue in
            startFlip(to: newValue)
        }
        .onDisappear {
            flipTask?.cancel()
        }
    }

    private func startFlip(to newValue: String) {
        guard newValue != currentValue || isFlipping else {
            return
        }

        flipTask?.cancel()

        let startValue = isFlipping ? nextValue : currentValue
        previousValue = startValue
        nextValue = newValue
        currentValue = startValue
        topRotation = 0
        bottomRotation = 90
        showBottomFlip = false
        isFlipping = true

        withAnimation(.easeIn(duration: 0.22)) {
            topRotation = -90
        }

        flipTask = Task {
            try? await Task.sleep(nanoseconds: 220_000_000)

            guard !Task.isCancelled else {
                return
            }

            await MainActor.run {
                bottomRotation = 90
                showBottomFlip = true

                withAnimation(.easeOut(duration: 0.24)) {
                    bottomRotation = 0
                }
            }

            try? await Task.sleep(nanoseconds: 240_000_000)

            guard !Task.isCancelled else {
                return
            }

            await MainActor.run {
                currentValue = newValue
                previousValue = newValue
                nextValue = newValue
                isFlipping = false
                showBottomFlip = false
                topRotation = 0
                bottomRotation = 90
                flipTask = nil
            }
        }
    }
}

private enum FlipScoreHalfPosition {
    case top
    case bottom
}

private struct FlipDigitHalf: View {
    let text: String
    let half: FlipScoreHalfPosition
    let fullSize: CGSize
    let isCompact: Bool

    var body: some View {
        ZStack {
            Color(red: 0.08, green: 0.08, blue: 0.09)

            Rectangle()
                .fill(halfGradient)

            Text(text)
                .font(.system(size: fontSize, weight: .black, design: .rounded))
                .monospacedDigit()
                .minimumScaleFactor(0.42)
                .lineLimit(1)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, Color.white.opacity(0.68)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .black.opacity(0.6), radius: 1, x: 0, y: 1)
                .frame(width: fullSize.width, height: fullSize.height)
                .offset(y: half == .top ? fullSize.height / 4 : -fullSize.height / 4)
        }
        .clipped()
    }

    private var fontSize: CGFloat {
        min(fullSize.height * (isCompact ? 0.7 : 0.73), fullSize.width * 1.46)
    }

    private var halfGradient: LinearGradient {
        switch half {
        case .top:
            LinearGradient(
                colors: [
                    Color.white.opacity(0.09),
                    Color.white.opacity(0.025)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        case .bottom:
            LinearGradient(
                colors: [
                    Color.black.opacity(0.12),
                    Color.black.opacity(0.31)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

private struct HingeLine: View {
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.black.opacity(0.85))
                .frame(height: 2)

            HStack {
                Circle()
                    .fill(Color.black.opacity(0.82))
                    .frame(width: 5, height: 5)
                Spacer()
                Circle()
                    .fill(Color.black.opacity(0.82))
                    .frame(width: 5, height: 5)
            }
            .padding(.horizontal, 8)
        }
    }
}

private struct ConnectionPill: View {
    let isConnected: Bool

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: isConnected ? "applewatch.radiowaves.left.and.right" : "applewatch")
                .font(.system(size: 13, weight: .semibold))
            Text(isConnected ? "Watch Connected" : "Watch Idle")
                .font(.system(.footnote, design: .rounded, weight: .semibold))
        }
        .foregroundStyle(isConnected ? Color.pongleAccent : Color.white.opacity(0.66))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.08))
        )
        .overlay {
            Capsule()
                .stroke(isConnected ? Color.pongleAccent.opacity(0.55) : Color.white.opacity(0.12), lineWidth: 1)
        }
    }
}

private struct ScoreActionButton: View {
    let title: String
    let systemImage: String
    let isEnabled: Bool
    var role: ButtonRole?
    let action: () -> Void

    var body: some View {
        Button(role: role, action: action) {
            Label(title, systemImage: systemImage)
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
        .foregroundStyle(foregroundColor)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.white.opacity(isEnabled ? 0.1 : 0.045))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.white.opacity(isEnabled ? 0.12 : 0.06), lineWidth: 1)
        }
        .disabled(!isEnabled)
    }

    private var foregroundColor: Color {
        guard isEnabled else { return .white.opacity(0.34) }
        return role == .destructive ? .red.opacity(0.9) : .white
    }
}

#Preview {
    let settings = AppSettings()
    return ContentView(store: PhoneScoreStore(settings: settings, activatesConnectivity: false))
        .environmentObject(settings)
}
