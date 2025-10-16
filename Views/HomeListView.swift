import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif
import SwiftData

/// Lista principal de raças em grelha 2-colunas com cartões quadrados.
/// Agora lê diretamente do SwiftData via @Query (CachedBreed) e usa o ViewModel apenas para paginar/sincronizar.
struct HomeListView: View {
    @ObservedObject var viewModel: CatBreedsViewModel

    // Colunas flexíveis para manter pares simétricos
    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: UILayout.gridSpacing), count: UIDimensions.homeGridColumnCount)
    }

    // Cores adaptadas à plataforma
    private var cardBackground: Color {
        #if canImport(UIKit)
        return Color(UIColor.secondarySystemBackground)
        #elseif canImport(AppKit)
        return Color(NSColor.windowBackgroundColor)
        #else
        return Color.gray.opacity(UILayout.previewCardBackgroundOpacity)
        #endif
    }

    private var shadowColor: Color {
        #if canImport(UIKit)
        return Color.black.opacity(UILayout.previewShadowOpacity)
        #else
        return Color.black.opacity(UILayout.macOSShadowOpacity)
        #endif
    }

    // Lê diretamente do SwiftData, ordenado pelo orderIndex (ordem de paginação)
    @Query(sort: [SortDescriptor(\CachedBreed.orderIndex, order: .forward)])
    private var cachedBreeds: [CachedBreed]

    var body: some View {
        Group {
            if cachedBreeds.isEmpty && !viewModel.hasLoadedFirstPage {
                VStack {
                    ProgressView("Loading breeds…")
                        .progressViewStyle(.circular)
                        .padding()
                    LazyVGrid(columns: columns, spacing: UILayout.gridSpacing) {
                        ForEach(0..<UIDimensions.placeholderItemsCount, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: UILayout.cardCornerRadius, style: .continuous)
                                .fill(cardBackground)
                                .frame(height: UIDimensions.breedCardHeight)
                                .redacted(reason: .placeholder)
                                .shimmer()
                        }
                    }
                    .padding(.all, UILayout.listPadding)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: UILayout.gridSpacing) {
                        ForEach(Array(cachedBreeds.enumerated()), id: \.element.id) { index, cached in
                            let breed = CatBreed(
                                id: cached.id,
                                name: cached.name,
                                origin: cached.origin,
                                description: cached.breedDescription,
                                temperament: cached.temperament,
                                lifeSpan: cached.lifeSpan,
                                image: BreedImage(url: cached.imageUrl),
                                referenceImageId: nil
                            )

                            NavigationLink(destination: BreedDetailView(breed: breed, viewModel: viewModel)) {
                                BreedSquareTile(
                                    breed: breed,
                                    isFavorite: viewModel.isFavorite(breed),
                                    favoriteAction: { viewModel.toggleFavorite(for: breed) },
                                    cardBackground: cardBackground,
                                    shadowColor: Color(shadowColor)
                                )
                            }
                            .buttonStyle(.plain)
                            .onAppear {
                                // Prefetch when reaching near the end
                                let threshold = max(0, cachedBreeds.count - UILayout.homePrefetchThresholdFromEnd)
                                if index >= threshold {
                                    viewModel.requestNextPageIfNeeded()
                                }
                            }
                        }

                        if viewModel.isLoadingPage {
                            ProgressView()
                                .padding()
                                .gridCellColumns(UIDimensions.homeGridColumnCount)
                        }
                    }
                    .padding(.all, UILayout.listPadding)
                }
            }
        }
        .navigationTitle("Cat Breeds")
        .onAppear {
            if cachedBreeds.isEmpty && !viewModel.isLoadingPage && !viewModel.hasLoadedFirstPage {
                viewModel.fetchPage(page: UIDimensions.initialPageIndex)
            }
        }
    }
}

// Remova este modificador se não tiver implementação de shimmer
private extension View {
    @ViewBuilder
    func shimmer() -> some View { self }
}
