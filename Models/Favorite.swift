import SwiftData

@Model
class Favorite {
    @Attribute(.unique) var breedId: String

    init(breedId: String) {
        self.breedId = breedId
    }
}
