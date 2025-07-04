//
//  RouteListView.swift
//  RIPTA T
//
//  Created by Kenichi Maeda on 6/22/25.
//

import SwiftUI

struct RouteListView: View {
    @StateObject private var vm = RouteListViewModel()
    
    var body: some View {
        NavigationView {
            List(vm.routes, id: \.route_id) { route in
                NavigationLink(destination: DirectionStopPickerView(route: route)) {
                    HStack {
                        Text(route.route_short_name)
                            .font(.headline)
                        Text(route.route_long_name)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Select a Route")
        }
    }
}

struct RouteListView_Previews: PreviewProvider {
    static var previews: some View {
        RouteListView()
    }
}
