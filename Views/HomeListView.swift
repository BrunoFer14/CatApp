import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

struct HomeListView: View {
    @ObservedObject var viewModel: CatBreedsViewModel

    // Cores compatíveis com múltiplas plataformas
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
                ForEach(viewModel.breeds) { breed in
                    NavigationLink(destination: BreedDetailView(breed: breed, viewModel: viewModel)) {
                        HStack(alignment: .center, spacing: 12) {
                            CatImageView(
                                urlString: breed.image?.url ?? breed.referenceImageUrl,
                                width: 90,
                                height: 90,
                                cornerRadius: 12
                            )

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

                            if viewModel.isFavorite(breed) {
                                Image(systemName: "heart.fill")
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(12)
                        .background(cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: shadowColor, radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal)
                    .onAppear {
                        // Paginação: ao chegar ao último item, carrega mais
                        if breed.id == viewModel.breeds.last?.id {
                            viewModel.fetchPage(page: viewModel.currentPage + 1)
                        }
                    }
                }

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
