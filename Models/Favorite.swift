import Foundation
import SwiftData

@Model
class Favorite {
    var breedId: String

    init(breedId: String) {
        self.breedId = breedId
    }
}


