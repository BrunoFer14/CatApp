import SwiftData

/// SwiftData model for caching cat breeds in local persistence storage.
/// Used to maintain breed data offline and support pagination ordering.
@Model
class CachedBreed {
    @Attribute(.unique) var id: String
    var name: String
    var origin: String?
    var temperament: String?
    var lifeSpan: String?
    var breedDescription: String?
    var imageUrl: String?
    var orderIndex: Int = UIConfig.Pagination.initialPageIndex

    init(
        id: String,
        name: String,
        origin: String?,
        temperament: String?,
        lifeSpan: String?,
        breedDescription: String?,
        imageUrl: String?,
        orderIndex: Int = UIConfig.Pagination.initialPageIndex
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
