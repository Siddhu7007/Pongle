//
//  ContentView.swift
//  Pongle Watch App Watch App
//
//  Created by Siddhant Daigavane on 21/04/26.
//

import SwiftUI
import Foundation

extension Color {
    /// Tasteful ping-pong orange used for active UI accents (phone reachability indicator, etc.).
    static let pongleAccent = Color(red: 0.98, green: 0.56, blue: 0.20)
}

private enum PlayerBatColor: String {
    case teal
    case orange
    case blue
    case red
    case lime
    case purple

    var accentColor: Color {
        switch self {
        case .teal: Color(red: 0.00, green: 0.68, blue: 0.66)
        case .orange: Color.pongleAccent
        case .blue: Color(red: 0.18, green: 0.38, blue: 0.96)
        case .red: Color(red: 0.96, green: 0.16, blue: 0.20)
        case .lime: Color(red: 0.62, green: 0.82, blue: 0.12)
        case .purple: Color(red: 0.62, green: 0.30, blue: 0.88)
        }
    }
}

struct ContentView: View {
    @ObservedObject var store: WatchScoreStore

    var body: some View {
        WatchRootModeContainer(store: store)
    }
}

private struct WatchRootModeContainer: View {
    @ObservedObject var store: WatchScoreStore
    @State private var selectedMode = WatchMode.inputPad

    var body: some View {
        Group {
            if store.watchSwipeEnabled {
                TabView(selection: $selectedMode) {
                    InputPadWatchView(store: store)
                        .tag(WatchMode.inputPad)

                    ScoreGlanceWatchView(store: store)
                        .tag(WatchMode.scoreGlance)
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))
            } else {
                modeView(store.defaultWatchMode)
            }
        }
        .onAppear {
            selectedMode = store.defaultWatchMode
        }
        .onChange(of: store.defaultWatchMode) { _, newMode in
            selectedMode = newMode
        }
        .onChange(of: store.watchSwipeEnabled) { _, isEnabled in
            if isEnabled {
                selectedMode = store.defaultWatchMode
            }
        }
    }

    @ViewBuilder
    private func modeView(_ mode: WatchMode) -> some View {
        switch mode {
        case .inputPad:
            InputPadWatchView(store: store)
        case .scoreGlance:
            ScoreGlanceWatchView(store: store)
        }
    }
}

private struct InputPadWatchView: View {
    @ObservedObject var store: WatchScoreStore

    var body: some View {
        GeometryReader { proxy in
            let buttonSize = min(proxy.size.width * 0.84, proxy.size.height * 0.62, 188)

            ZStack {
                Color.black
                    .ignoresSafeArea()

                RadialGradient(
                    colors: [
                        Color.green.opacity(0.26),
                        Color.green.opacity(0.1),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 8,
                    endRadius: max(proxy.size.width, proxy.size.height) * 0.56
                )
                .scaleEffect(x: 1.18, y: 0.92)
                .offset(y: -2)

                VStack(spacing: 0) {
                    HStack(spacing: 8) {
                        Text("Input Pad")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.72))
                            .lineLimit(1)

                        Spacer()

                        HStack(spacing: 5) {
                            Circle()
                                .fill(store.isPhoneReachable ? Color.green : Color.pongleAccent)
                                .frame(width: 6, height: 6)
                                .shadow(
                                    color: (store.isPhoneReachable ? Color.green : Color.pongleAccent).opacity(0.55),
                                    radius: 5,
                                    x: 0,
                                    y: 0
                                )

                            Image(systemName: store.isPhoneReachable ? "iphone.radiowaves.left.and.right" : "iphone")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundStyle(store.isPhoneReachable ? Color.green.opacity(0.9) : Color.pongleAccent.opacity(0.82))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Color.white.opacity(0.07)))
                        .overlay {
                            Capsule()
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        }
                        .accessibilityLabel(store.isPhoneReachable ? "Phone connected" : "Phone idle")
                    }
                    .frame(height: 24)

                    Spacer(minLength: 8)

                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.green.opacity(0.42),
                                        Color.green.opacity(0.2),
                                        Color(red: 0.02, green: 0.12, blue: 0.05)
                                    ],
                                    center: .center,
                                    startRadius: 4,
                                    endRadius: buttonSize / 2
                                )
                            )

                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.green.opacity(0.95),
                                        Color.green.opacity(0.46)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )

                        Circle()
                            .stroke(Color.green.opacity(0.2), lineWidth: 18)
                            .blur(radius: 15)

                        Circle()
                            .fill(Color.white.opacity(0.06))
                            .frame(width: buttonSize * 0.42, height: buttonSize * 0.42)
                            .blur(radius: 16)
                            .offset(x: -buttonSize * 0.14, y: -buttonSize * 0.14)

                        VStack(spacing: 6) {
                            Text("+1")
                                .font(.system(size: buttonSize * 0.4, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.72)
                                .shadow(color: .black.opacity(0.55), radius: 2, x: 0, y: 2)

                            Text("ME")
                                .font(.system(size: buttonSize * 0.14, weight: .black, design: .rounded))
                                .foregroundStyle(.white.opacity(0.92))
                                .lineLimit(1)
                                .minimumScaleFactor(0.72)
                                .shadow(color: .black.opacity(0.45), radius: 1, x: 0, y: 1)
                        }
                    }
                    .frame(width: buttonSize, height: buttonSize)
                    .shadow(color: Color.green.opacity(0.55), radius: 24, x: 0, y: 0)
                    .contentShape(Circle())
                    .onTapGesture {
                        store.registerTap()
                    }
                    .onLongPressGesture(minimumDuration: 0.55) {
                        store.undo()
                    }
                    .accessibilityLabel("Add point for me")
                    .accessibilityHint("Tap once for me, tap twice for opponent, hold to undo")

                    Spacer(minLength: 10)

                    HStack(spacing: 6) {
                        Text("Tap")
                            .foregroundStyle(Color.green.opacity(0.88))
                        Text("•")
                            .foregroundStyle(.white.opacity(0.28))
                        Text("Tap Tap")
                            .foregroundStyle(Color.yellow.opacity(0.86))
                        Text("•")
                            .foregroundStyle(.white.opacity(0.28))
                        Text("Hold")
                            .foregroundStyle(Color.purple.opacity(0.86))
                    }
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.white.opacity(0.07)))
                    .overlay {
                        Capsule()
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    }
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .accessibilityLabel("Tap, tap tap, hold")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 13)
                .padding(.top, 4)
                .padding(.bottom, 12)
            }
        }
    }
}

