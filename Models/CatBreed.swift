import Foundation

struct CatBreed: Identifiable, Codable {
    let id: String
    let name: String
    let origin: String?
    let temperament: String?
    let description: String?
    let life_span: String?
    let image: CatImage?
    
    struct CatImage: Codable {
        let url: String?
    }
}
