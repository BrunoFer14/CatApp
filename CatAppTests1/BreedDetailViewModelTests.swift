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
        let provided = CatBreed(id: "abc", name: "Provided", origin: nil, description: "desc", temperament: nil, lifeSpan: nil, image: nil, referenceImageId: nil)
        viewModel = BreedDetailViewModel(breed: provided, repository: mockRepo)

        // Quando: pedimos load por ID
        mockRepo.resetCounters()
        viewModel.loadBreedDetail(id: "abc")

        // Então: não deve ter alterado o breed nem chamado rede
        XCTAssertEqual(viewModel.breed?.id, "abc")
        XCTAssertEqual(viewModel.breed?.name, "Provided")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(mockRepo.fetchBreedDetailCallCount, 0, "Não deve chamar fetchBreedDetail quando breed já existe")
    }

    func testFetchesWhenBreedNotProvided() {
        // Dado: não fornecemos breed; mock devolve um breed para o ID pedido
        let fetched = CatBreed(id: "xyz", name: "Fetched", origin: "Origin", description: "Desc", temperament: "Calm", lifeSpan: "10 - 12", image: nil, referenceImageId: nil)
        mockRepo.breedsById["xyz"] = fetched

        viewModel = BreedDetailViewModel(breed: nil, repository: mockRepo)

        // Observa mudanças de loading: queremos observar a sequência true -> false e cumprir exatamente uma vez
        let loadingExpectation = expectation(description: "Loading toggled")
        var didFulfill = false
        var sawLoadingTrue = false

        viewModel.$isLoading
            .dropFirst() // ignore initial value
            .sink { value in
                if value {
                    sawLoadingTrue = true
                } else if sawLoadingTrue && !didFulfill {
                    didFulfill = true
                    loadingExpectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // Quando
        mockRepo.resetCounters()
        viewModel.loadBreedDetail(id: "xyz")

        // Espera o pipeline terminar
        wait(for: [loadingExpectation], timeout: TestConstants.defaultExpectationTimeout)

        // Então
        XCTAssertEqual(viewModel.breed?.id, "xyz")
        XCTAssertEqual(viewModel.breed?.name, "Fetched")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(mockRepo.fetchBreedDetailCallCount, 1)
    }

    func testFetchErrorSetsErrorMessage() {
        // Dado: mock falha
        enum DummyError: Error { case failed }
        mockRepo.error = DummyError.failed
        viewModel = BreedDetailViewModel(breed: nil, repository: mockRepo)

        let loadingExpectation = expectation(description: "Loading toggled on error")
        var didFulfill = false
        var sawLoadingTrue = false

        viewModel.$isLoading
            .dropFirst()
            .sink { value in
                if value {
                    sawLoadingTrue = true
                } else if sawLoadingTrue && !didFulfill {
                    didFulfill = true
                    loadingExpectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // Quando
        mockRepo.resetCounters()
        viewModel.loadBreedDetail(id: "any")

        // Espera
        wait(for: [loadingExpectation], timeout: TestConstants.defaultExpectationTimeout)

        // Então
        XCTAssertNil(viewModel.breed)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(mockRepo.fetchBreedDetailCallCount, 1)
    }

    func testFetchNilBreedSetsNotFoundError() {
        // Dado: mock não tem a raça (vai devolver nil sem erro)
        viewModel = BreedDetailViewModel(breed: nil, repository: mockRepo)

        let loadingExpectation = expectation(description: "Loading toggled on nil result")
        var didFulfill = false
        var sawLoadingTrue = false

        viewModel.$isLoading
            .dropFirst()
            .sink { value in
                if value {
                    sawLoadingTrue = true
                } else if sawLoadingTrue && !didFulfill {
                    didFulfill = true
                    loadingExpectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // Quando
        mockRepo.resetCounters()
        viewModel.loadBreedDetail(id: "missing")

        // Espera
        wait(for: [loadingExpectation], timeout: TestConstants.defaultExpectationTimeout)

        // Então
        XCTAssertNil(viewModel.breed)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.errorMessage, "Erro: Raça não encontrada.")
        XCTAssertEqual(mockRepo.fetchBreedDetailCallCount, 1)
    }

    func testLoadGalleryImagesUpdatesImageItemsAndResetsSelection() {
        // Dado: breed com imagem principal e galeria com imagens (inclui duplicada da principal)
        let breed = CatBreed(id: "gal", name: "WithGallery", origin: nil, description: nil, temperament: nil, lifeSpan: nil, image: BreedImage(url: "https://main.img/1.jpg"), referenceImageId: nil)
        viewModel = BreedDetailViewModel(breed: breed, repository: mockRepo)

        let images = [
            BreedGalleryImage(id: "g1", url: "https://main.img/1.jpg"), // duplicada
            BreedGalleryImage(id: "g2", url: "https://gallery.img/2.jpg"),
            BreedGalleryImage(id: "g3", url: "https://gallery.img/3.jpg")
        ]
        mockRepo.imagesByBreedId["gal"] = images

        // Observa mudanças de isLoadingGallery: cumprir quando voltar a false após ter sido true
        let loadingExpectation = expectation(description: "Gallery loading toggled")
        var didFulfill = false
        var sawLoadingTrue = false
        viewModel.$isLoadingGallery
            .dropFirst()
            .sink { value in
                if value {
                    sawLoadingTrue = true
                } else if sawLoadingTrue && !didFulfill {
                    didFulfill = true
                    loadingExpectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // Quando
        mockRepo.resetCounters()
        viewModel.loadGalleryImages(breedId: "gal", limit: 10)

        wait(for: [loadingExpectation], timeout: TestConstants.defaultExpectationTimeout)

        // Então: imageItems deve conter principal + únicas da galeria, sem duplicados, e selectedIndex reset a 0
        let urls = viewModel.imageItems.map { $0.url }
        XCTAssertEqual(urls.first, "https://main.img/1.jpg")
        XCTAssertTrue(urls.contains("https://gallery.img/2.jpg"))
        XCTAssertTrue(urls.contains("https://gallery.img/3.jpg"))
        XCTAssertEqual(Set(urls).count, urls.count, "Não deve haver URLs duplicadas")
        XCTAssertEqual(viewModel.selectedIndex, 0)
        XCTAssertEqual(mockRepo.fetchBreedImagesCallCount, 1)
        XCTAssertFalse(viewModel.isLoadingGallery)
        XCTAssertNil(viewModel.galleryError)
    }

    func testGalleryErrorSetsGalleryErrorMessage() {
        // Dado: erro ao carregar galeria
        enum DummyError: Error { case galleryFailed }
        mockRepo.error = DummyError.galleryFailed

        let breed = CatBreed(id: "galerr", name: "WithGallery", origin: nil, description: nil, temperament: nil, lifeSpan: nil, image: nil, referenceImageId: "ref1")
        viewModel = BreedDetailViewModel(breed: breed, repository: mockRepo)

        let loadingExpectation = expectation(description: "Gallery loading toggled on error")
        var didFulfill = false
        var sawLoadingTrue = false
        viewModel.$isLoadingGallery
            .dropFirst()
            .sink { value in
                if value {
                    sawLoadingTrue = true
                } else if sawLoadingTrue && !didFulfill {
                    didFulfill = true
                    loadingExpectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // Quando
        mockRepo.resetCounters()
        viewModel.loadGalleryImages(breedId: "galerr", limit: 10)

        wait(for: [loadingExpectation], timeout: TestConstants.defaultExpectationTimeout)

        // Então
        XCTAssertFalse(viewModel.isLoadingGallery)
        XCTAssertNotNil(viewModel.galleryError)
        XCTAssertEqual(mockRepo.fetchBreedImagesCallCount, 1)
    }
}
