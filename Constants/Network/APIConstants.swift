import Foundation

enum APIConstants {
    // Pagination
    static let defaultPageLimit: Int = 20
    static let defaultGalleryLimit: Int = 10

    // Networking behavior
    static let requestTimeout: TimeInterval = 30

    enum Headers {
        static let apiKey = "x-api-key"
    }

    enum Query {
        static let limit = "limit"
        static let page = "page"
        static let search = "q"
        static let breedIds = "breed_ids"
    }
}
