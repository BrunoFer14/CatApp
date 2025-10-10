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
                // Estado de loading inicial: pode ser um skeleton mais elaborado
                VStack {
                    ProgressView("Loading breeds…")
                        .progressViewStyle(.circular)
                        .padding()
                    // Opcional: placeholders da grelha
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(0..<6, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(cardBackground)
                                .frame(height: 180)
                                .redacted(reason: .placeholder)
                                .shimmer() // se tiver um modifier de shimmer; caso não, remova
                        }
                    }
                    .padding(.all, 12)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(cachedBreeds, id: \.id) { cached in
                            // Mapeia para CatBreed apenas para navegação/detalhe e componentes já existentes
                            let breed = CatBreed(
                                id: cached.id,
                                name: cached.name,
                                origin: cached.origin,
                                description: cached.breedDescription,
                                temperament: cached.temperament,
                                life_span: cached.life_span,
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
                                // Paginação: quando o último item aparece, carrega a próxima página
                                if cached.id == cachedBreeds.last?.id {
                                    viewModel.fetchPage(page: viewModel.currentPage + 1)
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
            // Garante que a primeira página é pedida se o store estiver vazio
            if cachedBreeds.isEmpty && !viewModel.isLoadingPage && !viewModel.hasLoadedFirstPage {
                viewModel.fetchPage(page: 0)
            }
        }
    }
}

/// Cartão quadrado simétrico para grelha 2-colunas.
/// - Imagem quadrada em cima
/// - Nome centrado
/// - Botão de favorito centrado em baixo do nome
private struct BreedSquareTile: View {
    let breed: CatBreed
    let isFavorite: Bool
    let favoriteAction: () -> Void
    let cardBackground: Color
    let shadowColor: Color

    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { geo in
                let side = geo.size.width
                CatImageView(
                    urlString: breed.image?.url ?? breed.referenceImageUrl,
                    width: side,
                    height: side,
                    cornerRadius: 12,
                    contentMode: .fill
                )
            }
            .aspectRatio(1, contentMode: .fit)

            Text(breed.name)
                .font(.headline)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .center)

            Button(action: favoriteAction) {
                HStack(spacing: 6) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(.red)
                    Text(isFavorite ? "Remove favorite" : "Add favorite")
                        .font(.footnote)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .background(cardBackground.opacity(0.7))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .center)
            .accessibilityLabel(isFavorite ? "Remove from favorites" : "Add to favorites")
        }
        .padding(10)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: shadowColor, radius: 4, x: 0, y: 2)
    }
}

// Remova este modificador se não tiver implementação de shimmer
private extension View {
    @ViewBuilder
    func shimmer() -> some View { self }
}
