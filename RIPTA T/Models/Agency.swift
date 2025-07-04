//
//  Agency.swift
//  RIPTA T
//
//  Created by Kenichi Maeda on 6/22/25.
//
import Foundation

struct Agency: Identifiable {
    let agency_id: String
    let agency_name: String
    let agency_url: URL
    let agency_timezone: String
    let agency_lang: String?
    let agency_phone: String?
    var id: String { agency_id }
}
