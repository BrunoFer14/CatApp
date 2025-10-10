import Foundation
import SwiftData

/// Modelo principal vindo da API (Codable) e usado pela UI.
struct CatBreed: Identifiable, Codable, Equatable {
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

    var referenceImageUrl: String? {
        guard let id = referenceImageId else { return nil }
        return "https://cdn2.thecatapi.com/images/\(id).jpg"
    }

    // URL pronta para UI
    var displayImageUrl: String? {
        image?.url ?? referenceImageUrl
    }

    // Vida média como Double
    var averageLifeSpan: Double? {
        guard let life_span else { return nil }
        let parts = life_span
            .components(separatedBy: "-")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .compactMap(Double.init)
        switch parts.count {
        case 2: return (parts[0] + parts[1]) / 2.0
        case 1: return parts[0]
        default: return nil
        }
    }
}

/// Submodelo para a imagem dentro do JSON.
struct BreedImage: Codable, Equatable {
    let url: String?
}
