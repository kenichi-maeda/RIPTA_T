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
    // Reuse your NextBusViewModel to get live bus coords:
    @StateObject private var vm = NextBusViewModel(
      route: Route(
        route_id: "dummy", route_short_name: "", route_long_name: "",
        route_type: 3, route_url: nil, route_color: nil, route_text_color: nil
      ),
      stop: Stop(
        stop_id: "dummy", stop_code: nil, stop_name: "",
        stop_desc: nil, stop_lat: 41.8236, stop_lon: -71.4222,
        zone_id: nil, stop_url: nil, location_type: 0,
        parent_station: nil, stop_associated_place: nil,
        wheelchair_boarding: nil
      ),
      direction: 0
    )

    @State private var cameraPosition = MapCameraPosition.region(
      MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 41.8236, longitude: -71.4222),
        span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
      )
    )

    var body: some View {
      ZStack {
        // 1) Full‐screen map with live‐bus markers
        Map(position: $cameraPosition) {
          ForEach(vm.busCoordinates.indices, id: \.self) { idx in
            let coord = vm.busCoordinates[idx]
            Marker("", coordinate: coord)
              .tint(.red)
          }
        }
        .ignoresSafeArea()

        // 2) “Locate me” button
        VStack {
          Spacer()
          HStack {
            Spacer()
            Button {
              // re-center; later you can plug in CLLocationManager
              cameraPosition = .region(
                MKCoordinateRegion(
                  center: CLLocationCoordinate2D(latitude: 41.8236, longitude: -71.4222),
                  span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                )
              )
            } label: {
              Image(systemName: "location.fill")
                .font(.title2)
                .padding()
                .background(.white.opacity(0.8))
                .clipShape(Circle())
            }
            .padding()
          }
        }
      }
      .onAppear {
        vm.fetchData()
      }
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
