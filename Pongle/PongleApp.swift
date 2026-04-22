//
//  PongleApp.swift
//  Pongle
//
//  Created by Siddhant Daigavane on 21/04/26.
//

import SwiftUI

@main
struct PongleApp: App {
    @StateObject private var scoreStore = PhoneScoreStore()

    var body: some Scene {
        WindowGroup {
            ContentView(store: scoreStore)
        }
    }
}
