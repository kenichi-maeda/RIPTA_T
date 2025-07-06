//
//  MapView.swift
//  RIPTA T
//
//  Created by Kenichi Maeda on 6/22/25.
//

// Views/MapView.swift

import SwiftUI
import MapKit

struct MapView: View {
    // We supply a “dummy” route/stop/direction here,
    // but you can later swap in something dynamic or
    // let the user pick which route they want to see on the map.
    @StateObject private var vm = NextBusViewModel(
      route: Route(
        route_id: "1",
        route_short_name: "1",
        route_long_name: "Eddy St/Hope St/Benefit St",
        route_type: 3,
        route_url: nil,
        route_color: nil,
        route_text_color: nil
      ),
      stop: Stop(
        stop_id: "24725",
        stop_code: "24725",
        stop_name: "Elmwood after Post",
        stop_desc: nil,
        stop_lat: 41.8345,
        stop_lon: -71.4155,
        zone_id: nil,
        stop_url: nil,
        location_type: 0,
        parent_station: nil,
        stop_associated_place: nil,
        wheelchair_boarding: nil
      ),
      direction: 0
    )

    // Start centered on Providence
    @State private var cameraPosition = MapCameraPosition.region(
      MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 41.8236, longitude: -71.4222),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
      )
    )

    var body: some View {
      ZStack {
        // 1) Full‐screen live‐bus map
        Map(position: $cameraPosition) {
          ForEach(vm.busCoordinates.indices, id: \.self) { idx in
            let coord = vm.busCoordinates[idx]
            Marker("", coordinate: coord)
              .tint(.red)
          }
        }
        .ignoresSafeArea()

        // 2) “Locate me” button in corner
        VStack {
          Spacer()
          HStack {
            Spacer()
            Button {
              // hard-coded recenter; swap in CoreLocation later
              cameraPosition = .region(
                MKCoordinateRegion(
                  center: CLLocationCoordinate2D(latitude: 41.8236, longitude: -71.4222),
                  span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
              )
            } label: {
              Image(systemName: "location.fill")
                .font(.title2)
                .padding(8)
                .background(Color.white.opacity(0.8))
                .clipShape(Circle())
            }
            .padding()
          }
        }
      }
      .onAppear { vm.fetchData() }
      .navigationTitle("Live Map")
      .navigationBarTitleDisplayMode(.inline)
    }
}

struct MapView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      MapView()
    }
  }
}

