import SwiftData

/// Durable snapshot of a favorited breed's renderable details, independent of the paginated cache.
@Model
final class FavoriteBreedDetail {
    @Attribute(.unique) var id: String
    var name: String
    var origin: String?
    var temperament: String?
    var lifeSpan: String?
    var breedDescription: String?
    var imageUrl: String?

    init(
        id: String,
        name: String,
        origin: String?,
        temperament: String?,
        lifeSpan: String?,
        breedDescription: String?,
        imageUrl: String?
    ) {
        self.id = id
        self.name = name
        self.origin = origin
        self.temperament = temperament
        self.lifeSpan = lifeSpan
        self.breedDescription = breedDescription
        self.imageUrl = imageUrl
    }
}
