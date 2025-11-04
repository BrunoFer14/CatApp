// BreedsService.swift
import Foundation
import Combine
import ComposableArchitecture

protocol BreedsServiceProtocol {
    func pagedBreeds(page: Int, limit: Int) async throws -> [CatBreed]
}

struct BreedsService: BreedsServiceProtocol {
    let networkService: NetworkServiceProtocol

    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
    }

    func pagedBreeds(page: Int, limit: Int) async throws -> [CatBreed] {
        guard let request = Endpoint.breeds(page: page, limit: limit).request() else {
            throw URLError(.badURL)
        }
        // Bridge Combine to async once and return the array
        let publisher = networkService.fetch([CatBreed].self, from: request)
        return try await publisher.asyncFirst()
    }
}

// MARK: - Helper: await first value from a Combine publisher
private extension Publisher {
    func asyncFirst() async throws -> Output {
        try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = self.first()
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            continuation.resume(throwing: error)
                        }
                        _ = cancellable
                    },
                    receiveValue: { value in
                        continuation.resume(returning: value)
                        _ = cancellable
                    }
                )
        }
    }
}

// MARK: - TCA Dependency

private enum BreedsServiceKey: DependencyKey {
    static var liveValue: BreedsServiceProtocol {
        let network = DependencyValues().networkService
        return BreedsService(networkService: network)
    }

    static var testValue: BreedsServiceProtocol {
        struct Stub: BreedsServiceProtocol {
            var pages: [Int: [CatBreed]] = [:]
            var error: Error?
            func pagedBreeds(page: Int, limit: Int) async throws -> [CatBreed] {
                if let error { throw error }
                return pages[page] ?? []
            }
        }
        return Stub()
    }

    static var previewValue: BreedsServiceProtocol { liveValue }
}

extension DependencyValues {
    var breedsService: BreedsServiceProtocol {
        get { self[BreedsServiceKey.self] }
        set { self[BreedsServiceKey.self] = newValue }
    }
}
