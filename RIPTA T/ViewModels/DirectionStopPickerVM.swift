//
//  DirectionStopPickerVM.swift
//  RIPTA T
//
//  Created by Kenichi Maeda on 6/22/25.
//


import Foundation
import Combine

/// ViewModel for choosing a direction (0/1) and listing stops for that direction
final class DirectionStopPickerViewModel: ObservableObject {
    let route: Route

    /// All trips on this route, grouped by direction (0 or 1)
    private var tripsByDirection: [Int: [Trip]] = [:]

    /// The currently selected direction (0 = outbound, 1 = inbound)
    @Published var selectedDirection: Int = 0 {
        didSet { loadStops() }
    }

    /// The stops (in sequence) for the selected direction’s first trip
    @Published var stops: [Stop] = []

    init(route: Route) {
        self.route = route
        let allTrips = GTFSStaticDataLoader.shared.trips
            .filter { $0.route_id == route.route_id }
        self.tripsByDirection = Dictionary(grouping: allTrips, by: { $0.direction_id })
        loadStops()
    }

    private func loadStops() {
        guard let trips = tripsByDirection[selectedDirection],
              let trip = trips.sorted(by: { $0.trip_id < $1.trip_id }).first
        else {
            stops = []
            return
        }

        // Find all stop_time entries for this trip, in sequence
        let entries = GTFSStaticDataLoader.shared.stopTimes
            .filter { $0.trip_id == trip.trip_id }
            .sorted { $0.stop_sequence < $1.stop_sequence }

        // Map to Stop models
        stops = entries.compactMap { entry in
            GTFSStaticDataLoader.shared.stops.first { $0.stop_id == entry.stop_id }
        }
    }
}
