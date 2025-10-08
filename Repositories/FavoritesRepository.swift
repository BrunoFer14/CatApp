import Foundation
import SwiftData

/// Repositório para gerir favoritos no SwiftData.
protocol FavoritesRepositoryProtocol {
    func fetchFavorites() throws -> [Favorite]
    func addFavorite(id: String) throws
    func removeFavorite(id: String) throws
    func isFavorite(id: String) -> Bool
}

@MainActor
class FavoritesRepository: FavoritesRepositoryProtocol {
    private let db: DatabaseServiceProtocol

    // Injeta o serviço base (testável)
    init(db: DatabaseServiceProtocol) {
        self.db = db
    }

    // Conveniência se preferires passar ModelContext diretamente
    convenience init(context: ModelContext) {
        self.init(db: SwiftDataDatabaseService(context: context))
    }

    func fetchFavorites() throws -> [Favorite] {
        // Busca todos os favoritos
        try db.fetch(FetchDescriptor<Favorite>())
    }

    func addFavorite(id: String) throws {
        // Cria e guarda um favorito
        let favorite = Favorite(breedId: id)
        try db.insert(favorite)
    }

    func removeFavorite(id: String) throws {
        // Apaga favorito(s) com o mesmo breedId
        // Nota: #Predicate requer Swift 5.9+ (Xcode 15+)
        let predicate = #Predicate<Favorite> { $0.breedId == id }
        var descriptor = FetchDescriptor<Favorite>(predicate: predicate)
        descriptor.fetchLimit = 0

        let matches = try db.fetch(descriptor)
        for fav in matches {
            try db.delete(fav)
        }
    }

    func isFavorite(id: String) -> Bool {
        // Verifica se existe um favorito com esse ID
        let predicate = #Predicate<Favorite> { $0.breedId == id }
        var descriptor = FetchDescriptor<Favorite>(predicate: predicate)
        descriptor.fetchLimit = 1

        let result = try? db.fetch(descriptor)
        return (result?.isEmpty == false)
    }
}
