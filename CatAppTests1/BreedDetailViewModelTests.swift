import XCTest
import Combine
@testable import CatApp

@MainActor
final class BreedDetailViewModelTests: XCTestCase {
    var mockRepo: MockDetailsRepository!
    var viewModel: BreedDetailViewModel!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        mockRepo = MockDetailsRepository()
        cancellables = []
    }

    override func tearDown() {
        mockRepo = nil
        viewModel = nil
        cancellables = nil
        super.tearDown()
    }

    func testDoesNotFetchWhenBreedProvided() {
        // Dado: já temos um breed completo
        let provided = CatBreed(id: "abc", name: "Provided", origin: nil, description: "desc", temperament: nil, life_span: nil, image: nil, referenceImageId: nil)
        viewModel = BreedDetailViewModel(breed: provided, repository: mockRepo)

        // Quando: pedimos load por ID
        viewModel.loadBreedDetail(id: "abc")

        // Então: não deve ter alterado o breed nem chamado rede (mockRepo não conta chamadas, mas estado não muda)
        XCTAssertEqual(viewModel.breed?.id, "abc")
        XCTAssertEqual(viewModel.breed?.name, "Provided")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testFetchesWhenBreedNotProvided() {
        // Dado: não fornecemos breed; mock devolve um breed para o ID pedido
        let fetched = CatBreed(id: "xyz", name: "Fetched", origin: "Origin", description: "Desc", temperament: "Calm", life_span: "10 - 12", image: nil, referenceImageId: nil)
        mockRepo.breedsById["xyz"] = fetched

        viewModel = BreedDetailViewModel(breed: nil, repository: mockRepo)

        // Observa mudanças de loading (opcional)
        let loadingExpectation = expectation(description: "Loading toggled")
        var loadingStates: [Bool] = []
        viewModel.$isLoading
            .dropFirst()
            .sink { value in
                loadingStates.append(value)
                if loadingStates.count >= 2 { loadingExpectation.fulfill() }
            }
            .store(in: &cancellables)

        // Quando
        viewModel.loadBreedDetail(id: "xyz")

        // Espera o pipeline terminar
        wait(for: [loadingExpectation], timeout: 1.0)

        // Então
        XCTAssertEqual(viewModel.breed?.id, "xyz")
        XCTAssertEqual(viewModel.breed?.name, "Fetched")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testFetchErrorSetsErrorMessage() {
        // Dado: mock falha
        enum DummyError: Error { case failed }
        mockRepo.error = DummyError.failed
        viewModel = BreedDetailViewModel(breed: nil, repository: mockRepo)

        let loadingExpectation = expectation(description: "Loading toggled on error")
        var loadingStates: [Bool] = []
        viewModel.$isLoading
            .dropFirst()
            .sink { value in
                loadingStates.append(value)
                if loadingStates.count >= 2 { loadingExpectation.fulfill() }
            }
            .store(in: &cancellables)

        // Quando
        viewModel.loadBreedDetail(id: "any")

        // Espera
        wait(for: [loadingExpectation], timeout: 1.0)

        // Então
        XCTAssertNil(viewModel.breed)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.errorMessage)
    }
}
