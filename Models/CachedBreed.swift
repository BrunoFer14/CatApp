import SwiftData

@Model
class CachedBreed {
    @Attribute(.unique) var id: String
    var name: String
    var origin: String?
    var temperament: String?
    var life_span: String?
    var breedDescription: String?
    var imageUrl: String?

    init(
        id: String,
        name: String,
        origin: String?,
        temperament: String?,
        life_span: String?,
        breedDescription: String?,
        imageUrl: String?
    ) {
        self.id = id
        self.name = name
        self.origin = origin
        self.temperament = temperament
        self.life_span = life_span
        self.breedDescription = breedDescription
        self.imageUrl = imageUrl
    }
}
