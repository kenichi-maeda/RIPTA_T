//
//  NextBusView.swift
//  RIPTA T
//

import SwiftUI
import MapKit

// Tune this to control how much the gray background for the ETA list is inset from the sides.
private let ARRIVAL_BOX_SIDE_INSET: CGFloat = 0   // 0 = edge-to-edge
private let ETA_CHIP_WIDTH: CGFloat = 84

struct NextBusView: View {
    let route: Route
    let stop: Stop
    let direction: Int

    @EnvironmentObject private var favs: FavoritesManager
    @StateObject private var vm: NextBusViewModel
    @State private var cameraPosition: MapCameraPosition
    @State private var mapExpanded = false

    private let shapeCoords: [CLLocationCoordinate2D]
    private var routePolyline: MKPolyline? {
        guard !shapeCoords.isEmpty else { return nil }
        return MKPolyline(coordinates: shapeCoords, count: shapeCoords.count)
    }

    init(route: Route, stop: Stop, direction: Int) {
        self.route = route
        self.stop = stop
        self.direction = direction

        _vm = StateObject(wrappedValue: NextBusViewModel(
            route: route, stop: stop, direction: direction
        ))

        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: stop.stop_lat,
                                           longitude: stop.stop_lon),
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        )
        _cameraPosition = State(wrappedValue: .region(region))

        if let sid = GTFSStaticDataLoader.shared.trips
            .first(where: { $0.route_id == route.route_id && $0.direction_id == direction })?
            .shape_id
        {
            let pts = GTFSStaticDataLoader.shared.shapePoints
                .filter { $0.shape_id == sid }
                .sorted { $0.shape_pt_sequence < $1.shape_pt_sequence }
            shapeCoords = pts.map {
                CLLocationCoordinate2D(latitude: $0.shape_pt_lat,
                                       longitude: $0.shape_pt_lon)
            }
        } else {
            shapeCoords = []
        }
    }

    var body: some View {
        let favKey = FavoriteItem(routeID: route.route_id,
                                  stopID:  stop.stop_id,
                                  direction: direction)
        let upcoming = vm.arrivals.filter { $0.minutesUntil > 0 }

        VStack(spacing: 18) {
            // Stop name centered
            Text(stop.stop_name)
                .font(.title.bold())
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, 12)

            // Route / Direction bar
            RouteDirectionBar(route: route, direction: direction)

            // Map section
            MapSection(mapExpanded: $mapExpanded,
                       cameraPosition: $cameraPosition,
                       routePolyline: routePolyline,
                       stop: stop,
                       busPositions: vm.busPositions)

            // Arrivals section
            if upcoming.isEmpty {
                EmptyArrivalsCard()
                Spacer()
            } else {
                ArrivalsSection(arrivals: Array(upcoming.prefix(5)))
            }
        }
        .padding(.horizontal)
        .navigationTitle("Next Buses")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    favs.isFavorite(favKey) ? favs.remove(favKey) : favs.add(favKey)
                } label: {
                    Image(systemName: favs.isFavorite(favKey) ? "star.fill" : "star")
                }
            }
        }
    }
}

// MARK: - Header bar

private struct RouteDirectionBar: View {
    let route: Route
    let direction: Int

    var body: some View {
        HStack {
            Spacer()
            HStack(spacing: 12) {
                // Colored circle with route #
                ZStack {
                    Circle()
                        .fill(routeColor)
                        .frame(width: 42, height: 42)
                    Text(route.route_short_name)
                        .font(.headline.bold())
                        .foregroundColor(routeTextColor)
                }

                // Direction tag
                HStack(spacing: 6) {
                    Image(systemName: direction == 0
                          ? "arrowshape.turn.up.right.fill"
                          : "arrowshape.turn.up.left.fill")
                    Text(direction == 0 ? "Outbound" : "Inbound")
                        .font(.subheadline.bold())
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(Color.gray.opacity(0.18))
                .clipShape(Capsule())
            }
            Spacer()
        }
    }


    private var routeColor: Color {
        Color(hex: route.route_color ?? "888888")
    }
    private var routeTextColor: Color {
        Color(hex: route.route_text_color ?? "FFFFFF")
    }
}

// MARK: - Map

private struct MapSection: View {
    @Binding var mapExpanded: Bool
    @Binding var cameraPosition: MapCameraPosition

    let routePolyline: MKPolyline?
    let stop: Stop
    let busPositions: [BusPosition]

    var body: some View {
        let height: CGFloat = mapExpanded ? 450 : 250

        Map(position: $cameraPosition) {
            if let poly = routePolyline {
                MapPolyline(poly).stroke(.gray, lineWidth: 4)
            }

            Marker("", coordinate: CLLocationCoordinate2D(
                latitude: stop.stop_lat, longitude: stop.stop_lon
            )).tint(.blue)

            ForEach(busPositions) { bus in
                Marker(bus.routeShortName, coordinate: bus.coordinate)
                    .tint(.red)
            }
        }
        .frame(height: height)
        .cornerRadius(14)
        .overlay(alignment: .topTrailing) {
            Button {
                withAnimation(.spring()) { mapExpanded.toggle() }
            } label: {
                Image(systemName: mapExpanded ? "chevron.down.circle.fill" :
                                                "chevron.up.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.black.opacity(0.35))
                    .clipShape(Circle())
                    .padding(8)
            }
        }
        .onTapGesture {
            withAnimation(.spring()) { mapExpanded.toggle() }
        }
    }
}

// MARK: - Arrivals

private struct ArrivalsSection: View {
    let arrivals: [Arrival]

    var body: some View {
        // Gray box “container”
        VStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(arrivals) { arr in
                        ArrivalRow(arrival: arr)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 4)
            }
        }
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal, ARRIVAL_BOX_SIDE_INSET)
    }
}

private struct ArrivalRow: View {
    let arrival: Arrival

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ETAChip(minutes: arrival.minutesUntil)
                .frame(width: ETA_CHIP_WIDTH, alignment: .leading)

            VStack(alignment: .leading, spacing: 3) {
                Text(arrival.headsign)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(2)

                Text("≈ \(etaClockString(for: arrival.minutesUntil))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }

    private func etaClockString(for minutes: Int) -> String {
        let date = Date().addingTimeInterval(Double(minutes) * 60)
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: date)
    }
}

private struct ETAChip: View {
    let minutes: Int

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 1) {
            Text("\(minutes)")
                .font(.title3.bold())
                .monospacedDigit()
            Text("min")
                .font(.caption2.bold())
        }
        .foregroundColor(.white)
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(badgeGradient(for: minutes))
        .clipShape(Capsule())
    }

    private func badgeGradient(for m: Int) -> LinearGradient {
        let colors: [Color]
        switch m {
        case ...1:   colors = [.red, .pink]
        case 2...4:  colors = [.orange, .yellow]
        default:     colors = [.green, .mint]
        }
        return LinearGradient(colors: colors,
                              startPoint: .topLeading,
                              endPoint: .bottomTrailing)
    }
}

// MARK: - Empty state

private struct EmptyArrivalsCard: View {
    var body: some View {
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
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .padding(.horizontal)
    }
}

// MARK: - Hex helper

private extension Color {
    init(hex: String) {
        var hexString = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        if hexString.count == 3 {
            hexString = hexString.map { "\($0)\($0)" }.joined()
        }
        let int = UInt64(hexString, radix: 16) ?? 0x888888
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
