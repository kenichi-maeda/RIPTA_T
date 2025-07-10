//
//  RouteListView.swift
//  RIPTA T
//
//  Created by Kenichi Maeda on 6/22/25.
//

import SwiftUI

struct RouteListView: View {
    @StateObject private var vm = RouteListViewModel()
    @State private var searchText = ""

    /// First we sort numerically by route_short_name (e.g. “1”, “2”, “10”),
    /// then alphabetically on the string if it isn’t a number.
    private var sortedRoutes: [Route] {
        vm.routes.sorted { a, b in
            let ai = Int(a.route_short_name)
            let bi = Int(b.route_short_name)
            switch (ai, bi) {
            case let (x?, y?):           return x < y
            case (_?, nil):              return true
            case (nil, _?):              return false
            default:                     return a.route_short_name < b.route_short_name
            }
        }
    }

    /// Apply the search filter on short or long name
    private var filteredRoutes: [Route] {
        guard !searchText.isEmpty else { return sortedRoutes }
        return sortedRoutes.filter {
            $0.route_short_name.localizedCaseInsensitiveContains(searchText)
            || $0.route_long_name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(filteredRoutes) { route in
                    NavigationLink {
                        DirectionStopPickerView(route: route)
                    } label: {
                        RouteCard(route: route)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .navigationTitle("Select a Route")
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always)) {
            // Optional: recent searches or suggestions
        }
    }
}

private struct RouteCard: View {
    let route: Route

    var body: some View {
        HStack(spacing: 16) {
            // Colored circle with short name
            ZStack {
                Circle()
                    .fill(Color(hex: route.route_color ?? "888888"))
                    .frame(width: 50, height: 50)
                Text(route.route_short_name)
                    .font(.headline)
                    .foregroundColor(.white)
            }

            // Long name
            Text(route.route_long_name)
                .font(.subheadline)
                .foregroundColor(.primary)
                .lineLimit(2)

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 12)
        .padding(.horizontal)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: –– Hex → Color helper

private extension Color {
    init(hex: String) {
        var hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        if hex.count == 3 {
            hex = hex.map { "\($0)\($0)" }.joined()
        }
        let int = UInt64(hex, radix: 16) ?? 0x888888
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >>  8) & 0xFF) / 255
        let b = Double( int        & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

struct RouteListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            RouteListView()
        }
    }
}
