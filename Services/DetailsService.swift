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
        // Try search first
        if let searchRequest = Endpoint.breedSearch(query: id).request() {
            do {
                let publisher = networkService.fetch([CatBreed].self, from: searchRequest)
                let results = try await publisher.asyncFirst()
                if let exact = results.first(where: { $0.id == id }) {
                    return exact
                }
                if let first = results.first {
                    return first
                }
            } catch {
                // fall back below
            }
        }

        // Fallback: fetch full list and match by id
        guard let request = Endpoint.breeds(page: nil, limit: nil).request() else {
            throw URLError(.badURL)
        }
        let publisher = networkService.fetch([CatBreed].self, from: request)
        return try await publisher.asyncFirst().first(where: { $0.id == id })
    }

    // Fetch all images for a breed by paginating until no more results or a safe cap is reached.
    // IMPORTANT: Only use Endpoint.breedImages so we always send "breed_ids" (plural) and the requested limit.
    func breedImages(id: String, limit: Int) async throws -> [BreedGalleryImage] {
        let pageSize = max(1, min(limit, APIConstants.defaultGalleryMaxTotal))
        var all: [BreedGalleryImage] = []
        var page = 0 // TheCatAPI uses 0-based page indexing

        while all.count < APIConstants.defaultGalleryMaxTotal {
            guard let request = Endpoint.breedImages(breedId: id, limit: pageSize, page: page).request() else {
                throw URLError(.badURL)
            }

            let publisher = networkService.fetch([BreedGalleryImage].self, from: request)
            let batch = try await publisher.asyncFirst()

            // Append new items; avoid duplicates by ID
            let existingIDs = Set(all.map { $0.id })
            let uniqueNew = batch.filter { !existingIDs.contains($0.id) }
            all.append(contentsOf: uniqueNew)

            // Stop if fewer than a full page returned
            if batch.count < pageSize { break }
            page += 1
        }

        let capped = Array(all.prefix(APIConstants.defaultGalleryMaxTotal))
        return capped
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
        // Compose directly; do not read from the current dependency context here
        let network = NetworkService(apiKey: secrets.catApiKey)
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
