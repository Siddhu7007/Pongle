//
//  ContentView.swift
//  Pongle
//
//  Created by Siddhant Daigavane on 21/04/26.
//

import SwiftUI
import UIKit

struct ContentView: View {
    @ObservedObject var store: PhoneScoreStore
    @State private var isShowingResetConfirmation = false
    @State private var isScoreboardCompact = false
    @State private var isScoreboardTransitioning = false
    @State private var isScoreboardContentVisible = true

    private let scoreboardTransition = Animation.easeInOut(duration: 0.26)

    var body: some View {
        GeometryReader { proxy in
            let isLandscape = proxy.size.width > proxy.size.height
            let isIPadPortrait = UIDevice.current.userInterfaceIdiom == .pad && !isLandscape

            ZStack(alignment: .topTrailing) {
                ScoreboardBackground()

                if isIPadPortrait || isScoreboardCompact {
                    compactLayout
                } else if isLandscape {
                    LandscapeScoreboardView(
                        store: store,
                        onRequestReset: { isShowingResetConfirmation = true }
                    )
                } else {
                    heroLayout
                }

                if (!isLandscape || isScoreboardCompact) && !isIPadPortrait {
                    ScoreboardModeButton(
                        isCompact: isScoreboardCompact,
                        isTransitioning: isScoreboardTransitioning,
                        action: toggleScoreboardMode
                    )
                    .padding(.top, 12)
                    .padding(.trailing, 14)
                    .zIndex(20)
                }
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

                    MatchControlsDock(
                        isWatchConnected: store.isWatchReachable,
                        flicInput: store.flicInput
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 16)
                .opacity(isScoreboardContentVisible ? 1 : 0)
                .scaleEffect(isScoreboardContentVisible ? 1 : 0.985, anchor: .top)
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
        // Title intentionally hidden; preserve original bar height so the
        // surrounding VStack spacing rhythm stays the same.
        HStack(spacing: 12) {
            Spacer()
        }
        .frame(height: 28)
    }

    private var bottomActionRail: some View {
        HStack(spacing: 12) {
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
                        currentServer: store.game.currentServer,
                        usesHorizontalLayout: isWide,
                        isCompact: true,
                        compactHeight: compactHeight,
                        isIphoneTapInputEnabled: store.settings.iphoneTapInputEnabled,
                        canUndo: store.game.canUndo,
                        onAddPoint: store.addPoint,
                        onUndo: store.undo
                    )
                } else {
                    let awaitingServeChoice = store.game.awaitingFirstServerChoice
                    HeroScoreboardScene(
                        availableSize: proxy.size,
                        topPlayerName: heroDisplayName(for: .playerTwo),
                        topPlayerScore: store.game.playerTwoScore,
                        topPlayerAccent: store.settings.batColor(for: .playerTwo).accentColor,
                        topPlayerIsServing: !awaitingServeChoice && store.game.currentServer == .playerTwo,
                        bottomPlayerName: heroDisplayName(for: .playerOne),
                        bottomPlayerScore: store.game.playerOneScore,
                        bottomPlayerAccent: store.settings.batColor(for: .playerOne).accentColor,
                        bottomPlayerIsServing: !awaitingServeChoice && store.game.currentServer == .playerOne,
                        winner: store.game.winner,
                        completedGames: store.game.completedGames,
                        gamesToWin: store.game.gamesToWin,
                        isIphoneTapInputEnabled: store.settings.iphoneTapInputEnabled,
                        isAwaitingServeChoice: awaitingServeChoice,
                        canUndo: store.game.canUndo,
                        onAddPoint: { player in
                            if store.game.awaitingFirstServerChoice {
                                store.setFirstServer(player)
                            } else {
                                store.addPoint(to: player)
                            }
                        },
                        onUndo: store.undo
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .opacity(isScoreboardContentVisible ? 1 : 0)
            .scaleEffect(isScoreboardContentVisible ? 1 : 0.985, anchor: .top)
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
    let topPlayerIsServing: Bool
    let bottomPlayerName: String
    let bottomPlayerScore: Int
    let bottomPlayerAccent: Color
    let bottomPlayerIsServing: Bool
    let winner: Player?
    let completedGames: [CompletedGame]
    let gamesToWin: Int
    let isIphoneTapInputEnabled: Bool
    let isAwaitingServeChoice: Bool
    let canUndo: Bool
    let onAddPoint: (Player) -> Void
    let onUndo: () -> Void

    var body: some View {
        let tableAspectRatio = 577.0 / 433.0
        let labelFontSize = min(max(availableSize.width * 0.04, 19), 27)
        let scoreFont = min(max(availableSize.width * 0.158, 102), 148)
        let scoreColumnWidth = min(max(availableSize.width * 0.19, 114), 156)
        let clusterWidth = min(max(scoreColumnWidth + 112, 232), 344)
        let railWidth = min(max(availableSize.width * 0.8, 272), 700)
        let tableFootprintWidth = min(max(availableSize.width * 0.9, 356), 640)
        let tableVisualWidth = min(max(tableFootprintWidth + 92, availableSize.width * 1.17), 800)
        let tableImageHeight = tableVisualWidth / tableAspectRatio
        // Table PNG has ~10% transparent padding at the top and ~17% at the bottom. Lift
        // the image so the visible top sits just below the opponent rail while the lower
        // rail only clips the feet. Both rails are drawn above the table.
        let tableBeamGap = 3.0
        let tableFootOverlap = min(max(tableImageHeight * 0.04, 18), 34)
        let tableTopLift = max(tableImageHeight * 0.10 - tableBeamGap, 0)
        let tableDrop = 3.0
        let originalGap = min(max(availableSize.height * 0.014, 16), 22) + min(max(tableImageHeight * 0.035, 8), 16)
        let tableContainerHeight = max(tableImageHeight * 0.852 - tableFootOverlap - (originalGap - (tableBeamGap + tableDrop)), 0)
        let horizontalPadding = min(max(availableSize.width * 0.006, 0), 6)
        let playerSpacing = min(max(availableSize.height * 0.004, 2), 6)
        let bottomRailLift = 0.0
        let bottomClusterPullUp = min(max(availableSize.height * 0.022, 12), 20)

        VStack(spacing: 0) {
            HeroPlayerCluster(
                playerName: topPlayerName,
                score: topPlayerScore,
                accent: topPlayerAccent,
                isWinner: winner == .playerTwo,
                isServing: topPlayerIsServing,
                labelFontSize: labelFontSize,
                scoreFont: scoreFont,
                scoreColumnWidth: scoreColumnWidth,
                clusterWidth: clusterWidth,
                isTapInputEnabled: isIphoneTapInputEnabled,
                isAwaitingServeChoice: isAwaitingServeChoice,
                canUndo: canUndo,
                showsPlayerName: true,
                onUndo: onUndo
            ) {
                onAddPoint(.playerTwo)
            }
            .padding(.bottom, playerSpacing)

            HeroAccentRail(accent: topPlayerAccent, emphasis: winner == .playerTwo, width: railWidth)
                .zIndex(2)

            Color.clear
                .frame(height: tableContainerHeight)
                .overlay(alignment: .top) {
                    HeroTableSurface(
                        width: tableVisualWidth,
                        height: tableImageHeight,
                        completedGames: completedGames,
                        gamesToWin: gamesToWin,
                        topAccent: topPlayerAccent,
                        bottomAccent: bottomPlayerAccent
                    )
                        .frame(maxWidth: .infinity, alignment: .center)
                        .offset(y: tableDrop - tableTopLift)
                }
                .zIndex(0)

            HeroAccentRail(accent: bottomPlayerAccent, emphasis: winner == .playerOne, width: railWidth)
                .padding(.top, -bottomRailLift)
                .padding(.bottom, playerSpacing)
                .zIndex(2)

            HeroPlayerCluster(
                playerName: bottomPlayerName,
                score: bottomPlayerScore,
                accent: bottomPlayerAccent,
                isWinner: winner == .playerOne,
                isServing: bottomPlayerIsServing,
                labelFontSize: labelFontSize,
                scoreFont: scoreFont,
                scoreColumnWidth: scoreColumnWidth,
                clusterWidth: clusterWidth,
                isTapInputEnabled: isIphoneTapInputEnabled,
                isAwaitingServeChoice: isAwaitingServeChoice,
                canUndo: canUndo,
                showsPlayerName: true,
                onUndo: onUndo
            ) {
                onAddPoint(.playerOne)
            }
            .padding(.top, -bottomClusterPullUp)
        }
        .padding(.horizontal, horizontalPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

private struct HeroTableSurface: View {
    let width: CGFloat
    let height: CGFloat
    let completedGames: [CompletedGame]
    let gamesToWin: Int
    let topAccent: Color
    let bottomAccent: Color

    private enum TableSide { case top, bottom }

    private enum SlotState {
        case unplayed
        case played(CompletedGame, isMatchClincher: Bool)
        case unneeded
    }

    private var totalSlots: Int {
        max(gamesToWin * 2 - 1, 1)
    }

    private var matchWinner: Player? {
        let p1 = completedGames.filter { $0.winner == .playerOne }.count
        let p2 = completedGames.filter { $0.winner == .playerTwo }.count
        if p1 >= gamesToWin { return .playerOne }
        if p2 >= gamesToWin { return .playerTwo }
        return nil
    }

    private func state(forGameNumber n: Int) -> SlotState {
        if let game = completedGames.first(where: { $0.gameNumber == n }) {
            let clincher = matchWinner != nil && completedGames.last?.gameNumber == n
            return .played(game, isMatchClincher: clincher)
        }
        return matchWinner == nil ? .unplayed : .unneeded
    }

    var body: some View {
        ZStack {
            Image("Table")
                .resizable()
                .scaledToFit()
                .frame(width: width)
                .shadow(color: .black.opacity(0.42), radius: 12, x: 0, y: 6)

            ForEach(1...totalSlots, id: \.self) { slot in
                let slotState = state(forGameNumber: slot)
                tile(forGameNumber: slot, state: slotState, side: .top)
                    .position(position(forGameNumber: slot, side: .top))
                tile(forGameNumber: slot, state: slotState, side: .bottom)
                    .position(position(forGameNumber: slot, side: .bottom))
            }
        }
        .frame(width: width, height: height)
    }

    @ViewBuilder
    private func tile(forGameNumber n: Int, state: SlotState, side: TableSide) -> some View {
        let titleSize = min(max(width * 0.019, 11), 14)
        let scoreSize = min(max(width * 0.027, 15), 19)
        let underlineWidth = min(max(width * 0.062, 36), 52)
        let iconSize = min(max(width * 0.020, 11), 15)
        let crownSize = min(max(width * 0.030, 16), 22)
        let sideAccent: Color = side == .top ? topAccent : bottomAccent

        switch state {
        case .unplayed:
            unplayedTile(gameNumber: n, titleSize: titleSize, underlineWidth: underlineWidth)
        case .played(let game, let isClincher):
            let winnerSide: TableSide = game.winner == .playerOne ? .bottom : .top
            if side == winnerSide {
                wonTile(
                    game: game,
                    titleSize: titleSize,
                    scoreSize: scoreSize,
                    underlineWidth: underlineWidth,
                    crownSize: crownSize,
                    accent: sideAccent,
                    isClincher: isClincher
                )
            } else {
                lostTile(
                    gameNumber: n,
                    titleSize: titleSize,
                    iconSize: iconSize,
                    accent: sideAccent
                )
            }
        case .unneeded:
            unneededTile(gameNumber: n, titleSize: titleSize)
        }
    }

    private func unplayedTile(
        gameNumber n: Int,
        titleSize: CGFloat,
        underlineWidth: CGFloat
    ) -> some View {
        VStack(spacing: 3) {
            Text("G\(n)")
                .font(.system(size: titleSize, weight: .bold, design: .rounded))
            Path { p in
                p.move(to: CGPoint(x: 0, y: 0.5))
                p.addLine(to: CGPoint(x: underlineWidth, y: 0.5))
            }
            .stroke(
                Color.white.opacity(0.40),
                style: StrokeStyle(lineWidth: 1, lineCap: .round, dash: [2.5, 2])
            )
            .frame(width: underlineWidth, height: 1)
        }
        .foregroundStyle(Color.white.opacity(0.42))
        .multilineTextAlignment(.center)
        .lineLimit(1)
        .shadow(color: .black.opacity(0.55), radius: 2, x: 0, y: 1)
    }

    private func wonTile(
        game: CompletedGame,
        titleSize: CGFloat,
        scoreSize: CGFloat,
        underlineWidth: CGFloat,
        crownSize: CGFloat,
        accent: Color,
        isClincher: Bool
    ) -> some View {
        VStack(spacing: 3) {
            Text("G\(game.gameNumber)")
                .font(.system(size: titleSize, weight: .bold, design: .rounded))

            Text("\(game.player1Score) — \(game.player2Score)")
                .font(.system(size: scoreSize, weight: .semibold, design: .rounded))
                .monospacedDigit()

            Rectangle()
                .fill(accent)
                .frame(width: underlineWidth, height: 1.5)
                .shadow(color: accent.opacity(0.6), radius: 3, x: 0, y: 0)
        }
        .foregroundStyle(accent)
        .multilineTextAlignment(.center)
        .lineLimit(1)
        .minimumScaleFactor(0.78)
        .shadow(color: .black.opacity(0.62), radius: 2, x: 0, y: 1)
        .shadow(
            color: accent.opacity(isClincher ? 0.62 : 0.42),
            radius: isClincher ? 8 : 5,
            x: 0,
            y: 0
        )
        .shadow(
            color: accent.opacity(isClincher ? 0.34 : 0.22),
            radius: isClincher ? 16 : 11,
            x: 0,
            y: 0
        )
        .overlay(alignment: .top) {
            if isClincher {
                Image(systemName: "crown.fill")
                    .font(.system(size: crownSize, weight: .semibold))
                    .foregroundStyle(accent)
                    .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
                    .shadow(color: accent.opacity(0.55), radius: 6, x: 0, y: 0)
                    .offset(y: -(crownSize + 4))
            }
        }
    }

    private func lostTile(
        gameNumber n: Int,
        titleSize: CGFloat,
        iconSize: CGFloat,
        accent: Color
    ) -> some View {
        VStack(spacing: 4) {
            Text("G\(n)")
                .font(.system(size: titleSize, weight: .bold, design: .rounded))
            Image(systemName: "xmark")
                .font(.system(size: iconSize, weight: .bold))
        }
        .foregroundStyle(accent.opacity(0.55))
        .multilineTextAlignment(.center)
        .lineLimit(1)
        .shadow(color: .black.opacity(0.55), radius: 2, x: 0, y: 1)
        .shadow(color: accent.opacity(0.18), radius: 6, x: 0, y: 0)
    }

    private func unneededTile(gameNumber n: Int, titleSize: CGFloat) -> some View {
        Text("G\(n)")
            .font(.system(size: titleSize, weight: .bold, design: .rounded))
            .foregroundStyle(Color.white.opacity(0.22))
            .lineLimit(1)
            .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
    }

    private func position(forGameNumber n: Int, side: TableSide) -> CGPoint {
        let slot = CGFloat(min(max(n - 1, 0), 2))
        switch side {
        case .top:
            return CGPoint(
                x: width * (0.36 + slot * 0.14),
                y: height * 0.19
            )
        case .bottom:
            return CGPoint(
                x: width * (0.29 + slot * 0.21),
                y: height * 0.68
            )
        }
    }
}

private struct HeroPlayerCluster: View {
    let playerName: String
    let score: Int
    let accent: Color
    let isWinner: Bool
    let isServing: Bool
    let labelFontSize: CGFloat
    let scoreFont: CGFloat
    let scoreColumnWidth: CGFloat
    let clusterWidth: CGFloat
    let isTapInputEnabled: Bool
    let isAwaitingServeChoice: Bool
    let canUndo: Bool
    let showsPlayerName: Bool
    let onUndo: () -> Void
    let action: () -> Void

    private var tapAction: (() -> Void)? {
        isTapInputEnabled || isAwaitingServeChoice ? action : nil
    }

    private var longPressAction: (() -> Void)? {
        canUndo ? onUndo : nil
    }

    private var accessibilityHint: String {
        if isAwaitingServeChoice {
            return canUndo
                ? "Tap to choose \(playerName) to serve first, or touch and hold to undo the last point"
                : "Tap to choose \(playerName) to serve first"
        }

        if isTapInputEnabled {
            return canUndo
                ? "Tap to add one point for \(playerName), or touch and hold to undo the last point"
                : "Tap to add one point for \(playerName)"
        }

        return "Touch and hold to undo the last point"
    }

    var body: some View {
        clusterBody
            .scoreInputGesture(
                tapAction: tapAction,
                longPressAction: longPressAction,
                accessibilityHint: accessibilityHint
            )
    }

    private var clusterBody: some View {
        let nameSize = labelFontSize
        let serveBadgeHeight = max(nameSize * 1.05, 22)

        return VStack(alignment: .center, spacing: 4) {
            if showsPlayerName {
                Text(playerName)
                    .font(.system(size: nameSize, weight: .semibold, design: .rounded))
                    .foregroundStyle(accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                    .shadow(color: accent.opacity(0.55), radius: 8, x: 0, y: 0)
                    .shadow(color: accent.opacity(0.30), radius: 18, x: 0, y: 0)
            }

            HeroScoreText(score: score, accent: accent, fontSize: scoreFont, isWinner: isWinner)
                .frame(width: scoreColumnWidth, alignment: .center)

            Group {
                if isAwaitingServeChoice {
                    ServeChoiceBadge(accent: accent, isCompact: false)
                } else {
                    ServeBadge(accent: accent, isCompact: false)
                        .opacity(isServing ? 1 : 0)
                        .accessibilityHidden(!isServing)
                }
            }
            .frame(height: serveBadgeHeight)
        }
        .frame(maxWidth: clusterWidth, minHeight: max(scoreFont * 0.96, 108), alignment: .center)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 1)
        .accessibilityLabel("\(playerName), score \(min(score, 99))\(isServing ? ", serving" : "")")
    }
}

extension View {
    func scoreInputGesture(
        tapAction: (() -> Void)?,
        longPressAction: (() -> Void)?,
        accessibilityHint: String
    ) -> some View {
        modifier(
            ScoreInputGestureModifier(
                tapAction: tapAction,
                longPressAction: longPressAction,
                accessibilityHint: accessibilityHint
            )
        )
    }
}

struct ScoreInputGestureModifier: ViewModifier {
    let tapAction: (() -> Void)?
    let longPressAction: (() -> Void)?
    let accessibilityHint: String

    private var isEnabled: Bool {
        tapAction != nil || longPressAction != nil
    }

    @ViewBuilder
    func body(content: Content) -> some View {
        if isEnabled {
            accessibilityActions(
                content
                    .contentShape(Rectangle())
                    .gesture(scoreGesture)
                    .accessibilityAddTraits(.isButton)
                    .accessibilityHint(accessibilityHint)
            )
        } else {
            content
        }
    }

    private var scoreGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.55)
            .exclusively(before: TapGesture())
            .onEnded { value in
                switch value {
                case .first:
                    longPressAction?()
                case .second:
                    tapAction?()
                }
            }
    }

    @ViewBuilder
    private func accessibilityActions<Content: View>(_ content: Content) -> some View {
        if let tapAction, let longPressAction {
            content
                .accessibilityAction {
                    tapAction()
                }
                .accessibilityAction(named: Text("Undo Last Point")) {
                    longPressAction()
                }
        } else if let tapAction {
            content
                .accessibilityAction {
                    tapAction()
                }
        } else if let longPressAction {
            content
                .accessibilityAction {
                    longPressAction()
                }
        }
    }
}

private struct ServeBadge: View {
    let accent: Color
    let isCompact: Bool

    var body: some View {
        Label("Serve", systemImage: "circle.fill")
            .font(.system(size: isCompact ? 9 : 11, weight: .semibold, design: .rounded))
            .labelStyle(.titleAndIcon)
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .foregroundStyle(accent.opacity(0.94))
            .padding(.horizontal, isCompact ? 9 : 12)
            .padding(.vertical, isCompact ? 4 : 5)
            .background(
                Capsule()
                    .stroke(accent.opacity(0.55), lineWidth: 1)
            )
            .shadow(color: accent.opacity(0.28), radius: 5, x: 0, y: 0)
    }
}

private struct ServeChoiceBadge: View {
    let accent: Color
    let isCompact: Bool

    var body: some View {
        Text("Tap to Serve")
            .font(.system(size: isCompact ? 9 : 11, weight: .semibold, design: .rounded))
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .foregroundStyle(accent.opacity(0.78))
            .padding(.horizontal, isCompact ? 9 : 12)
            .padding(.vertical, isCompact ? 4 : 5)
            .background(
                Capsule()
                    .stroke(
                        accent.opacity(0.45),
                        style: StrokeStyle(lineWidth: 1, dash: [3, 3])
                    )
            )
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
            .foregroundStyle(accent)
            .shadow(color: .black.opacity(0.30), radius: 2, x: 0, y: 1)
            .shadow(color: accent.opacity(isWinner ? 0.75 : 0.62), radius: isWinner ? 18 : 14, x: 0, y: 0)
            .shadow(color: accent.opacity(isWinner ? 0.45 : 0.32), radius: isWinner ? 36 : 28, x: 0, y: 0)
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
    let currentServer: Player
    let usesHorizontalLayout: Bool
    let isCompact: Bool
    let compactHeight: CGFloat
    let isIphoneTapInputEnabled: Bool
    let canUndo: Bool
    let onAddPoint: (Player) -> Void
    let onUndo: () -> Void

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
                isServing: currentServer == .playerOne,
                isCompact: isCompact
            )

            playerScorePanel(
                player: .playerTwo,
                playerName: playerTwoName,
                score: playerTwoScore,
                accent: playerTwoAccent,
                isWinner: winner == .playerTwo,
                isServing: currentServer == .playerTwo,
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
        isServing: Bool,
        isCompact: Bool
    ) -> some View {
        let panel = PlayerScorePanel(
            playerName: playerName,
            score: score,
            accent: accent,
            isWinner: isWinner,
            isServing: isServing,
            isCompact: isCompact,
            isTapInputEnabled: isIphoneTapInputEnabled
        )

        if isIphoneTapInputEnabled {
            panel
                .scoreInputGesture(
                    tapAction: { onAddPoint(player) },
                    longPressAction: canUndo ? onUndo : nil,
                    accessibilityHint: canUndo
                        ? "Tap to add one point for \(playerName), or touch and hold to undo the last point"
                        : "Tap to add one point for \(playerName)"
                )
        } else if canUndo {
            panel
                .scoreInputGesture(
                    tapAction: nil,
                    longPressAction: onUndo,
                    accessibilityHint: "Touch and hold to undo the last point"
                )
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
    let isServing: Bool
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

                if isServing {
                    ServeBadge(accent: accent, isCompact: isCompact)
                }

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
