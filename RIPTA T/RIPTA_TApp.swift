//
//  RIPTA_TApp.swift
//  RIPTA T
//
//  Created by Kenichi Maeda on 6/22/25.
//

import SwiftUI

@main
struct RIPTA_TApp: App {
    // Single shared FavoritesManager
    @StateObject private var favoritesManager = FavoritesManager()

    var body: some Scene {
        WindowGroup {
            HomeView()
              .environmentObject(favoritesManager)
        }
    }
}

