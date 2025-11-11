import Foundation
import SwiftData
import ComposableArchitecture

// A small provider to build a ModelContainer under TCA
protocol ModelContainerProviding {
    func make() throws -> ModelContainer
}

// DependencyKey que expõe o provider.
enum ModelContainerProviderKey: DependencyKey {
    // Container persistente para a app
    static var liveValue: any ModelContainerProviding {
        struct LiveProvider: ModelContainerProviding {
            func make() throws -> ModelContainer {
                try ModelContainer(for: Favorite.self, CachedBreed.self, FavoriteBreedDetail.self)
            }
        }
        return LiveProvider()
    }

    // Container in-memory for tests
    static var testValue: any ModelContainerProviding {
        struct TestProvider: ModelContainerProviding {
            func make() throws -> ModelContainer {
                try ModelContainer(
                    for: Favorite.self, CachedBreed.self, FavoriteBreedDetail.self,
                    configurations: ModelConfiguration(isStoredInMemoryOnly: true)
                )
            }
        }
        return TestProvider()
    }

    // Previews that use live
    static var previewValue: any ModelContainerProviding { liveValue }
}

extension DependencyValues {
    var modelContainerProvider: any ModelContainerProviding {
        get { self[ModelContainerProviderKey.self] }
        set { self[ModelContainerProviderKey.self] = newValue }
    }
}
