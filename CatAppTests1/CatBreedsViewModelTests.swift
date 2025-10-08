import XCTest
import SwiftData
import Combine
@testable import CatApp

@MainActor
final class CatBreedsViewModelTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!
    var mockRepo: MockBreedsRepository!
    var viewModel: CatBreedsViewModel!

    override func setUpWithError() throws {
        container = try ModelContainer(
            for: Favorite.self, CachedBreed.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        context = container.mainContext

        mockRepo = MockBreedsRepository()
        mockRepo.mockBreedsByPage = [:]

        viewModel = CatBreedsViewModel(
            context: context,
            repository: mockRepo,
            autoFetchFirstPage: false
        )
    }

    override func tearDownWithError() throws {
        container = nil
        context = nil
        mockRepo = nil
        viewModel = nil
    }

    func testInitialLoadFromEmptyRepo() throws {
        XCTAssertTrue(viewModel.breeds.isEmpty)
    }

    func testFetchFirstPageLoadsBreeds() throws {
        let page0 = (0..<3).map { i in
            CatBreed(id: "id\(i)", name: "Breed \(i)", origin: nil, description: nil, temperament: nil, life_span: nil, image: nil, referenceImageId: nil)
        }
        mockRepo.mockBreedsByPage[0] = page0

        viewModel.fetchPage(page: 0)
        RunLoop.main.run(until: Date().addingTimeInterval(0.2))

        XCTAssertEqual(viewModel.breeds.count, 3, "breeds: \(viewModel.breeds)")
        XCTAssertEqual(Set(viewModel.breeds.map { $0.id }), Set(page0.map { $0.id }))
        XCTAssertEqual(viewModel.currentPage, 0)
    }

    func testPaginationAppendsWithoutDuplicates() throws {
        let page0 = (0..<3).map { i in
            CatBreed(id: "id\(i)", name: "Breed \(i)", origin: nil, description: nil, temperament: nil, life_span: nil, image: nil, referenceImageId: nil)
        }
        mockRepo.mockBreedsByPage[0] = page0
        viewModel.fetchPage(page: 0)
        RunLoop.main.run(until: Date().addingTimeInterval(0.2))
        XCTAssertEqual(viewModel.breeds.count, 3, "breeds after page 0: \(viewModel.breeds)")

        let page1 = [
            CatBreed(id: "id2", name: "Breed 2 DUP", origin: nil, description: nil, temperament: nil, life_span: nil, image: nil, referenceImageId: nil),
            CatBreed(id: "id3", name: "Breed 3", origin: nil, description: nil, temperament: nil, life_span: nil, image: nil, referenceImageId: nil),
            CatBreed(id: "id4", name: "Breed 4", origin: nil, description: nil, temperament: nil, life_span: nil, image: nil, referenceImageId: nil)
        ]
        mockRepo.mockBreedsByPage[1] = page1
        viewModel.fetchPage(page: 1)
        RunLoop.main.run(until: Date().addingTimeInterval(0.2))

        XCTAssertEqual(viewModel.breeds.count, 5, "breeds after page 1: \(viewModel.breeds)")
        XCTAssertTrue(viewModel.breeds.contains(where: { $0.id == "id3" }))
        XCTAssertTrue(viewModel.breeds.contains(where: { $0.id == "id4" }))
    }

    func testToggleFavoriteAddsAndRemoves() throws {
        let breed = CatBreed(id: "fav1", name: "Fav Breed", origin: nil, description: nil, temperament: nil, life_span: nil, image: nil, referenceImageId: nil)
        viewModel.breeds = [breed]

        XCTAssertFalse(viewModel.isFavorite(breed))
        viewModel.toggleFavorite(for: breed)
        XCTAssertTrue(viewModel.isFavorite(breed))
        XCTAssertTrue(viewModel.favoriteIDs.contains(breed.id))
        viewModel.toggleFavorite(for: breed)
        XCTAssertFalse(viewModel.isFavorite(breed))
        XCTAssertFalse(viewModel.favoriteIDs.contains(breed.id))
    }
}
