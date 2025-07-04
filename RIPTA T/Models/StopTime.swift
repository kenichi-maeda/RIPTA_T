//
//  StopTime.swift
//  RIPTA T
//
//  Created by Kenichi Maeda on 6/22/25.
//


struct StopTime {
    let trip_id: String
    let arrival_time: String   // “HH:MM:SS”
    let departure_time: String
    let stop_id: String
    let stop_sequence: Int
    let pickup_type: Int?      // 0=regular, …
    let drop_off_type: Int?
}
