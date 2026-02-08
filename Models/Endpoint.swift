import Foundation

/// HTTP methods supported by the API.
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

/// Describes an API endpoint in a type-safe manner.
enum Endpoint {
    // MARK: - Breeds
    case breeds(page: Int?, limit: Int?)
    case breedSearch(query: String)
    case breedImages(breedId: String, limit: Int?, page: Int?)

    // MARK: - Components
    var method: HTTPMethod {
        switch self {
        case .breeds, .breedSearch, .breedImages:
            return .get
        }
    }

    /// Path components after /{version}
    private var pathComponents: [String] {
        switch self {
        case .breeds:
            return ["breeds"]
        case .breedSearch:
            return ["breeds", "search"]
        case .breedImages:
            return ["images", "search"]
        }
    }

    /// Query items for the endpoint.
    private var queryItems: [URLQueryItem] {
        switch self {
        case let .breeds(page, limit):
            var items: [URLQueryItem] = []
            if let limit { items.append(URLQueryItem(name: APIConstants.Query.limit, value: String(limit))) }
            if let page { items.append(URLQueryItem(name: APIConstants.Query.page, value: String(page))) }
            return items

        case let .breedSearch(query):
            return [URLQueryItem(name: APIConstants.Query.search, value: query)]

        case let .breedImages(breedId, limit, page):
            var items: [URLQueryItem] = [
                // IMPORTANT: TheCatAPI expects "breed_ids" (plural)
                URLQueryItem(name: APIConstants.Query.breedIds, value: breedId)
            ]
            if let limit {
                items.append(URLQueryItem(name: APIConstants.Query.limit, value: String(limit)))
            }
            if let page {
                items.append(URLQueryItem(name: APIConstants.Query.page, value: String(page)))
            }
            return items
        }
    }

    /// Builds a URL for this endpoint using APIConfig.
    func url() -> URL? {
        var url = APIConfig.baseURL
        url.append(path: APIConfig.version)
        for comp in pathComponents {
            url.append(path: comp)
        }
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        return components.url
    }

    /// Builds a URLRequest for this endpoint, injecting headers (like x-api-key).
    func request() -> URLRequest? {
        guard let url = url() else { return nil }
        var req = URLRequest(url: url)
        req.httpMethod = method.rawValue

        // Common headers: API key if present
        if let apiKey = APIConfig.apiKey, !apiKey.isEmpty {
            req.addValue(apiKey, forHTTPHeaderField: APIConstants.Headers.apiKey)
        }

        return req
    }
}
