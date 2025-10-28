import Foundation
import Combine
@testable import CatApp

/// Mock for NetworkServiceProtocol to test repositories.
/// Supports both URL and URLRequest-based fetch.
final class MockNetworkService: NetworkServiceProtocol {
    struct Key: Hashable {
        let url: URL
        let method: String
        let typeName: String
    }

    // Map of (URL, Method, Type) -> Data or Error
    var results: [Key: Result<Data, Error>] = [:]

    // Helper: set a JSON response for an encodable object and URL (GET by default).
    func setJSONResponse<T: Encodable>(_ object: T, for url: URL, method: String = "GET", encoder: JSONEncoder = JSONEncoder()) throws {
        let data = try encoder.encode(AnyEncodable(object))
        let key = Key(url: url, method: method, typeName: String(describing: T.self))
        results[key] = .success(data)
    }

    func setError<T: Decodable>(_ error: Error, for type: T.Type, url: URL, method: String = "GET") {
        let key = Key(url: url, method: method, typeName: String(describing: T.self))
        results[key] = .failure(error)
    }

    // URL overload (kept for compatibility)
    func fetch<T>(_ type: T.Type, from url: URL) -> AnyPublisher<T, Error> where T : Decodable {
        let key = Key(url: url, method: "GET", typeName: String(describing: T.self))
        guard let result = results[key] else {
            return Fail(error: URLError(.badServerResponse)).eraseToAnyPublisher()
        }
        switch result {
        case .success(let data):
            return Just(data)
                .decode(type: T.self, decoder: JSONDecoder())
                .mapError { $0 }
                .eraseToAnyPublisher()
        case .failure(let error):
            return Fail(error: error).eraseToAnyPublisher()
        }
    }

    // URLRequest overload (preferred)
    func fetch<T>(_ type: T.Type, from request: URLRequest) -> AnyPublisher<T, Error> where T : Decodable {
        let url = request.url ?? URL(string: "about:blank")!
        let method = request.httpMethod ?? "GET"
        let key = Key(url: url, method: method, typeName: String(describing: T.self))
        guard let result = results[key] else {
            return Fail(error: URLError(.badServerResponse)).eraseToAnyPublisher()
        }
        switch result {
        case .success(let data):
            return Just(data)
                .decode(type: T.self, decoder: JSONDecoder())
                .mapError { $0 }
                .eraseToAnyPublisher()
        case .failure(let error):
            return Fail(error: error).eraseToAnyPublisher()
        }
    }
}

/// Wrapper to allow encoding any Encodable value to Data with JSONEncoder.
private struct AnyEncodable: Encodable {
    let value: any Encodable
    init(_ value: any Encodable) { self.value = value }
    func encode(to encoder: Encoder) throws { try value.encode(to: encoder) }
}

