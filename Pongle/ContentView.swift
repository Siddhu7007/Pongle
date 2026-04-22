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

    var body: some View {
        ZStack {
            ScoreboardBackground()

            VStack(spacing: 22) {
                topBar

                GeometryReader { proxy in
                    let isWide = proxy.size.width > proxy.size.height

                    Group {
                        if isWide {
                            HStack(spacing: 16) {
                                PlayerScorePanel(
                                    playerName: Player.playerOne.displayName,
                                    score: store.game.playerOneScore,
                                    accent: .teal,
                                    isWinner: store.game.winner == .playerOne
                                )
                                PlayerScorePanel(
                                    playerName: Player.playerTwo.displayName,
                                    score: store.game.playerTwoScore,
                                    accent: .orange,
                                    isWinner: store.game.winner == .playerTwo
                                )
                            }
                        } else {
                            VStack(spacing: 16) {
                                PlayerScorePanel(
                                    playerName: Player.playerOne.displayName,
                                    score: store.game.playerOneScore,
                                    accent: .teal,
                                    isWinner: store.game.winner == .playerOne
                                )
                                PlayerScorePanel(
                                    playerName: Player.playerTwo.displayName,
                                    score: store.game.playerTwoScore,
                                    accent: .orange,
                                    isWinner: store.game.winner == .playerTwo
                                )
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                bottomActionRail
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 20)
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

private struct PlayerScorePanel: View {
    let playerName: String
    let score: Int
    let accent: Color
    let isWinner: Bool

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(playerName)
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.72))
                Spacer()
                if isWinner {
                    Label("Game", systemImage: "flag.checkered")
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .foregroundStyle(accent)
                        .labelStyle(.titleAndIcon)
                }
            }

            Text(score, format: .number)
                .font(.system(size: 148, weight: .black, design: .rounded))
                .monospacedDigit()
                .minimumScaleFactor(0.38)
                .lineLimit(1)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.white.opacity(0.075))
        )
        .overlay(alignment: .top) {
            Rectangle()
                .fill(accent)
                .frame(height: 4)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(isWinner ? accent : Color.white.opacity(0.1), lineWidth: isWinner ? 2 : 1)
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
        .foregroundStyle(isConnected ? Color.mint : Color.white.opacity(0.66))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.08))
        )
        .overlay {
            Capsule()
                .stroke(isConnected ? Color.mint.opacity(0.45) : Color.white.opacity(0.12), lineWidth: 1)
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
    ContentView(store: PhoneScoreStore(activatesConnectivity: false))
}
