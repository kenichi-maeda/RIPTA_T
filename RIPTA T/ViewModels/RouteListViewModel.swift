//
//  RouteListViewModel.swift
//  RIPTA T
//
//  Created by Kenichi Maeda on 6/22/25.
//

import Foundation
import Combine

/// ViewModel for showing all RIPTA routes
final class RouteListViewModel: ObservableObject {
    @Published var routes: [Route] = []
    
    init() {
        loadRoutes()
    }
    
    private func loadRoutes() {
        // Pull from your static loader
        let all = GTFSStaticDataLoader.shared.routes
        // Sort however you like (e.g. by short name)
        routes = all.sorted { $0.route_short_name < $1.route_short_name }
    }
}
