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

final class NextBusViewModel: ObservableObject {
    let route: Route
    let stop: Stop
    let direction: Int

    @Published var arrivals: [Arrival] = []
    @Published var busCoordinates: [CLLocationCoordinate2D] = []

    private var timer: AnyCancellable?
    private var cancellables = Set<AnyCancellable>()

    init(route: Route, stop: Stop, direction: Int) {
        self.route = route
        self.stop = stop
        self.direction = direction

        // fire immediately and then every 15s
        fetchData()
        timer = Timer.publish(every: 15, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.fetchData()
            }
    }

    func fetchData() {
        let now = Date()

        // 1) scheduled trips for this route+direction at this stop
        let todayTrips = GTFSStaticDataLoader.shared.trips
            .filter { $0.route_id == route.route_id && $0.direction_id == direction }
            .map(\.trip_id)

        let scheduledEntries = GTFSStaticDataLoader.shared.stopTimes
            .filter { todayTrips.contains($0.trip_id) && $0.stop_id == stop.stop_id }

        // 2) pull down RT updates + vehicle positions
        Publishers.Zip(
            RealtimeService.shared.fetchTripUpdates(),
            RealtimeService.shared.fetchVehiclePositions()
        )
        .receive(on: DispatchQueue.main)
        .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] updates, vehicles in
            guard let self = self else { return }

            // compute arrivals as before
            let nextArrivals: [Arrival] = scheduledEntries.compactMap { entry in
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
                let minutes = max(0, Int(predicted.timeIntervalSince(now) / 60))

                let headsign = GTFSStaticDataLoader.shared.trips
                    .first(where: { $0.trip_id == entry.trip_id })?
                    .trip_headsign ?? ""

                return Arrival(minutesUntil: minutes, headsign: headsign)
            }
            self.arrivals = nextArrivals.sorted { $0.minutesUntil < $1.minutesUntil }

            // collect *all* vehicles that match both route_id and static direction
            let matching = vehicles.filter { vehicle in
                guard vehicle.trip.route_id == self.route.route_id else { return false }
                guard let staticTrip = GTFSStaticDataLoader.shared.trips
                        .first(where: { $0.trip_id == vehicle.trip.trip_id })
                else { return false }
                return staticTrip.direction_id == self.direction
            }

            self.busCoordinates = matching.map {
                CLLocationCoordinate2D(
                    latitude:  $0.position.latitude,
                    longitude: $0.position.longitude
                )
            }
        })
        .store(in: &cancellables)
    }
}
