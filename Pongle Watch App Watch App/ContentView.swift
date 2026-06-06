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

struct ContentView: View {
    @ObservedObject var store: WatchScoreStore

    var body: some View {
        InputPadWatchView(store: store)
    }
}

private struct InputPadWatchView: View {
    @ObservedObject var store: WatchScoreStore
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced
    @State private var isPressed = false
    @State private var showsMatchModeEndOptions = false

    var body: some View {
        GeometryReader { proxy in
            let buttonSize = min(proxy.size.width * 0.94, proxy.size.height * 0.94)

            ZStack {
                Color.black
                    .ignoresSafeArea()

                if !isLuminanceReduced {
                    RadialGradient(
                        colors: [
                            Color(red: 0.04, green: 0.30, blue: 0.13),
                            Color(red: 0.015, green: 0.12, blue: 0.05),
                            Color.black
                        ],
                        center: .center,
                        startRadius: 6,
                        endRadius: max(proxy.size.width, proxy.size.height) * 0.95
                    )
                    .ignoresSafeArea()
                }

                if !isLuminanceReduced {
                    Circle()
                        .fill(Color(red: 0.30, green: 1.0, blue: 0.45).opacity(isPressed ? 0.46 : 0.22))
                        .frame(width: buttonSize * 1.20, height: buttonSize * 1.20)
                        .blur(radius: 34)
                        .animation(.easeOut(duration: 0.18), value: isPressed)
                        .allowsHitTesting(false)
                }

                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white,
                                    Color(white: 0.96),
                                    Color(white: 0.78)
                                ],
                                center: UnitPoint(x: 0.40, y: 0.32),
                                startRadius: 2,
                                endRadius: buttonSize * 0.62
                            )
                        )

                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white,
                                    Color(white: 0.58)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )

                    Circle()
                        .strokeBorder(Color.black.opacity(0.18), lineWidth: 1)
                        .padding(2)

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(0.95),
                                    Color.white.opacity(0.0)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: buttonSize * 0.28
                            )
                        )
                        .frame(width: buttonSize * 0.55, height: buttonSize * 0.42)
                        .blur(radius: 10)
                        .offset(x: -buttonSize * 0.12, y: -buttonSize * 0.20)
                }
                .frame(width: buttonSize, height: buttonSize)
                .shadow(
                    color: Color.black.opacity(isLuminanceReduced ? 0 : (isPressed ? 0.30 : 0.62)),
                    radius: isLuminanceReduced ? 0 : (isPressed ? 6 : 18),
                    x: 0,
                    y: isLuminanceReduced ? 0 : (isPressed ? 2 : 9)
                )
                .scaleEffect(isPressed ? 0.94 : 1.0)
                .animation(.spring(response: 0.22, dampingFraction: 0.62), value: isPressed)
                .contentShape(Circle())
                .onTapGesture {
                    store.registerTap()
                }
                .onLongPressGesture(minimumDuration: 0.55) {
                    store.undo()
                }
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            if !isPressed {
                                isPressed = true
                            }
                        }
                        .onEnded { _ in
                            isPressed = false
                        }
                )
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Input pad")
                .accessibilityHint(store.inputAccessibilityHint)

                VStack {
                    HStack {
                        matchModeButton
                        Spacer()
                        Circle()
                            .fill(store.isPhoneReachable ? Color.green : Color.pongleAccent)
                            .frame(width: 6, height: 6)
                            .opacity(0.85)
                            .shadow(
                                color: (store.isPhoneReachable ? Color.green : Color.pongleAccent).opacity(0.55),
                                radius: 4
                            )
                    }
                    Spacer()
                }
                .padding(.top, 4)
                .padding(.trailing, 6)
                .padding(.leading, 6)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .confirmationDialog(
                "End Table Tennis Match Mode?",
                isPresented: $showsMatchModeEndOptions,
                titleVisibility: .visible
            ) {
                Button("Save Workout") {
                    store.endMatchMode(saveToHealth: true)
                }

                Button("Discard Workout") {
                    store.endMatchMode(saveToHealth: false)
                }

                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Saving is optional. Discarding ends Match Mode without adding a workout to Health.")
            }
            .onChange(of: store.game.matchWinner) { _, winner in
                guard winner != nil, store.matchModeState.isActive else {
                    return
                }

                showsMatchModeEndOptions = true
            }
        }
    }

    private var matchModeButton: some View {
        Button {
            if store.matchModeState.isActive {
                showsMatchModeEndOptions = true
            } else {
                store.startMatchMode()
            }
        } label: {
            Text(store.matchModeState.isActive ? "End" : store.matchModeState.statusText)
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.65)
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(matchModeTint.opacity(store.matchModeState.isActive ? 0.95 : 0.74))
                )
                .foregroundStyle(store.matchModeState.isActive ? Color.black : Color.white)
        }
        .buttonStyle(.plain)
        .disabled(!canTapMatchModeButton)
        .opacity(canTapMatchModeButton ? 1 : 0.64)
        .accessibilityLabel(store.matchModeState.isActive ? "End Table Tennis Match Mode" : "Start Table Tennis Match Mode")
    }

    private var canTapMatchModeButton: Bool {
        switch store.matchModeState {
        case .inactive, .active, .authorizationDenied, .failed:
            true
        case .requestingAuthorization, .starting, .ending, .unavailable:
            false
        }
    }

    private var matchModeTint: Color {
        switch store.matchModeState {
        case .active:
            Color(red: 0.30, green: 1.0, blue: 0.45)
        case .authorizationDenied, .failed, .unavailable:
            Color.pongleAccent
        case .inactive, .requestingAuthorization, .starting, .ending:
            Color.white.opacity(0.20)
        }
    }
}

#Preview {
    ContentView(store: WatchScoreStore(activatesConnectivity: false))
}
