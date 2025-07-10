//
//  NextBusViewModel.swift
//  RIPTA T
//
//  Created by Kenichi Maeda on 6/22/25.
//

import Foundation
import Combine
import MapKit

struct Arrival: Identifiable {
    let id = UUID()
    let minutesUntil: Int
    let headsign: String
}

/// A little struct to hold each live bus’s position *and* its route number.
struct BusPosition: Identifiable {
    let id: String                     // trip_id
    let coordinate: CLLocationCoordinate2D
    let routeShortName: String
}

final class NextBusViewModel: ObservableObject {
    let route: Route
    let stop: Stop
    let direction: Int

    @Published var arrivals: [Arrival] = []
    @Published var busPositions: [BusPosition] = []

    private var timer: AnyCancellable?
    private var cancellables = Set<AnyCancellable>()

    init(route: Route, stop: Stop, direction: Int) {
        self.route = route
        self.stop = stop
        self.direction = direction

        fetchData()
        timer = Timer.publish(every: 15, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.fetchData() }
    }

    func fetchData() {
        let now = Date()

        // 1) static schedule: which trips serve this route+direction at this stop
        let todayTripIDs = GTFSStaticDataLoader.shared.trips
            .filter { $0.route_id == route.route_id && $0.direction_id == direction }
            .map(\.trip_id)

        let scheduledEntries = GTFSStaticDataLoader.shared.stopTimes
            .filter { todayTripIDs.contains($0.trip_id) && $0.stop_id == stop.stop_id }

        // 2) fetch realtime updates
        Publishers.Zip(
            RealtimeService.shared.fetchTripUpdates(),
            RealtimeService.shared.fetchVehiclePositions()
        )
        .receive(on: DispatchQueue.main)
        .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] updates, vehicles in
            guard let self = self else { return }

            // compute arrivals as before…
            let nextArrivals = scheduledEntries.compactMap { entry -> Arrival? in
                let tu = updates.first { $0.trip.trip_id == entry.trip_id }
                let delay = tu?.stop_time_update
                    .first { $0.stop_id == entry.stop_id }?
                    .arrival?.delay ?? 0

                let fmt = DateFormatter(); fmt.dateFormat = "HH:mm:ss"
                guard let sched = fmt.date(from: entry.arrival_time) else { return nil }
                let comps = Calendar.current.dateComponents([.hour, .minute, .second], from: sched)
                guard let scheduled = Calendar.current.date(
                    bySettingHour: comps.hour!,
                    minute: comps.minute!,
                    second: comps.second!,
                    of: now
                ) else { return nil }
                let predicted = scheduled.addingTimeInterval(TimeInterval(delay))
                let mins = max(0, Int(predicted.timeIntervalSince(now) / 60))

                let headsign = GTFSStaticDataLoader.shared.trips
                    .first(where: { $0.trip_id == entry.trip_id })?
                    .trip_headsign ?? ""

                return Arrival(minutesUntil: mins, headsign: headsign)
            }
            self.arrivals = nextArrivals.sorted { $0.minutesUntil < $1.minutesUntil }

            // build busPositions: only those matching route+direction
            let matched = vehicles.compactMap { veh -> BusPosition? in
                // 1) unwrap the optional realtime route_id
                guard let vehRoute = veh.trip.route_id,
                      vehRoute == self.route.route_id
                else { return nil }

                // 2) ensure static GTFS record matches direction
                guard let staticTrip = GTFSStaticDataLoader.shared.trips
                        .first(where: { $0.trip_id == veh.trip.trip_id }),
                      staticTrip.direction_id == self.direction
                else { return nil }

                // 3) find a nice short name (fallback to the route_id if needed)
                let shortName = GTFSStaticDataLoader.shared.routes
                    .first(where: { $0.route_id == vehRoute })?
                    .route_short_name
                    ?? vehRoute

                let coord = CLLocationCoordinate2D(
                    latitude:  veh.position.latitude,
                    longitude: veh.position.longitude
                )
                return BusPosition(id: veh.trip.trip_id,
                                   coordinate: coord,
                                   routeShortName: shortName)
            }

            self.busPositions = matched
        })
        .store(in: &cancellables)
    }
}
