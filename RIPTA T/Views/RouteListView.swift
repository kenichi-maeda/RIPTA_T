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
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(vm.routes) { route in
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
                    .foregroundColor(Color(hex: route.route_text_color ?? "FFFFFF"))
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
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// Hex → Color helper (same as before)
private extension Color {
    init(hex: String) {
        var hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        if hex.count == 3 {
            hex = hex.map { "\($0)\($0)" }.joined()
        }
        let int = UInt64(hex, radix: 16) ?? 0x888888
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
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
