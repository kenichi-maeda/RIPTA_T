//
//  FavoritesManager.swift
//  RIPTA T
//
//  Created by Kenichi Maeda on 7/3/25.
//

import Foundation
import Combine

/// Persists favorites to UserDefaults as JSON
final class FavoritesManager: ObservableObject {
    @Published private(set) var favorites: [FavoriteItem] = []

    private let key = "favorites"
    private var cancellables = Set<AnyCancellable>()

    init() {
        load()
        // Auto-save whenever `favorites` changes
        $favorites
          .sink { [weak self] _ in self?.save() }
          .store(in: &cancellables)
    }

    func isFavorite(_ item: FavoriteItem) -> Bool {
        favorites.contains(item)
    }

    func add(_ item: FavoriteItem) {
        guard !favorites.contains(item) else { return }
        favorites.append(item)
    }

    func remove(_ item: FavoriteItem) {
        favorites.removeAll { $0 == item }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([FavoriteItem].self, from: data)
        else { return }
        favorites = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(favorites) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
