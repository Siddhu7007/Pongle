//
//  Pongle_Watch_AppApp.swift
//  Pongle Watch App Watch App
//
//  Created by Siddhant Daigavane on 21/04/26.
//

import SwiftUI

@main
struct Pongle_Watch_App_Watch_AppApp: App {
    @StateObject private var scoreStore = WatchScoreStore()

    var body: some Scene {
        WindowGroup {
            ContentView(store: scoreStore)
        }
    }
}
