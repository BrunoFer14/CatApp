import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

/// Lista principal de raças com paginação ao fazer scroll.
struct HomeListView: View {
    @ObservedObject var viewModel: CatBreedsViewModel

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

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Para cada raça, mostra um cartão
                ForEach(viewModel.breeds) { breed in
                    NavigationLink(destination: BreedDetailView(breed: breed, viewModel: viewModel)) {
                        HStack(alignment: .center, spacing: 12) {
                            // Imagem da raça (usa URL direta ou derivada do referenceImageId)
                            CatImageView(
                                urlString: breed.image?.url ?? breed.referenceImageUrl,
                                width: 90,
                                height: 90,
                                cornerRadius: 12
                            )

                            // Nome, origem e temperamento
                            VStack(alignment: .leading, spacing: 6) {
                                Text(breed.name)
                                    .font(.headline)

                                if let origin = breed.origin, !origin.isEmpty {
                                    Text(origin)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }

                                if let temperament = breed.temperament, !temperament.isEmpty {
                                    Text(temperament)
                                        .font(.footnote)
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                }
                            }

                            Spacer()

                            // Botão de favorito na lista principal
                            Button {
                                viewModel.toggleFavorite(for: breed)
                            } label: {
                                Image(systemName: viewModel.isFavorite(breed) ? "heart.fill" : "heart")
                                    .foregroundColor(.red)
                                    .imageScale(.medium)
                                    .padding(6)
                            }
                            .buttonStyle(.plain)
                            .contentShape(Rectangle())
                            .accessibilityLabel(viewModel.isFavorite(breed) ? "Remove from favorites" : "Add to favorites")
                        }
                        .padding(12)
                        .background(cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: shadowColor, radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal)
                    .onAppear {
                        // Paginação: quando o último item aparece, carrega a próxima página
                        if breed.id == viewModel.breeds.last?.id {
                            viewModel.fetchPage(page: viewModel.currentPage + 1)
                        }
                    }
                }

                // Indicador de carregamento de página
                if viewModel.isLoadingPage {
                    ProgressView()
                        .padding()
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Cat Breeds")
    }
}
