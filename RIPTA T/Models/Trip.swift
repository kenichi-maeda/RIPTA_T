//
//  Trip.swift
//  RIPTA T
//
//  Created by Kenichi Maeda on 6/22/25.
//

struct Trip: Identifiable {
    let route_id: String
    let service_id: String
    let trip_id: String
    let trip_headsign: String
    let direction_id: Int    // 0 or 1
    let block_id: String?
    let shape_id: String?
    var id: String { trip_id }
}
