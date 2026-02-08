import Foundation

/// Constants for API configuration and network requests
/// Centralizes all API-related configuration for easy maintenance
enum APIConstants {
    // MARK: - Pagination Settings
    /// Default number of breeds to fetch per page
    static let defaultPageLimit: Int = 20
    /// Page size used when fetching gallery images (per request)
    static let defaultGalleryLimit: Int = 100
    /// Safety cap to avoid unbounded downloads when fetching all images for a breed
    static let defaultGalleryMaxTotal: Int = 200

    // MARK: - Networking Configuration
    /// Timeout duration for network requests (in seconds)
    static let requestTimeout: TimeInterval = 30

    /// HTTP header constants used in API requests
    enum Headers {
        /// Header key for API authentication
        static let apiKey = "x-api-key"
    }

    /// Query parameter names used in API requests
    enum Query {
        /// Parameter for limiting the number of results
        static let limit = "limit"
        /// Parameter for specifying the page number
        static let page = "page"
        /// Parameter for search queries
        static let search = "q"
        /// Parameter for filtering by specific breed IDs (plural - for breeds endpoint)
        static let breedIds = "breed_ids"
        /// Parameter for filtering by specific breed ID (singular - for images/search endpoint)
        static let breedId = "breed_id"
    }
}

