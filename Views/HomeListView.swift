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

    // 2 colunas flexíveis para manter pares simétricos
    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    // Cores adaptadas à plataforma
    private var cardBackground: Color {
        #if canImport(UIKit)
        return Color(UIColor.secondarySystemBackground)
        #elseif canImport(AppKit)
        return Color(NSColor.windowBackgroundColor)
        #else
        return Color.gray.opacity(0.15)
        #endif
    }

    private var shadowColor: Color {
        #if canImport(UIKit)
        return Color.black.opacity(0.08)
        #else
        return Color.black.opacity(0.12)
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
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(0..<6, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(cardBackground)
                                .frame(height: 180)
                                .redacted(reason: .placeholder)
                                .shimmer()
                        }
                    }
                    .padding(.all, 12)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
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
                                // Prefetch when reaching near the end (last 4 items)
                                let threshold = max(0, cachedBreeds.count - 4)
                                if index >= threshold {
                                    viewModel.requestNextPageIfNeeded()
                                }
                            }
                        }

                        if viewModel.isLoadingPage {
                            ProgressView()
                                .padding()
                                .gridCellColumns(2)
                        }
                    }
                    .padding(.all, 12)
                }
            }
        }
        .navigationTitle("Cat Breeds")
        .onAppear {
            if cachedBreeds.isEmpty && !viewModel.isLoadingPage && !viewModel.hasLoadedFirstPage {
                viewModel.fetchPage(page: 0)
            }
        }
    }
}

// Remova este modificador se não tiver implementação de shimmer
private extension View {
    @ViewBuilder
    func shimmer() -> some View { self }
}
