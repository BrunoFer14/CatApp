import Foundation
import SwiftData

struct CatBreed: Identifiable, Codable {
    let id: String
    let name: String
    let origin: String?
    let description: String?
    let temperament: String?
    let life_span: String?
    let image: BreedImage?
    let referenceImageId: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case origin
        case description
        case temperament
        case life_span
        case image
        case referenceImageId = "reference_image_id"
    }

    /// URL direto para a imagem, se existir um reference_image_id
    var referenceImageUrl: String? {
        guard let id = referenceImageId else { return nil }
        return "https://cdn2.thecatapi.com/images/\(id).jpg"
    }
}

struct BreedImage: Codable {
    let url: String?
}
