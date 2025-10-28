import SwiftData

/// Modelo SwiftData simples: guarda apenas o ID da raça favorita.
@Model
class Favorite {
    @Attribute(.unique) var breedId: String

    init(breedId: String) {
        self.breedId = breedId
    }
}