private struct ScoreGlanceWatchView: View {
    @ObservedObject var store: WatchScoreStore

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 12) {
                HStack {
                    Text("Pongle")
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)

                    Spacer()

                    Image(systemName: store.isPhoneReachable ? "iphone.radiowaves.left.and.right" : "iphone")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(store.isPhoneReachable ? Color.pongleAccent : Color.white.opacity(0.48))
                }

                HStack(spacing: 8) {
                    FlipScoreTile(
                        label: store.displayName(for: .playerOne),
                        score: store.game.playerOneScore,
                        accent: accentColor(for: .playerOne),
                        isWinner: store.game.winner == .playerOne
                    )

                    FlipScoreTile(
                        label: store.displayName(for: .playerTwo),
                        score: store.game.playerTwoScore,
                        accent: accentColor(for: .playerTwo),
                        isWinner: store.game.winner == .playerTwo
                    )
                }

                Text(store.eventText)
                    .font(.system(.footnote, design: .rounded, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.58))
                    .lineLimit(1)
                    .minimumScaleFactor(0.74)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            store.registerTap()
        }
        .onLongPressGesture(minimumDuration: 0.55) {
            store.undo()
        }
    }

    private func accentColor(for player: Player) -> Color {
        PlayerBatColor(rawValue: store.colorID(for: player))?.accentColor
            ?? (player == .playerOne ? .teal : .orange)
    }
}

private struct FlipScoreTile: View {
    let label: String
    let score: Int
    let accent: Color
    let isWinner: Bool

    private var scoreText: String {
        String(format: "%02d", min(score, 99))
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Text(label)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.68))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                if isWinner {
                    Image(systemName: "flag.checkered")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(accent)
                }
            }

            SplitFlapScorePanel(value: scoreText)
            .frame(maxWidth: .infinity, minHeight: 112)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(accent)
                    .frame(height: 4)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isWinner ? accent : Color.white.opacity(0.14), lineWidth: isWinner ? 2 : 1)
            }
            .shadow(color: accent.opacity(isWinner ? 0.26 : 0.1), radius: isWinner ? 8 : 3, x: 0, y: 0)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct SplitFlapScorePanel: View {
    let value: String

    var body: some View {
        HStack(spacing: 3) {
            ForEach(Array(value.enumerated()), id: \.offset) { _, digit in
                SplitFlapDigit(value: String(digit))
            }
        }
        .padding(5)
        .background(Color(red: 0.07, green: 0.07, blue: 0.08))
    }
}

private struct SplitFlapDigit: View {
    let value: String

    @State private var currentValue: String
    @State private var previousValue: String
    @State private var nextValue: String
    @State private var isFlipping = false
    @State private var showBottomFlip = false
    @State private var topRotation = 0.0
    @State private var bottomRotation = 90.0
    @State private var flipTask: Task<Void, Never>?

    init(value: String) {
        self.value = value
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
                        fullSize: size
                    )
                    .frame(height: halfHeight)

                    FlipDigitHalf(
                        text: isFlipping ? previousValue : currentValue,
                        half: .bottom,
                        fullSize: size
                    )
                    .frame(height: halfHeight)
                }

                if isFlipping {
                    VStack(spacing: 0) {
                        FlipDigitHalf(text: previousValue, half: .top, fullSize: size)
                            .frame(height: halfHeight)
                            .rotation3DEffect(
                                .degrees(topRotation),
                                axis: (x: 1, y: 0, z: 0),
                                anchor: .bottom,
                                perspective: 0.72
                            )
                            .shadow(color: .black.opacity(0.58), radius: 4, x: 0, y: 5)
                            .opacity(showBottomFlip ? 0 : 1)
                            .zIndex(2)

                        Spacer(minLength: 0)
                    }

                    VStack(spacing: 0) {
                        Spacer(minLength: 0)

                        FlipDigitHalf(text: nextValue, half: .bottom, fullSize: size)
                            .frame(height: halfHeight)
                            .rotation3DEffect(
                                .degrees(bottomRotation),
                                axis: (x: 1, y: 0, z: 0),
                                anchor: .top,
                                perspective: 0.72
                            )
                            .shadow(color: .black.opacity(0.45), radius: 4, x: 0, y: -4)
                            .opacity(showBottomFlip ? 1 : 0)
                            .zIndex(3)
                    }
                }

                HingeLine()
            }
            .background(Color(red: 0.08, green: 0.08, blue: 0.09))
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
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
        min(fullSize.height * 0.72, fullSize.width * 1.54)
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
                    .frame(width: 4, height: 4)
                Spacer()
                Circle()
                    .fill(Color.black.opacity(0.82))
                    .frame(width: 4, height: 4)
            }
            .padding(.horizontal, 6)
        }
    }
}

#Preview {
    ContentView(store: WatchScoreStore(activatesConnectivity: false))
}
