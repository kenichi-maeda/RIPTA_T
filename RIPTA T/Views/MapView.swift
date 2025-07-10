//
//  MapView.swift
//  RIPTA T
//
//  Created by Kenichi Maeda on 7/4/25.
//

import SwiftUI
import MapKit
import Combine
import CoreLocation

// MARK: –– Make VehicleRecord Identifiable

extension VehicleRecord: Identifiable {
    public var id: String { trip.trip_id }
}

// MARK: –– ViewModel

/// Loads all GTFS shapes once, polls live vehicle positions,
/// and keeps track of the user’s location.
final class MapViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    struct RouteShape: Identifiable {
        let id: String
        let color: Color
        let polyline: MKPolyline
    }

    @Published var routeShapes: [RouteShape] = []
    @Published var vehiclePositions: [VehicleRecord] = []
    @Published var userLocation: CLLocationCoordinate2D?

    private let locationManager = CLLocationManager()
    private var cancellables = Set<AnyCancellable>()
    private var timer: AnyCancellable?

    override init() {
        super.init()
        // 1) Location setup
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()

        // 2) Load static GTFS shapes
        loadStaticShapes()

        // 3) Fetch vehicles now + every 15s
        fetchVehicles()
        timer = Timer.publish(every: 15, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.fetchVehicles() }
    }

    // CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locs: [CLLocation]) {
        userLocation = locs.last?.coordinate
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("🔴 Location error:", error)
    }

    private func loadStaticShapes() {
        let trips  = GTFSStaticDataLoader.shared.trips
        let shapes = GTFSStaticDataLoader.shared.shapePoints
        var out: [RouteShape] = []

        for route in GTFSStaticDataLoader.shared.routes {
            guard let sid = trips.first(where: { $0.route_id == route.route_id })?.shape_id else {
                continue
            }
            let pts = shapes
                .filter { $0.shape_id == sid }
                .sorted { $0.shape_pt_sequence < $1.shape_pt_sequence }
            guard !pts.isEmpty else { continue }

            let coords = pts.map {
                CLLocationCoordinate2D(latitude:  $0.shape_pt_lat,
                                       longitude: $0.shape_pt_lon)
            }
            let poly = MKPolyline(coordinates: coords, count: coords.count)
            let c = Color(hex: route.route_color) ?? .gray
            out.append(RouteShape(id: route.route_id, color: c, polyline: poly))
        }

        routeShapes = out
    }

    private func fetchVehicles() {
        RealtimeService.shared.fetchVehiclePositions()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] vehicles in
                    self?.vehiclePositions = vehicles
                }
            )
            .store(in: &cancellables)
    }
}

// MARK: –– MapView

struct MapView: View {
    @StateObject private var vm = MapViewModel()

    /// Default zoomed-out region over RI
    private let defaultRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 41.7, longitude: -71.5),
        span: MKCoordinateSpan(latitudeDelta: 0.8, longitudeDelta: 0.8)
    )

    @State private var cameraPosition: MapCameraPosition

    init() {
        // start at the default region
        _cameraPosition = State(wrappedValue: .region(defaultRegion))
    }

    var body: some View {
        ZStack {
            // — The map itself —
            Map(position: $cameraPosition) {
                // 1) Route polylines
                ForEach(vm.routeShapes) { rs in
                    MapPolyline(rs.polyline)
                        .stroke(rs.color, lineWidth: 3)
                }

                // 2) Live buses
                ForEach(vm.vehiclePositions) { record in
                    let coord = CLLocationCoordinate2D(
                        latitude:  record.position.latitude,
                        longitude: record.position.longitude
                    )
                    Marker(record.trip.route_id ?? "?",
                           coordinate: coord)
                        .tint(.red)
                }

                // 3) User location
                if let userLoc = vm.userLocation {
                    Marker("", coordinate: userLoc)
                        .tint(.blue)
                }
            }
            .ignoresSafeArea()

            // — “Locate Me” button —
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        if let userLoc = vm.userLocation {
                            cameraPosition = .region(
                                MKCoordinateRegion(
                                    center: userLoc,
                                    span: MKCoordinateSpan(
                                        latitudeDelta: 0.02,
                                        longitudeDelta: 0.02
                                    )
                                )
                            )
                        } else {
                            cameraPosition = .region(defaultRegion)
                        }
                    } label: {
                        Image(systemName: "location.fill")
                            .font(.title2)
                            .padding(10)
                            .background(.white.opacity(0.8))
                            .clipShape(Circle())
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Map")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: –– Hex→Color Helper

extension Color {
    /// Create a Color from a 6-digit hex string (e.g. "FF00AA").
    init?(hex: String?) {
        guard
            let hex = hex?.trimmingCharacters(in: .whitespacesAndNewlines),
            hex.count == 6,
            let int = Int(hex, radix: 16)
        else { return nil }
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >>  8) & 0xFF) / 255
        let b = Double(int         & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            MapView()
        }
    }
}
