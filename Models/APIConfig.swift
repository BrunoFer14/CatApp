import Foundation

/// Central configuration for the TheCatAPI.
enum APIConfig {
    /// Base URL for all endpoints.
    static let baseURL: URL = URL(string: "https://api.thecatapi.com")!

    /// API version path component (e.g., "v1").
    static let version: String = "v1"

    /// API key provider. Currently reads from Info.plist via `secrets.catApiKey`.
    static var apiKey: String? { secrets.catApiKey }
}

