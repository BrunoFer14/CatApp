import CoreGraphics

enum UILayout {
    // Spacing and padding
    static let gridSpacing: CGFloat = 12
    static let listPadding: CGFloat = 12
    static let buttonPadding: CGFloat = 10
    static let sectionSpacing: CGFloat = 16
    static let textTopPaddingSmall: CGFloat = 8
    static let textTopPaddingMedium: CGFloat = 16

    // BreedSquareTile specific
    static let tileContentSpacing: CGFloat = 8
    static let iconButtonPadding: CGFloat = 8
    static let cardContentPadding: CGFloat = 10
    static let titleLineLimit: Int = 2
    static let subtitleLineLimit: Int = 1

    // Visual constants
    static let circleButtonBackgroundOpacity: CGFloat = 0.08
    static let circleButtonFillOpacity: CGFloat = 0.90
    static let circleButtonShadowOpacity: CGFloat = 0.15
    static let circleButtonShadowRadius: CGFloat = 2
    static let circleButtonShadowOffsetX: CGFloat = 0
    static let circleButtonShadowOffsetY: CGFloat = 1

    // Card shadow
    static let cardShadowRadius: CGFloat = 6
    static let cardShadowOffsetX: CGFloat = 0
    static let cardShadowOffsetY: CGFloat = 2

    // SearchBar fallback visuals
    static let searchBarFallbackBackgroundOpacity: CGFloat = 0.12

    // Fullscreen controls
    static let fullscreenCloseButtonOpacity: CGFloat = 0.90

    // Home prefetch
    static let homePrefetchThresholdFromEnd: Int = 4

    // Platform-specific opacities
    static let macOSShadowOpacity: CGFloat = 0.12

    // Preview visual constants
    static let previewCardBackgroundOpacity: CGFloat = 0.15
    static let previewShadowOpacity: CGFloat = 0.08

    // Corners
    static let cardCornerRadius: CGFloat = 14
    static let imageCornerRadius: CGFloat = 12
    static let defaultCornerRadius: CGFloat = 8

    // Favorites
    static let favoriteThumbnailCornerRadius: CGFloat = 6

    // Search row layout
    static let searchThumbnailCornerRadius: CGFloat = 8
    static let searchRowHorizontalSpacing: CGFloat = 12
    static let searchRowVerticalSpacing: CGFloat = 4
    static let searchRowVerticalPadding: CGFloat = 4

    // Detail screen specific
    static let fullscreenImageCornerRadius: CGFloat = 0
}
