import XCTest
import SwiftData
@testable import CatApp

@MainActor
final class CatBreedsViewModelTests: XCTestCase {
    var context: ModelContext!
    var viewModel: CatBreedsViewModel!

    override func setUpWithError() throws {
        let container = try ModelContainer(
            for: Favorite.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        context = container.mainContext

        let mockRepo = MockBreedsRepository()
        viewModel = CatBreedsViewModel(context: context, repository: mockRepo)
    }

    func testToggleFavoriteAddsAndRemoves() throws {
        let breed = CatBreed(
            id: "123",
            name: "Persian",
            origin: nil,
            description: nil,
            temperament: nil,
            life_span: nil,
            image: nil
        )

        XCTAssertFalse(viewModel.isFavorite(breed))
        viewModel.toggleFavorite(for: breed)
        XCTAssertTrue(viewModel.isFavorite(breed))
        viewModel.toggleFavorite(for: breed)
        XCTAssertFalse(viewModel.isFavorite(breed))
    }
}
