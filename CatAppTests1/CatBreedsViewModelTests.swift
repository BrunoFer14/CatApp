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
            for: Favorite.self, CachedBreed.self, FavoriteBreedDetail.self,
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

    private func fetchAllCached() throws -> [CachedBreed] {
        try context.fetch(FetchDescriptor<CachedBreed>())
            .sorted { $0.orderIndex < $1.orderIndex }
    }

    func testInitialLoadFromEmptyRepo() throws {
        let cached = try fetchAllCached()
        XCTAssertTrue(cached.isEmpty)
        XCTAssertFalse(viewModel.hasLoadedFirstPage)
    }

    func testFetchFirstPagePersistsBreedsInSwiftData() throws {
        let page0 = (0..<3).map { i in
            CatBreed(id: "id\(i)", name: "Breed \(i)", origin: nil, description: nil, temperament: nil, life_span: nil, image: nil, referenceImageId: nil)
        }
        mockRepo.mockBreedsByPage[0] = page0

        viewModel.fetchPage(page: 0)
        RunLoop.main.run(until: Date().addingTimeInterval(0.2))

        let cached = try fetchAllCached()
        XCTAssertEqual(cached.count, 3, "cached: \(cached.map { $0.id })")
        XCTAssertEqual(Set(cached.map { $0.id }), Set(page0.map { $0.id }))
        XCTAssertEqual(viewModel.currentPage, 0)
        XCTAssertTrue(viewModel.hasLoadedFirstPage)
    }

    func testPaginationAppendsToSwiftDataWithoutDuplicates() throws {
        let page0 = (0..<3).map { i in
            CatBreed(id: "id\(i)", name: "Breed \(i)", origin: nil, description: nil, temperament: nil, life_span: nil, image: nil, referenceImageId: nil)
        }
        mockRepo.mockBreedsByPage[0] = page0
        viewModel.fetchPage(page: 0)
        RunLoop.main.run(until: Date().addingTimeInterval(0.2))

        var cached = try fetchAllCached()
        XCTAssertEqual(cached.count, 3, "cached after page 0: \(cached.map { $0.id })")

        let page1 = [
            CatBreed(id: "id2", name: "Breed 2 DUP", origin: nil, description: nil, temperament: nil, life_span: nil, image: nil, referenceImageId: nil),
            CatBreed(id: "id3", name: "Breed 3", origin: nil, description: nil, temperament: nil, life_span: nil, image: nil, referenceImageId: nil),
            CatBreed(id: "id4", name: "Breed 4", origin: nil, description: nil, temperament: nil, life_span: nil, image: nil, referenceImageId: nil)
        ]
        mockRepo.mockBreedsByPage[1] = page1
        viewModel.fetchPage(page: 1)
        RunLoop.main.run(until: Date().addingTimeInterval(0.2))

        cached = try fetchAllCached()
        XCTAssertEqual(cached.count, 5, "cached after page 1: \(cached.map { $0.id })")
        XCTAssertTrue(cached.contains(where: { $0.id == "id3" }))
        XCTAssertTrue(cached.contains(where: { $0.id == "id4" }))
    }

    func testToggleFavoriteAddsAndRemovesPersistedSnapshot() throws {
        // Prepara um breed e insere snapshot ao favoritar
        let breed = CatBreed(id: "fav1", name: "Fav Breed", origin: nil, description: "desc", temperament: nil, life_span: "10 - 12", image: nil, referenceImageId: nil)

        XCTAssertFalse(viewModel.favoriteIDs.contains(breed.id))
        viewModel.toggleFavorite(for: breed)
        XCTAssertTrue(viewModel.favoriteIDs.contains(breed.id))

        // Verifica que o snapshot foi persistido
        let details = try context.fetch(FetchDescriptor<FavoriteBreedDetail>())
        XCTAssertTrue(details.contains(where: { $0.id == "fav1" }))

        // Remove favorito
        viewModel.toggleFavorite(for: breed)
        XCTAssertFalse(viewModel.favoriteIDs.contains(breed.id))

        let detailsAfter = try context.fetch(FetchDescriptor<FavoriteBreedDetail>())
        XCTAssertFalse(detailsAfter.contains(where: { $0.id == "fav1" }))
    }
}

