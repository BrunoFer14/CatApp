import Foundation
import Combine
import ComposableArchitecture

protocol DetailsServiceProtocol {
    func breedDetail(id: String) async throws -> CatBreed?
    func breedImages(id: String, limit: Int) async throws -> [BreedGalleryImage]
}

struct DetailsService: DetailsServiceProtocol {
    let networkService: NetworkServiceProtocol

    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
    }

    func breedDetail(id: String) async throws -> CatBreed? {
        guard let request = Endpoint.breeds(page: nil, limit: nil).request() else {
            throw URLError(.badURL)
        }
        let publisher = networkService.fetch([CatBreed].self, from: request)
        return try await publisher.asyncFirst().first(where: { $0.id == id })
    }

    func breedImages(id: String, limit: Int) async throws -> [BreedGalleryImage] {
        guard let request = Endpoint.breedImages(breedId: id, limit: limit).request() else {
            throw URLError(.badURL)
        }
        let publisher = networkService.fetch([BreedGalleryImage].self, from: request)
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

private enum DetailsServiceKey: DependencyKey {
    static var liveValue: DetailsServiceProtocol {
        // Use the registered dependency accessor instead of referencing the key type
        let network = DependencyValues().networkService
        return DetailsService(networkService: network)
    }

    static var testValue: DetailsServiceProtocol {
        struct Stub: DetailsServiceProtocol {
            var detail: CatBreed?
            var images: [BreedGalleryImage] = []
            func breedDetail(id: String) async throws -> CatBreed? { detail }
            func breedImages(id: String, limit: Int) async throws -> [BreedGalleryImage] { images }
        }
        return Stub()
    }

    static var previewValue: DetailsServiceProtocol { liveValue }
}

extension DependencyValues {
    var detailsService: DetailsServiceProtocol {
        get { self[DetailsServiceKey.self] }
        set { self[DetailsServiceKey.self] = newValue }
    }
}
