//
//  DirectionStopPickerVM.swift
//  RIPTA T
//
//  Created by Kenichi Maeda on 6/22/25.
//

import SwiftUI

struct DirectionStopPickerView: View {
    let route: Route      // passed in from the RouteListView’s NavigationLink

    var body: some View {
        VStack {
            Text("Route \(route.route_short_name)")
                .font(.title2)
                .padding(.bottom)

            Text("Select direction and stop here")
                .foregroundColor(.secondary)
        }
        .navigationTitle("Stops")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DirectionStopPickerView_Previews: PreviewProvider {
    static var previews: some View {
        // Preview with a dummy Route
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
