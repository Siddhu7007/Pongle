//
//  PongleApp.swift
//  Pongle
//
//  Created by Siddhant Daigavane on 21/04/26.
//

import SwiftUI
import UIKit

@main
struct PongleApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var settings = AppSettings()
    @StateObject private var scoreStore: PhoneScoreStore

    init() {
        let settings = AppSettings()
        _settings = StateObject(wrappedValue: settings)
        _scoreStore = StateObject(wrappedValue: PhoneScoreStore(settings: settings))
    }

    var body: some Scene {
        WindowGroup {
            ContentView(store: scoreStore)
                .environmentObject(settings)
                .onChange(of: scenePhase, initial: true) { _, newPhase in
                    updateIdleTimer(for: newPhase)
                }
        }
    }

    private func updateIdleTimer(for scenePhase: ScenePhase) {
        UIApplication.shared.isIdleTimerDisabled = scenePhase == .active
    }
}
