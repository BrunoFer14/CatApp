import Foundation
import SwiftData

protocol FavoritesRepositoryProtocol {
    func fetchFavorites() throws -> [Favorite]
    func addFavorite(id: String) throws
    func removeFavorite(id: String) throws
    func isFavorite(id: String) -> Bool
}

@MainActor
class FavoritesRepository: FavoritesRepositoryProtocol {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchFavorites() throws -> [Favorite] {
        try context.fetch(FetchDescriptor<Favorite>())
    }

    func addFavorite(id: String) throws {
        let favorite = Favorite(breedId: id)
        context.insert(favorite)
        try context.save()
    }

    func removeFavorite(id: String) throws {
        let predicate = #Predicate<Favorite> { $0.breedId == id }
        var descriptor = FetchDescriptor<Favorite>(predicate: predicate)
        descriptor.fetchLimit = 0 // sem limite; apaga todos os duplicados, se existirem

        let matches = try context.fetch(descriptor)
        for fav in matches {
            context.delete(fav)
        }
        if !matches.isEmpty {
            try context.save()
        }
    }

    func isFavorite(id: String) -> Bool {
        let predicate = #Predicate<Favorite> { $0.breedId == id }
        var descriptor = FetchDescriptor<Favorite>(predicate: predicate)
        descriptor.fetchLimit = 1

        let result = try? context.fetch(descriptor)
        return (result?.isEmpty == false)
    }
}
