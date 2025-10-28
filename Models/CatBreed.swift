import Foundation
import SwiftData

/// Modelo principal vindo da API (Codable) e usado pela UI.
struct CatBreed: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let origin: String?
    let description: String?
    let temperament: String?
    let lifeSpan: String?
    let image: BreedImage?
    let referenceImageId: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case origin
        case description
        case temperament
        case lifeSpan = "life_span" // map JSON snake_case to Swift camelCase
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
        guard let lifeSpan else { return nil }

        // Normalize whitespace around hyphen, but keep components to validate both sides
        let components = lifeSpan.split(separator: "-", maxSplits: 1, omittingEmptySubsequences: false)
        if components.count == 2 {
            // Range form: require both sides to be valid numbers
            let leftString = components[0].trimmingCharacters(in: .whitespaces)
            let rightString = components[1].trimmingCharacters(in: .whitespaces)
            guard
                !leftString.isEmpty,
                !rightString.isEmpty,
                let left = Double(leftString),
                let right = Double(rightString)
            else {
                return nil
            }
            return (left + right) / 2.0
        } else {
            // Single value form: require it to be a valid number
            let single = lifeSpan.trimmingCharacters(in: .whitespaces)
            guard !single.isEmpty, let value = Double(single) else { return nil }
            return value
        }
    }
}

/// Submodelo para a imagem dentro do JSON.
struct BreedImage: Codable, Equatable {
    let url: String?
}

