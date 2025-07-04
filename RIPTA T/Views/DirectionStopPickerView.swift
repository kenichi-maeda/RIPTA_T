//
//  DirectionStopPickerView.swift
//  RIPTA T
//
//  Created by Kenichi Maeda on 6/22/25.
//

import SwiftUI

struct DirectionStopPickerView: View {
    let route: Route
    @StateObject private var vm: DirectionStopPickerViewModel

    init(route: Route) {
        self.route = route
        _vm = StateObject(wrappedValue: DirectionStopPickerViewModel(route: route))
    }

    var body: some View {
        VStack {
            // 1) Route header
            Text("Route \(route.route_short_name)")
                .font(.headline)
                .padding(.top)

            // 2) Direction picker
            Picker("Direction", selection: $vm.selectedDirection) {
                Text("Outbound").tag(0)
                Text("Inbound").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)

            // 3) Stop list
            List(vm.stops) { stop in
                NavigationLink(destination:
                    NextBusView(
                      route: route,
                      stop: stop,
                      direction: vm.selectedDirection
                    )
                ) {
                    Text(stop.stop_name)
                }
            }
        }
        .navigationTitle("Select a Stop")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DirectionStopPickerView_Previews: PreviewProvider {
    static var previews: some View {
        // Preview with a dummy route
        DirectionStopPickerView(route: Route(
            route_id: "1",
            route_short_name: "1",
            route_long_name: "Eddy St/Hope St/Benefit St",
            route_type: 3,
            route_url: nil,
            route_color: nil,
            route_text_color: nil
        ))
    }
}
