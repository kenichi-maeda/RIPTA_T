//
//  FavoritesView.swift
//  RIPTA T
//
//  Created by Kenichi Maeda on 7/3/25.
//

import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject var favs: FavoritesManager

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Empty state
                if favs.favorites.isEmpty {
                    Text("No Favorites Yet")
                        .foregroundColor(.secondary)
                        .padding(.top, 40)
                }

                // Favorite cards
                ForEach(favs.favorites) { item in
                    if
                        let route = GTFSStaticDataLoader.shared.routes.first(where: { $0.route_id == item.routeID }),
                        let stop  = GTFSStaticDataLoader.shared.stops.first(where: { $0.stop_id  == item.stopID })
                    {
                        NavigationLink {
                            NextBusView(route: route, stop: stop, direction: item.direction)
                                .environmentObject(favs)
                        } label: {
                            FavoriteCard(route: route, stop: stop, direction: item.direction)
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                favs.remove(item)
                            } label: {
                                Label("Remove", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Favorites")
    }
}

private struct FavoriteCard: View {
    let route: Route
    let stop: Stop
    let direction: Int

    var body: some View {
        HStack(spacing: 16) {
            // Route badge
            ZStack {
                Circle()
                    .fill(Color(hex: route.route_color ?? "888")) // default gray
                    .frame(width: 50, height: 50)
                Text(route.route_short_name)
                    .foregroundColor(Color(hex: route.route_text_color ?? "FFF"))
                    .font(.headline)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(stop.stop_name)
                    .font(.headline)
                Text(direction == 0 ? "Outbound" : "Inbound")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(4)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// Simple hex→Color initializer
private extension Color {
    init(hex: String) {
        var hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        if hex.count == 3 {
            hex = hex.map { "\($0)\($0)" }.joined()
        }
        let int = UInt64(hex, radix: 16) ?? 0x888888
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double( int        & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

struct FavoritesView_Previews: PreviewProvider {
    static var previews: some View {
        let fm = FavoritesManager()
        // Prepopulate one favorite for preview
        fm.add(.init(routeID: "20", stopID: "24725", direction: 0))

        return NavigationStack {
            FavoritesView()
                .environmentObject(fm)
        }
    }
}
