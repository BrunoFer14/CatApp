import SwiftData

/// Modelo SwiftData para guardar raças em cache (persistência local).
@Model
class CachedBreed {
    @Attribute(.unique) var id: String // único por raça
    var name: String
    var origin: String?
    var temperament: String?
    var lifeSpan: String?
    var breedDescription: String?
    var imageUrl: String?
    // Índice para manter a ordem de carregamento/paginação
    var orderIndex: Int = 0

    init(
        id: String,
        name: String,
        origin: String?,
        temperament: String?,
        lifeSpan: String?,
        breedDescription: String?,
        imageUrl: String?,
        orderIndex: Int = 0
    ) {
        self.id = id
        self.name = name
        self.origin = origin
        self.temperament = temperament
        self.lifeSpan = lifeSpan
        self.breedDescription = breedDescription
        self.imageUrl = imageUrl
        self.orderIndex = orderIndex
    }
}
