import XCTest
import Combine
@testable import CatApp

final class DetailsRepositoryTests: XCTestCase {
    var cancellables: Set<AnyCancellable> = []

    func testFetchBreedDetailFiltersByID() throws {
        let mockService = MockNetworkService()
        let repo = DetailsRepository(networkService: mockService)

        let url = URL(string: "https://api.thecatapi.com/v1/breeds")!
        let breeds: [CatBreed] = [
            CatBreed(id: "a", name  : "A", origin: nil, description: nil, temperament: nil, lifeSpan: nil, image: nil, referenceImageId: nil),
            CatBreed(id: "b", name: "B", origin: nil, description: nil, temperament: nil, lifeSpan: nil, image: nil, referenceImageId: nil)
        ]
        try mockService.setJSONResponse(breeds, for: url)

        let exp = expectation(description: "detail")
        var received: CatBreed?

        repo.fetchBreedDetail(by: "b")
            .sink(receiveCompletion: { completion in
                if case .failure(let err) = completion {
                    XCTFail("Unexpected error: \(err)")
                }
                exp.fulfill()
            }, receiveValue: { breed in
                received = breed
            })
            .store(in: &cancellables)

        waitForExpectations(timeout: 1.0)
        XCTAssertEqual(received?.id, "b")
        XCTAssertEqual(received?.name, "B")
    }

    func testFetchBreedImagesUsesCorrectEndpointAndDecodes() throws {
        let mockService = MockNetworkService()
        let repo = DetailsRepository(networkService: mockService)

        let id = "abys"
        let limit = 3
        let url = URL(string: "https://api.thecatapi.com/v1/images/search?breed_ids=\(id)&limit=\(limit)")!

        let images: [BreedGalleryImage] = [
            BreedGalleryImage(id: "i1", url: "https://cdn2.thecatapi.com/images/i1.jpg"),
            BreedGalleryImage(id: "i2", url: "https://cdn2.thecatapi.com/images/i2.jpg"),
            BreedGalleryImage(id: "i3", url: "https://cdn2.thecatapi.com/images/i3.jpg")
        ]
        try mockService.setJSONResponse(images, for: url)

        let exp = expectation(description: "images")
        var received: [BreedGalleryImage] = []

        repo.fetchBreedImages(by: id, limit: limit)
            .sink(receiveCompletion: { completion in
                if case .failure(let err) = completion {
                    XCTFail("Unexpected error: \(err)")
                }
                exp.fulfill()
            }, receiveValue: { imgs in
                received = imgs
            })
            .store(in: &cancellables)

        waitForExpectations(timeout: 1.0)
        XCTAssertEqual(received.count, 3)
        XCTAssertEqual(received.map(\.id), ["i1", "i2", "i3"])
    }
}
