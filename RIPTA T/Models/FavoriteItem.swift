//
//  FavoriteItem.swift
//  RIPTA T
//
//  Created by Kenichi Maeda on 7/3/25.
//

import Foundation

/// A “favorite” is a particular route + stop + direction combo
struct FavoriteItem: Identifiable, Codable, Equatable {
    let routeID: String
    let stopID: String
    let direction: Int

    // Unique ID for Identifiable
    var id: String { "\(routeID)|\(stopID)|\(direction)" }
}
