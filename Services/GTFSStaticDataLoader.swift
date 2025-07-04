//
//  GTFSStaticDataLoader.swift
//  RIPTA T
//
//  Created by Kenichi Maeda on 6/22/25.
//

import Foundation

final class GTFSStaticDataLoader {
    static let shared = GTFSStaticDataLoader()

    let agencies:      [Agency]
    let routes:        [Route]
    let trips:         [Trip]
    let stops:         [Stop]
    let stopTimes:     [StopTime]
    let calendarDates: [CalendarDate]
    let feedInfo:      [FeedInfo]
    let routeTimepoints:[RouteTimepoint]
    let shapePoints:   [ShapePoint]

    private init() {
        agencies        = Self.loadCSV("agency",          ext: "txt", subdirectory: "GTFS", parser: GTFSStaticDataLoader.parseAgency)
        routes          = Self.loadCSV("routes",          ext: "txt", subdirectory: "GTFS", parser: GTFSStaticDataLoader.parseRoute)
        trips           = Self.loadCSV("trips",           ext: "txt", subdirectory: "GTFS", parser: GTFSStaticDataLoader.parseTrip)
        stops           = Self.loadCSV("stops",           ext: "txt", subdirectory: "GTFS", parser: GTFSStaticDataLoader.parseStop)
        stopTimes       = Self.loadCSV("stop_times",      ext: "txt", subdirectory: "GTFS", parser: GTFSStaticDataLoader.parseStopTime)
        calendarDates   = Self.loadCSV("calendar_dates",  ext: "txt", subdirectory: "GTFS", parser: GTFSStaticDataLoader.parseCalendarDate)
        feedInfo        = Self.loadCSV("feed_info",       ext: "txt", subdirectory: "GTFS", parser: GTFSStaticDataLoader.parseFeedInfo)
        routeTimepoints = Self.loadCSV("route_timepoints",ext: "txt", subdirectory: "GTFS", parser: GTFSStaticDataLoader.parseRouteTimepoint)
        shapePoints     = Self.loadCSV("shapes",          ext: "txt", subdirectory: "GTFS", parser: GTFSStaticDataLoader.parseShapePoint)
    }

    private static func loadCSV<T>(
        _ resource: String,
        ext: String,
        subdirectory: String?,
        parser: (String) -> T?
    ) -> [T] {
        guard let url = Bundle.main.url(
                forResource: resource,
                withExtension: ext,
                subdirectory: subdirectory),
              let content = try? String(contentsOf: url, encoding: .utf8)
        else {
            fatalError("Missing or unreadable \(resource).\(ext) in \(subdirectory ?? "bundle root")")
        }

        return content
            .components(separatedBy: .newlines)
            .dropFirst()              // skip header
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .compactMap(parser)
    }

    // MARK: –– CSV Line Parser

    private static func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var field = ""
        var inQuotes = false

        for char in line {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                fields.append(field.trimmingCharacters(in: .whitespaces))
                field = ""
            } else {
                field.append(char)
            }
        }

        fields.append(field.trimmingCharacters(in: .whitespaces))
        return fields
    }

    // MARK: –– Parsers

    private static func parseAgency(_ line: String) -> Agency? {
        let f = parseCSVLine(line)
        guard f.count >= 6,
              let url = URL(string: f[2])
        else { return nil }

        return Agency(
            agency_id:       f[0],
            agency_name:     f[1],
            agency_url:      url,
            agency_timezone: f[3],
            agency_lang:     f[4].isEmpty ? nil : f[4],
            agency_phone:    f[5].isEmpty ? nil : f[5]
        )
    }

    private static func parseRoute(_ line: String) -> Route? {
        let f = parseCSVLine(line)
        guard f.count >= 8 else { return nil }
        return Route(
            route_id:         f[0],
            route_short_name: f[1],
            route_long_name:  f[2],
            route_type:       Int(f[4]) ?? 0,
            route_url:        URL(string: f[5]),
            route_color:      f[6].isEmpty ? nil : f[6],
            route_text_color: f[7].isEmpty ? nil : f[7]
        )
    }

    private static func parseTrip(_ line: String) -> Trip? {
        let f = parseCSVLine(line)
        guard f.count >= 7 else { return nil }
        return Trip(
            route_id:      f[0],
            service_id:    f[1],
            trip_id:       f[2],
            trip_headsign: f[3],
            direction_id:  Int(f[4]) ?? 0,
            block_id:      f[5].isEmpty ? nil : f[5],
            shape_id:      f[6].isEmpty ? nil : f[6]
        )
    }

    private static func parseStop(_ line: String) -> Stop? {
        let f = parseCSVLine(line)
        guard f.count >= 11 else { return nil }
        return Stop(
            stop_id:               f[0],
            stop_code:             f[1].isEmpty ? nil : f[1],
            stop_name:             f[2],
            stop_desc:             f[3].isEmpty ? nil : f[3],
            stop_lat:              Double(f[4]) ?? 0,
            stop_lon:              Double(f[5]) ?? 0,
            zone_id:               f[6].isEmpty ? nil : f[6],
            stop_url:              f[7].isEmpty ? nil : f[7],
            location_type:         Int(f[8]),
            parent_station:        f[9].isEmpty ? nil : f[9],
            stop_associated_place: f[10].isEmpty ? nil : f[10],
            wheelchair_boarding:   f.count > 11 ? Int(f[11]) : nil
        )
    }

    private static func parseStopTime(_ line: String) -> StopTime? {
        let f = parseCSVLine(line)
        guard f.count >= 7 else { return nil }
        return StopTime(
            trip_id:       f[0],
            arrival_time:  f[1],
            departure_time:f[2],
            stop_id:       f[3],
            stop_sequence: Int(f[4]) ?? 0,
            pickup_type:   Int(f[5]),
            drop_off_type: Int(f[6])
        )
    }

    private static func parseCalendarDate(_ line: String) -> CalendarDate? {
        let f = parseCSVLine(line)
        guard f.count >= 3 else { return nil }
        return CalendarDate(
            service_id:     f[0],
            date:           f[1],
            exception_type: Int(f[2]) ?? 0
        )
    }

    private static func parseFeedInfo(_ line: String) -> FeedInfo? {
        let f = parseCSVLine(line)
        guard f.count >= 6 else { return nil }
        return FeedInfo(
            feed_publisher_name: f[0],
            feed_publisher_url:  f[1],
            feed_lang:           f[2].isEmpty ? nil : f[2],
            feed_start_date:     f[3].isEmpty ? nil : f[3],
            feed_end_date:       f[4].isEmpty ? nil : f[4],
            feed_contact_email:  f[5].isEmpty ? nil : f[5],
            feed_contact_url:    f.count > 6 && !f[6].isEmpty ? f[6] : nil
        )
    }

    private static func parseRouteTimepoint(_ line: String) -> RouteTimepoint? {
        let f = parseCSVLine(line)
        guard f.count >= 5 else { return nil }
        return RouteTimepoint(
            route_id:       f[0],
            direction_label:f[1],
            stop_code:      f[2],
            stop_name:      f[3],
            stop_sequence:  Int(f[4]) ?? 0
        )
    }

    private static func parseShapePoint(_ line: String) -> ShapePoint? {
        let f = parseCSVLine(line)
        guard f.count >= 4 else { return nil }
        return ShapePoint(
            shape_id:          f[0],
            shape_pt_lat:      Double(f[1]) ?? 0,
            shape_pt_lon:      Double(f[2]) ?? 0,
            shape_pt_sequence: Int(f[3]) ?? 0
        )
    }
}







