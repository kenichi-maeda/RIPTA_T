//
//  MapView.swift
//  RIPTA T
//
//  Created by Kenichi Maeda on 7/4/25.
//

import SwiftUI
import MapKit
import Combine

// MARK: –– Make VehicleRecord Identifiable

extension VehicleRecord: Identifiable {
    public var id: String { trip.trip_id }
}

// MARK: –– ViewModel

/// ViewModel that loads all GTFS shapes once, then polls for live vehicle positions.
final class MapViewModel: ObservableObject {
    /// Shape polylines for every route
    struct RouteShape: Identifiable {
        let id: String
        let color: Color
        let polyline: MKPolyline
    }

    @Published var routeShapes: [RouteShape] = []
    @Published var vehiclePositions: [VehicleRecord] = []

    private var timer: AnyCancellable?
    private var cancellables = Set<AnyCancellable>()

    init() {
        loadStaticShapes()
        fetchVehicles()
        // Refresh every 15s
        timer = Timer.publish(every: 15, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.fetchVehicles() }
    }

    private func loadStaticShapes() {
        let trips  = GTFSStaticDataLoader.shared.trips
        let shapes = GTFSStaticDataLoader.shared.shapePoints

        var out: [RouteShape] = []
        for route in GTFSStaticDataLoader.shared.routes {
            guard let sid = trips.first(where: { $0.route_id == route.route_id })?.shape_id
            else { continue }

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

/// A full-screen map showing *all* routes + live buses.
struct MapView: View {
    @StateObject private var vm = MapViewModel()

    /// Starts zoomed out over RI
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 41.7, longitude: -71.5),
            span: MKCoordinateSpan(latitudeDelta: 0.8, longitudeDelta: 0.8)
        )
    )

    var body: some View {
        ZStack {
            Map(position: $cameraPosition) {
                // 1) draw each route
                ForEach(vm.routeShapes) { rs in
                    MapPolyline(rs.polyline)
                        .stroke(rs.color, lineWidth: 3)
                }

                // 2) draw every live bus as a red marker
                ForEach(vm.vehiclePositions) { record in
                    let coord = CLLocationCoordinate2D(
                        latitude:  record.position.latitude,
                        longitude: record.position.longitude
                    )
                    Marker("", coordinate: coord)
                        .tint(.red)
                }
            }
            .ignoresSafeArea()

            // 3) recenter button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        cameraPosition = .region(
                            MKCoordinateRegion(
                                center: CLLocationCoordinate2D(latitude: 41.7,
                                                               longitude: -71.5),
                                span: MKCoordinateSpan(latitudeDelta: 0.8,
                                                       longitudeDelta: 0.8)
                            )
                        )
                    } label: {
                        Image(systemName: "location.fill")
                            .padding(8)
                            .background(Color.white.opacity(0.8))
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

// MARK: –– Color-from-hex Helper

extension Color {
    /// Create Color from 6-digit hex string (e.g. "FF00AA"), else nil
    init?(hex: String?) {
        guard
            let hex = hex?.trimmingCharacters(in: .whitespacesAndNewlines),
            hex.count == 6,
            let int = Int(hex, radix: 16)
        else { return nil }
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
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
