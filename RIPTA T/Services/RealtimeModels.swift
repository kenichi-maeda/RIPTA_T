//
//  RealtimeModels.swift
//  RIPTA T
//
//  Created by Kenichi Maeda on 6/23/25.
//

import Foundation

// MARK: –– Trip Updates

struct TripUpdatesResponse: Decodable {
    let entity: [TripUpdateEntity]
}

struct TripUpdateEntity: Decodable {
    let trip_update: TripUpdate
}

struct TripUpdate: Decodable {
    let trip: TripDescriptor
    let stop_time_update: [StopTimeUpdate]
}

struct StopTimeUpdate: Decodable {
    let stop_sequence: Int
    let arrival: DelayInfo?
    let departure: DelayInfo?
    let stop_id: String
}

struct DelayInfo: Decodable {
    let delay: Int
}

// MARK: –– Vehicle Positions

struct VehiclePositionsResponse: Decodable {
    let entity: [VehicleEntity]
}

struct VehicleEntity: Decodable {
    let vehicle: VehicleRecord
}

struct VehicleRecord: Decodable {
    let trip: TripDescriptor
    let position: Position
}

struct Position: Decodable {
    let latitude: Double
    let longitude: Double
}

// MARK: –– Trip Descriptor (with route_id)

/// This replaces your old `TripIDOnly`.
struct TripDescriptor: Decodable {
    let trip_id: String
    let route_id: String?            // NEW
    let start_time: String?          // NEW
    let start_date: String?          // NEW
    let schedule_relationship: Int?  // NEW

    private enum CodingKeys: String, CodingKey {
        case trip_id
        case route_id
        case start_time
        case start_date
        case schedule_relationship
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        trip_id               = try c.decode(String.self,   forKey: .trip_id)
        route_id              = try? c.decode(String.self,   forKey: .route_id)
        start_time            = try? c.decode(String.self,   forKey: .start_time)
        start_date            = try? c.decode(String.self,   forKey: .start_date)
        schedule_relationship = try? c.decode(Int.self,      forKey: .schedule_relationship)
    }
}
