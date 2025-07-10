//
//  NextBusView.swift
//  RIPTA T
//
//  Created by Kenichi Maeda on 6/22/25.
//

import SwiftUI
import MapKit

struct NextBusView: View {
    let route: Route
    let stop: Stop
    let direction: Int

    @EnvironmentObject private var favs: FavoritesManager
    @StateObject private var vm: NextBusViewModel
    @State private var cameraPosition: MapCameraPosition

    /// Raw shape coordinates from GTFS
    private let shapeCoords: [CLLocationCoordinate2D]

    /// Prebuilt MKPolyline for the route
    private var routePolyline: MKPolyline? {
        guard !shapeCoords.isEmpty else { return nil }
        return MKPolyline(coordinates: shapeCoords,
                          count: shapeCoords.count)
    }

    init(route: Route, stop: Stop, direction: Int) {
        self.route = route
        self.stop = stop
        self.direction = direction

        _vm = StateObject(wrappedValue: NextBusViewModel(
            route: route, stop: stop, direction: direction
        ))

        // Center map on the chosen stop
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: stop.stop_lat,
                longitude: stop.stop_lon
            ),
            span: MKCoordinateSpan(latitudeDelta: 0.02,
                                   longitudeDelta: 0.02)
        )
        _cameraPosition = State(wrappedValue: .region(region))

        // Pull out the GTFS shape for this route+direction
        if let sid = GTFSStaticDataLoader.shared.trips
            .first(where: {
                $0.route_id == route.route_id &&
                $0.direction_id == direction
            })?
            .shape_id
        {
            let pts = GTFSStaticDataLoader.shared.shapePoints
                .filter { $0.shape_id == sid }
                .sorted { $0.shape_pt_sequence < $1.shape_pt_sequence }
            shapeCoords = pts.map {
                CLLocationCoordinate2D(
                  latitude:  $0.shape_pt_lat,
                  longitude: $0.shape_pt_lon
                )
            }
        } else {
            shapeCoords = []
        }
    }

    var body: some View {
        // Build the FavoriteItem for this context
        let me = FavoriteItem(
            routeID:   route.route_id,
            stopID:    stop.stop_id,
            direction: direction
        )

        // Only arrivals > 0 minutes
        let upcoming = vm.arrivals.filter { $0.minutesUntil > 0 }

        VStack(spacing: 16) {
            // 1) Stop name
            Text(stop.stop_name)
                .font(.largeTitle)
                .bold()

            // 2) Route + direction banner
            HStack {
                Text("Route \(route.route_short_name)").bold()
                Text("·")
                Text(direction == 0 ? "Outbound" : "Inbound")
            }
            .padding(.vertical, 8)
            .padding(.horizontal)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(8)

            // 3) Map: route polyline + stop pin + all live buses
            Map(position: $cameraPosition) {
                // Route line
                if let poly = routePolyline {
                    MapPolyline(poly)
                        .stroke(Color.gray, lineWidth: 4)
                }
                // Selected stop
                Marker("", coordinate:
                    CLLocationCoordinate2D(
                        latitude:  stop.stop_lat,
                        longitude: stop.stop_lon
                    )
                )
                .tint(.blue)

                // All live buses (with their route short‐name)
                ForEach(vm.busPositions) { bus in
                    Marker(bus.routeShortName, coordinate: bus.coordinate)
                        .tint(.red)
                }
            }
            .frame(height: 200)
            .cornerRadius(12)

            // 4) Arrivals / Empty‐state
            if upcoming.isEmpty {
                HStack {
                    Image(systemName: "bus")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No upcoming buses")
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, minHeight: 80)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05),
                        radius: 2, x: 0, y: 1)
                .padding(.horizontal)

                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(upcoming.prefix(5)) { arrival in
                            HStack {
                                Text("\(arrival.minutesUntil) min")
                                    .bold()
                                    .frame(width: 60,
                                           alignment: .leading)
                                Text(arrival.headsign)
                                    .frame(maxWidth: .infinity,
                                           alignment: .leading)
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.05),
                                    radius: 2, x: 0, y: 1)
                        }
                    }
                    .padding()
                }
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
            }
        }
        .padding(.horizontal)
        .navigationTitle("Next Buses")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    if favs.isFavorite(me) { favs.remove(me) }
                    else                   { favs.add(me)    }
                } label: {
                    Image(systemName:
                        favs.isFavorite(me)
                        ? "star.fill" : "star"
                    )
                }
            }
        }
    }
}

struct NextBusView_Previews: PreviewProvider {
    static var previews: some View {
        let dummyRoute = Route(
            route_id:          "20",
            route_short_name:  "20",
            route_long_name:   "Elmwood Ave/Airport",
            route_type:        3,
            route_url:         nil,
            route_color:       nil,
            route_text_color:  nil
        )
        let dummyStop = Stop(
            stop_id:               "24725",
            stop_code:             "24725",
            stop_name:             "Elmwood after Post",
            stop_desc:             nil,
            stop_lat:              41.8345,
            stop_lon:              -71.4155,
            zone_id:               nil,
            stop_url:              nil,
            location_type:         0,
            parent_station:        nil,
            stop_associated_place: nil,
            wheelchair_boarding:   nil
        )
        NavigationStack {
            NextBusView(route: dummyRoute, stop: dummyStop, direction: 0)
                .environmentObject(FavoritesManager())
        }
    }
}
