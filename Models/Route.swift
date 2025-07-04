//
//  Route.swift
//  RIPTA T
//
//  Created by Kenichi Maeda on 6/22/25.
//

import Foundation

struct Route: Identifiable {
    let route_id: String
    let route_short_name: String
    let route_long_name: String
    let route_type: Int
    let route_url: URL?
    let route_color: String?
    let route_text_color: String?
    var id: String { route_id }
}
