//
//  ContentView.swift
//  Pongle Watch App Watch App
//
//  Created by Siddhant Daigavane on 21/04/26.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var store: WatchScoreStore

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 10) {
                HStack {
                    Text("Pongle")
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)

                    Spacer()

                    Image(systemName: store.isPhoneReachable ? "iphone.radiowaves.left.and.right" : "iphone")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(store.isPhoneReachable ? .mint : .white.opacity(0.48))
                }

                HStack(spacing: 8) {
                    WatchScoreTile(
                        label: Player.playerOne.displayName,
                        score: store.game.playerOneScore,
                        accent: .teal,
                        isWinner: store.game.winner == .playerOne
                    )

                    WatchScoreTile(
                        label: Player.playerTwo.displayName,
                        score: store.game.playerTwoScore,
                        accent: .orange,
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
}

private struct WatchScoreTile: View {
    let label: String
    let score: Int
    let accent: Color
    let isWinner: Bool

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.58))
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(score, format: .number)
                .font(.system(size: 54, weight: .black, design: .rounded))
                .monospacedDigit()
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, minHeight: 108)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
        .overlay(alignment: .top) {
            Rectangle()
                .fill(accent)
                .frame(height: 3)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(isWinner ? accent : Color.white.opacity(0.11), lineWidth: isWinner ? 2 : 1)
        }
    }
}

#Preview {
    ContentView(store: WatchScoreStore(activatesConnectivity: false))
}
