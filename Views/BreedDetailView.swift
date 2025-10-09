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

    @State private var currentIndex: Int = 0

    // Fullscreen image state
    @State private var showFullscreen = false
    @State private var fullscreenURL: String?
    @State private var fullscreenImage: Image? // imagem já carregada (para funcionar offline)

    // Mantém uma cache temporária das imagens carregadas por índice
    @State private var loadedImagesByIndex: [Int: Image] = [:]

    // Constrói a lista de imagens para o carrossel:
    // - Primeira imagem: a mesma usada na lista (principal)
    // - Seguem as imagens da galeria, removendo duplicados por URL
    private var combinedImages: [String] {
        var urls: [String] = []
        if let main = breed.image?.url ?? breed.referenceImageUrl {
            urls.append(main)
        }
        let gallery = detailVM.galleryImages.map { $0.url }
        // Deduplicar mantendo ordem (main primeiro)
        var seen = Set<String>()
        var result: [String] = []
        for url in urls + gallery {
            if !seen.contains(url) {
                seen.insert(url)
                result.append(url)
            }
        }
        return result
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                // Carrossel de imagens (inclui a principal como primeira)
                if !combinedImages.isEmpty {
                    VStack(spacing: 0) {
                        TabView(selection: $currentIndex) {
                            ForEach(Array(combinedImages.enumerated()), id: \.offset) { index, url in
                                // Top-aligned: usar fill + clipped e frame fixo
                                CatImageView(
                                    urlString: url,
                                    height: 260,
                                    cornerRadius: 12,
                                    contentMode: .fill,
                                    loadedImage: Binding(
                                        get: { loadedImagesByIndex[index] },
                                        set: { newValue in
                                            if let img = newValue {
                                                loadedImagesByIndex[index] = img
                                            }
                                        }
                                    )
                                )
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    // Preferir a imagem já carregada para fullscreen (funciona offline)
                                    fullscreenImage = loadedImagesByIndex[index]
                                    fullscreenURL = url
                                    showFullscreen = true
                                }
                                .tag(index)
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .automatic))
                        .frame(height: 260)

                        // Bigger arrows with more spacing
                        HStack {
                            Button {
                                withAnimation {
                                    currentIndex = max(0, currentIndex - 1)
                                }
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(.title2) // larger icon
                                    .foregroundColor(.primary)
                                    .padding(10)
                                    .background(
                                        Circle()
                                            .fill(Color.black.opacity(0.08))
                                    )
                            }
                            .buttonStyle(.plain)
                            .disabled(currentIndex == 0)

                            Spacer()

                            // Optional loading indicator to hint gallery fetch
                            if detailVM.isLoadingGallery {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .padding(.horizontal)
                            }

                            Spacer()

                            Button {
                                withAnimation {
                                    currentIndex = min(combinedImages.count - 1, currentIndex + 1)
                                }
                            } label: {
                                Image(systemName: "chevron.right")
                                    .font(.title2) // larger icon
                                    .foregroundColor(.primary)
                                    .padding(10)
                                    .background(
                                        Circle()
                                            .fill(Color.black.opacity(0.08))
                                    )
                            }
                            .buttonStyle(.plain)
                            .disabled(currentIndex >= combinedImages.count - 1)
                        }
                        .padding(.horizontal)
                        .padding(.top, 12) // extra spacing from the image
                    }
                } else {
                    // Fallback se não houver imagem nenhuma
                    CatImageView(
                        urlString: breed.image?.url ?? breed.referenceImageUrl,
                        height: 200,
                        cornerRadius: 12,
                        contentMode: .fill,
                        loadedImage: Binding(
                            get: { loadedImagesByIndex[-1] },
                            set: { newValue in
                                if let img = newValue {
                                    loadedImagesByIndex[-1] = img
                                }
                            }
                        )
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        fullscreenImage = loadedImagesByIndex[-1]
                        fullscreenURL = breed.image?.url ?? breed.referenceImageUrl
                        if fullscreenImage != nil || fullscreenURL != nil {
                            showFullscreen = true
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

                if let lifeSpan = breed.life_span {
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
            // Carrega detalhes se necessário
            detailVM.loadBreedDetail(id: breed.id)
            // Carrega galeria de imagens para o carrossel
            detailVM.loadGalleryImages(breedId: breed.id, limit: 10)
            // Garantir que começamos na imagem principal (índice 0)
            currentIndex = 0
        }
        // Sempre que a galeria é atualizada, garantimos que o índice fica no 0 (imagem principal)
        .onChange(of: detailVM.galleryImages) {
            currentIndex = 0
        }
        // Fullscreen viewer
        .fullScreenCover(isPresented: $showFullscreen) {
            FullscreenImageView(urlString: fullscreenURL, inlineImage: fullscreenImage) {
                showFullscreen = false
            }
        }
    }
}

// MARK: - Fullscreen Image Viewer
private struct FullscreenImageView: View {
    let urlString: String?
    let inlineImage: Image?
    let onClose: () -> Void

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)

            ZStack {
                Color.black.ignoresSafeArea()

                if let inlineImage {
                    // Usa a imagem já carregada (funciona offline)
                    inlineImage
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: side, height: side, alignment: .center)
                } else {
                    // Fallback para carregar por URL (se disponível/online)
                    CatImageView(
                        urlString: urlString,
                        width: side,
                        height: side,
                        cornerRadius: 0,
                        contentMode: .fit
                    )
                    .frame(width: side, height: side, alignment: .center)
                }

                // Close button
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
