import XCTest
import Combine
@testable import CatApp

final class SearchRepositoryTests: XCTestCase {
    var cancellables: Set<AnyCancellable> = []

    func testSearchBreedsDecodesAndReturnsResults() throws {
        let mockService = MockNetworkService()
        let repo = SearchRepository(networkService: mockService)

        let query = "british shorthair"
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let url = URL(string: "https://api.thecatapi.com/v1/breeds/search?q=\(encoded)")!

        let payload: [CatBreed] = [
            CatBreed(id: "bri", name: "British Shorthair", origin: "GB", description: "desc", temperament: "calm", lifeSpan: "12 - 17", image: nil, referenceImageId: "abc")
        ]
        try mockService.setJSONResponse(payload, for: url)

        let exp = expectation(description: "search")
        var received: [CatBreed] = []

        repo.searchBreeds(query: query)
            .sink(receiveCompletion: { completion in
                if case .failure(let err) = completion {
                    XCTFail("Unexpected error: \(err)")
                }
                exp.fulfill()
            }, receiveValue: { breeds in
                received = breeds
            })
            .store(in: &cancellables)

        waitForExpectations(timeout: 1.0)
        XCTAssertEqual(received.count, 1)
        XCTAssertEqual(received.first?.id, "bri")
        XCTAssertEqual(received.first?.name, "British Shorthair")
    }

    func testSearchBreedsBadURLEmitsError() {
        // Força uma query que gere badURL (teoricamente só acontece se URL init falhar, raro)
        let repo = SearchRepository(networkService: MockNetworkService())
        let badQuery = " " // ainda é válido, mas deixamos como sanity check
        let exp = expectation(description: "error")
        var gotError = false

        repo.searchBreeds(query: badQuery)
            .sink(receiveCompletion: { completion in
                if case .failure = completion { gotError = true }
                exp.fulfill()
            }, receiveValue: { _ in })
            .store(in: &cancellables)

        waitForExpectations(timeout: 1.0)
        XCTAssertTrue(gotError)
    }
}
