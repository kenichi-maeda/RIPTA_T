//
//  HomeView.swift
//  RIPTA T
//
//  Created by Kenichi Maeda on 7/3/25.
//

import SwiftUI

struct HomeView: View {
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                // Logo & title
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                Text("RIPTA T")
                    .font(.largeTitle)
                    .bold()
                Text("Real-time bus tracking")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                // Service grid
                LazyVGrid(columns: columns, spacing: 20) {
                    // By Route
                    NavigationLink {
                        RouteListView()
                    } label: {
                        ServiceTile(icon: "bus.fill", title: "By Route")
                    }

                    // Map view placeholder
                    NavigationLink {
                        Text("Map view coming soon")
                            .navigationTitle("Map")
                    } label: {
                        ServiceTile(icon: "map.fill", title: "Map")
                    }

                    // Favorites placeholder
                    NavigationLink {
                        FavoritesView()
                    } label: {
                        ServiceTile(icon: "star.fill", title: "Favorites")
                    }

                    // Settings placeholder
                    NavigationLink {
                        Text("Settings coming soon")
                            .navigationTitle("Settings")
                    } label: {
                        ServiceTile(icon: "gearshape.fill", title: "Settings")
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding()
            .navigationBarHidden(true)
        }
    }
}

struct ServiceTile: View {
    let icon: String
    let title: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(.blue)
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, minHeight: 120)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
