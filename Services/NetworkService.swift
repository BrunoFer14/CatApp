import Foundation
import Combine

/// Protocolo para um serviço de rede genérico.
protocol NetworkServiceProtocol {
    func fetch<T: Decodable>(_ type: T.Type, from url: URL) -> AnyPublisher<T, Error>
    func fetch<T: Decodable>(_ type: T.Type, from request: URLRequest) -> AnyPublisher<T, Error>
}

/// Implementação baseada em URLSession + Combine, com suporte a API key.
class NetworkService: NetworkServiceProtocol {
    private let apiKey: String?

    /// Permite configurar uma API key para ser enviada no header "x-api-key".
    init(apiKey: String? = nil) {
        self.apiKey = apiKey
    }

    // Legacy URL-based overload (kept for compatibility)
    func fetch<T: Decodable>(_ type: T.Type, from url: URL) -> AnyPublisher<T, Error> {
        var request = URLRequest(url: url)
        // Adiciona header da TheCatAPI se existir key (kept here for URL-based paths)
        if let apiKey, !apiKey.isEmpty {
            request.addValue(apiKey, forHTTPHeaderField: APIConstants.Headers.apiKey)
        }
        return fetch(type, from: request)
    }

    // New request-based overload
    func fetch<T: Decodable>(_ type: T.Type, from request: URLRequest) -> AnyPublisher<T, Error> {
        URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: T.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
}
