//
//  Stop.swift
//  RIPTA T
//
//  Created by Kenichi Maeda on 6/22/25.
//

struct Stop: Identifiable {
    let stop_id: String
    let stop_code: String?
    let stop_name: String
    let stop_desc: String?
    let stop_lat: Double
    let stop_lon: Double
    let zone_id: String?
    let stop_url: String?
    let location_type: Int?
    let parent_station: String?
    let stop_associated_place: String?
    let wheelchair_boarding: Int?
    var id: String { stop_id }
}
