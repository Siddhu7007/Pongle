//
//  PongleApp.swift
//  Pongle
//
//  Created by Siddhant Daigavane on 21/04/26.
//

import SwiftUI

@main
struct PongleApp: App {
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
        }
    }
}
