//
//  RealtimeService.swift
//  RIPTA T
//
//  Created by Kenichi Maeda on 6/22/25.
//

import Foundation
import Combine
import CoreLocation

final class RealtimeService {
    static let shared = RealtimeService()
    private init() {}

    private let baseURL = URL(string: "http://realtime.ripta.com:81/api")!
    private var decoder = JSONDecoder()

    /// Fetch live trip updates
    func fetchTripUpdates() -> AnyPublisher<[TripUpdate], Error> {
        let url = baseURL.appendingPathComponent("tripupdates")
            .appending(queryItems: [URLQueryItem(name: "format", value: "json")])
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: TripUpdatesResponse.self, decoder: decoder)
            .map { $0.entity.map(\.trip_update) }
            .eraseToAnyPublisher()
    }

    /// Fetch live vehicle positions
    func fetchVehiclePositions() -> AnyPublisher<[VehicleRecord], Error> {
        let url = baseURL.appendingPathComponent("vehiclepositions")
            .appending(queryItems: [URLQueryItem(name: "format", value: "json")])
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: VehiclePositionsResponse.self, decoder: decoder)
            .map { $0.entity.map(\.vehicle) }
            .eraseToAnyPublisher()
    }
}

// Helper to append query items
private extension URL {
    func appending(queryItems: [URLQueryItem]) -> URL {
        var c = URLComponents(url: self, resolvingAgainstBaseURL: false)!
        c.queryItems = (c.queryItems ?? []) + queryItems
        return c.url!
    }
}
