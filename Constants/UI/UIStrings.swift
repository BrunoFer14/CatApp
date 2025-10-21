import Foundation

enum UIStrings {

    enum Common {
        static let loadingBreeds = "Loading breeds…"
        static let errorTitle = "Error"
        static let years = "years"
        static let favorites = "Favorites"
        static let searchBreeds = "Search Breeds"
        static let searchPrompt = "Search breeds..."
        static let catBreedsTitle = "Cat Breeds"
        static let noFavoritesYet = "No favorites yet 🐾"
        static let averageLifeSpanOfFavoritesPrefix = "Average life span of favorites:"
    }

    enum Detail {
        static let originPrefix = "🌍 Origin:"
        static let temperamentPrefix = "😺 Temperament:"
        static let lifeSpanPrefix = "⏳ Life span:"
        static let addToFavorites = "Add to Favorites"
        static let removeFromFavorites = "Remove from Favorites"
        static let notFoundError = "Erro: Raça não encontrada."
    }

    enum Favorites {
        static let title = "Favorites"
    }

    enum Home {
        static let title = "Cat Breeds"
    }

    enum Search {
        static let title = "Search Breeds"
        // prompt compartilhado está em Common.searchPrompt
    }

    enum Icons {
        static let heart = "heart"
        static let heartFill = "heart.fill"
        static let chevronLeft = "chevron.left"
        static let chevronRight = "chevron.right"
        static let closeCircleFill = "xmark.circle.fill"
    }
}
