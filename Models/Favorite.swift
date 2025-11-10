import SwiftData

/// Model Swift Data : saves favorite breed id
@Model
class Favorite {
    @Attribute(.unique) var breedId: String

    init(breedId: String) {
        self.breedId = breedId
    }
}
