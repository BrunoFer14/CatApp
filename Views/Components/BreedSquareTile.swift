import SwiftUI

struct BreedSquareTile: View {
    let breed: CatBreed
    let isFavorite: Bool
    let favoriteAction: () -> Void
    let cardBackground: Color
    let shadowColor: Color

    // Tile layout constants
    private let cornerRadius: CGFloat = UILayout.cardCornerRadius
    private let imageCornerRadius: CGFloat = UILayout.imageCornerRadius
    private let imageHeight: CGFloat = UIDimensions.tileImageHeight

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                // Image (uses URL from breed model) - full width edge-to-edge
                CatImageView(
                    urlString: breed.displayImageUrl ?? breed.referenceImageUrl,
                    width: UIDimensions.breedCardWidth, // Full card width
                    height: imageHeight,
                    cornerRadius: cornerRadius, // Match card corner radius
                    contentMode: .fill
                )
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: cornerRadius,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: cornerRadius
                    )
                )

                // Favorite button floating over the image
                Button(action: favoriteAction) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(.red)
                        .padding(UILayout.iconButtonPadding)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(UILayout.circleButtonFillOpacity))
                                .shadow(
                                    color: Color.black.opacity(UILayout.circleButtonShadowOpacity),
                                    radius: UILayout.circleButtonShadowRadius,
                                    x: UILayout.circleButtonShadowOffsetX,
                                    y: UILayout.circleButtonShadowOffsetY
                                )
                        )
                        .padding(UILayout.iconButtonPadding)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isFavorite ? "Remove from Favorites" : "Add to Favorites")
            }

            // Fixed height text section for consistent alignment
            VStack(alignment: .leading, spacing: 4) {
                // Title with fixed size for consistent wrapping
                Text(breed.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(UILayout.titleLineLimit)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Optional origin as subtitle
                if let origin = breed.origin, !origin.isEmpty {
                    Text(origin)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(UILayout.subtitleLineLimit)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(height: UIDimensions.tileTextAreaHeight, alignment: .top) // Fixed height for text area
            .padding(.horizontal, UILayout.cardContentPadding) // Only horizontal padding for text
            .padding(.top, UILayout.tileContentSpacing) // Top spacing from image

            Spacer(minLength: 0)
        }
        .padding(.bottom, UILayout.cardContentPadding) // Only bottom padding
        .frame(
            width: UIDimensions.breedCardWidth,   // Fixed width for consistent grid
            height: UIDimensions.breedCardHeight  // Fixed height
        )
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .shadow(
            color: shadowColor,
            radius: UILayout.cardShadowRadius,
            x: UILayout.cardShadowOffsetX,
            y: UILayout.cardShadowOffsetY
        )
        .contentShape(Rectangle())
    }
}

#Preview {
    let sample = CatBreed(
        id: "abys",
        name: "Abyssinian",
        origin: "Egypt",
        description: "Active, Energetic, Independent, Intelligent, Gentle",
        temperament: "Active, Energetic",
        lifeSpan: "14 - 15",
        image: BreedImage(url: "https://cdn2.thecatapi.com/images/0XYvRd7oD.jpg"),
        referenceImageId: "0XYvRd7oD"
    )

    return BreedSquareTile(
        breed: sample,
        isFavorite: true,
        favoriteAction: {},
        cardBackground: Color.gray.opacity(UILayout.previewCardBackgroundOpacity),
        shadowColor: Color.black.opacity(UILayout.previewShadowOpacity)
    )
    .padding()
}
