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
    private let db: DatabaseServiceProtocol

    init(db: DatabaseServiceProtocol) {
        self.db = db
    }

    convenience init(context: ModelContext) {
        self.init(db: SwiftDataDatabaseService(context: context))
    }

    func fetchFavorites() throws -> [Favorite] {
        try db.fetch(FetchDescriptor<Favorite>())
    }

    func addFavorite(id: String) throws {
        let favorite = Favorite(breedId: id)
        try db.insert(favorite)
    }

    func removeFavorite(id: String) throws {
        // Sem #Predicate: busca todos e filtra em memória
        let all = try db.fetch(FetchDescriptor<Favorite>())
        let matches = all.filter { $0.breedId == id }
        for fav in matches {
            try db.delete(fav)
        }
    }

    func isFavorite(id: String) -> Bool {
        let all = try? db.fetch(FetchDescriptor<Favorite>())
        return all?.contains(where: { $0.breedId == id }) ?? false
    }
}
