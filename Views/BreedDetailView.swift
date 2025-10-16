import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

/// Ecrã de detalhes de uma raça.
struct BreedDetailView: View {
    let breed: CatBreed
    @ObservedObject var viewModel: CatBreedsViewModel

    @StateObject private var detailVM = BreedDetailViewModel()

    // Cor do botão (compatível com várias plataformas)
    private var buttonBackground: Color {
        #if canImport(UIKit)
        return Color(UIColor.systemGray6)
        #elseif canImport(AppKit)
        return Color(NSColor.windowBackgroundColor)
        #else
        return Color.gray.opacity(0.12)
        #endif
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                // Carrossel de imagens já pronto (main + galeria deduplicada)
                if !detailVM.imageItems.isEmpty {
                    VStack(spacing: 0) {
                        TabView(selection: $detailVM.selectedIndex) {
                            ForEach(Array(detailVM.imageItems.enumerated()), id: \.offset) { index, item in
                                CatImageView(
                                    urlString: item.url,
                                    height: 260,
                                    cornerRadius: 12,
                                    contentMode: .fill
                                )
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    detailVM.select(index: index)
                                    detailVM.presentFullscreenForSelected()
                                }
                                .tag(index)
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .automatic))
                        .frame(height: 260)

                        HStack {
                            Button {
                                withAnimation {
                                    detailVM.goPrev()
                                }
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(.title2)
                                    .foregroundColor(.primary)
                                    .padding(10)
                                    .background(
                                        Circle()
                                            .fill(Color.black.opacity(0.08))
                                    )
                            }
                            .buttonStyle(.plain)
                            .disabled(detailVM.selectedIndex == 0)

                            Spacer()

                            if detailVM.isLoadingGallery {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .padding(.horizontal)
                            }

                            Spacer()

                            Button {
                                withAnimation {
                                    detailVM.goNext()
                                }
                            } label: {
                                Image(systemName: "chevron.right")
                                    .font(.title2)
                                    .foregroundColor(.primary)
                                    .padding(10)
                                    .background(
                                        Circle()
                                            .fill(Color.black.opacity(0.08))
                                    )
                            }
                            .buttonStyle(.plain)
                            .disabled(detailVM.selectedIndex >= detailVM.imageItems.count - 1)
                        }
                        .padding(.horizontal)
                        .padding(.top, 12)
                    }
                } else {
                    // Fallback se não houver imagem nenhuma
                    CatImageView(
                        urlString: breed.image?.url ?? breed.referenceImageUrl,
                        height: 200,
                        cornerRadius: 12,
                        contentMode: .fill
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // Se houver URL válido, abrir fullscreen
                        if let url = breed.image?.url ?? breed.referenceImageUrl {
                            detailVM.fullscreenURL = url
                            detailVM.isPresentingFullscreen = true
                        }
                    }
                    .frame(maxWidth: .infinity)
                }

                // Título
                Text(breed.name)
                    .font(.largeTitle)
                    .bold()

                // Campos informativos
                if let origin = breed.origin {
                    Text("🌍 Origin: \(origin)")
                        .font(.subheadline)
                }

                if let temperament = breed.temperament {
                    Text("😺 Temperament: \(temperament)")
                        .font(.subheadline)
                }

                if let lifeSpan = breed.lifeSpan {
                    Text("⏳ Life span: \(lifeSpan) years")
                        .font(.subheadline)
                }

                if let description = breed.description {
                    Text(description)
                        .padding(.top, 8)
                }

                // Botão para marcar/desmarcar favorito
                Button(action: {
                    viewModel.toggleFavorite(for: breed)
                }) {
                    HStack {
                        Image(systemName: viewModel.isFavorite(breed) ? "heart.fill" : "heart")
                            .foregroundColor(.red)
                        Text(viewModel.isFavorite(breed) ? "Remove from Favorites" : "Add to Favorites")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(buttonBackground)
                    .cornerRadius(8)
                }
                .padding(.top, 16)
            }
            .padding()
        }
        .navigationTitle(breed.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // VM decide o que carregar e como construir imagens
            detailVM.prepare(for: breed)
        }
        // Fullscreen viewer
        .fullScreenCover(isPresented: $detailVM.isPresentingFullscreen) {
            FullscreenImageView(urlString: detailVM.fullscreenURL) {
                detailVM.dismissFullscreen()
            }
        }
    }
}

// MARK: - Fullscreen Image Viewer
private struct FullscreenImageView: View {
    let urlString: String?
    let onClose: () -> Void

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)

            ZStack {
                Color.black.ignoresSafeArea()

                CatImageView(
                    urlString: urlString,
                    width: side,
                    height: side,
                    cornerRadius: 0,
                    contentMode: .fit
                )
                .id(urlString) // força reload quando a URL muda
                .frame(width: side, height: side, alignment: .center)

                VStack {
                    HStack {
                        Spacer()
                        Button(action: onClose) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.largeTitle)
                                .foregroundColor(.white.opacity(0.9))
                                .padding()
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer()
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }
}
