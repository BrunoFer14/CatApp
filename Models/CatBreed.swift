import Foundation
import SwiftData

/// Main cat breed model from API (Codable) and used throughout the UI
/// Represents a complete cat breed with all available information
struct CatBreed: Identifiable, Codable, Equatable {
    /// Unique identifier for the breed
    let id: String
    let name: String
    let origin: String?
    let description: String?
    let temperament: String?
    let lifeSpan: String?
    let image: BreedImage?
    let referenceImageId: String?

    /// Maps JSON keys to Swift property names
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case origin
        case description
        case temperament
        case lifeSpan = "life_span" // Maps JSON snake_case to Swift camelCase
        case image
        case referenceImageId = "reference_image_id"
    }

    /// Constructs image URL from reference image ID
    /// - Returns: Complete URL string for the breed's reference image
    var referenceImageUrl: String? {
        guard let id = referenceImageId else { return nil }
        return "https://cdn2.thecatapi.com/images/\(id).jpg"
    }

    /// Primary image URL for UI display
    /// Prefers direct image URL, falls back to reference image URL
    var displayImageUrl: String? {
        image?.url ?? referenceImageUrl
    }

    /// Calculates average lifespan from string range
    /// Handles both single values ("12") and ranges ("12 - 15")
    /// - Returns: Average lifespan as Double, nil if parsing fails
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

/// Image submodel contained within breed JSON response
/// Contains URL information for breed representation images
struct BreedImage: Codable, Equatable {
    /// Direct URL to the breed's image
    let url: String?
}

