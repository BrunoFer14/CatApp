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
        return Color.gray.opacity(UILayout.searchBarFallbackBackgroundOpacity)
        #endif
    }

    var body: some View {
        content
            .onAppear(perform: onAppearDetail)
            // Fullscreen viewer
            .fullScreenCover(isPresented: $detailVM.isPresentingFullscreen) {
                FullscreenImageView(urlString: detailVM.fullscreenURL) {
                    detailVM.dismissFullscreen()
                }
            }
    }
}

// MARK: - Body composition
private extension BreedDetailView {
    @ViewBuilder
    var content: some View {
        Group {
            switch detailVM.state {
            case .idle, .loading:
                loadingSection
            case .error(let message):
                errorSection(message: message)
            case .content(let currentBreed):
                contentSection(currentBreed: currentBreed)
            }
        }
    }
}

// MARK: - Sections
private extension BreedDetailView {
    var loadingSection: some View {
        VStack(spacing: UILayout.sectionSpacing) {
            ProgressView()
                .progressViewStyle(.circular)
                .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    func errorSection(message: String) -> some View {
        ScrollView {
            VStack(spacing: UILayout.sectionSpacing) {
                Text(UIStrings.Common.errorTitle)
                    .font(.title)
                    .bold()
                Text(message)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }

    func contentSection(currentBreed: CatBreed) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: UILayout.sectionSpacing) {
                if !detailVM.imageItems.isEmpty {
                    headerCarouselSection
                } else {
                    fallbackImageSection(currentBreed: currentBreed)
                }

                titleSection(currentBreed: currentBreed)
                infoSection(currentBreed: currentBreed)
                descriptionSection(currentBreed: currentBreed)
                favoriteButtonSection(currentBreed: currentBreed)
            }
            .padding()
        }
        .navigationTitle(currentBreed.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    var headerCarouselSection: some View {
        VStack(spacing: 0) {
            TabView(selection: $detailVM.selectedIndex) {
                ForEach(Array(detailVM.imageItems.enumerated()), id: \.offset) { index, item in
                    CatImageView(
                        urlString: item.url,
                        height: UIDimensions.detailImageHeightPrimary,
                        cornerRadius: UILayout.imageCornerRadius,
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
            .frame(height: UIDimensions.detailImageHeightPrimary)

            carouselControlsSection
                .padding(.horizontal)
                .padding(.top, UILayout.gridSpacing)
        }
    }

    var carouselControlsSection: some View {
        HStack(spacing: UILayout.gridSpacing) {
            Button {
                withAnimation {
                    detailVM.goPrev()
                }
            } label: {
                Image(systemName: UIStrings.Icons.chevronLeft)
                    .font(.title2)
                    .foregroundColor(.primary)
                    .padding(UILayout.buttonPadding)
                    .background(
                        Circle()
                            .fill(Color.black.opacity(UILayout.circleButtonBackgroundOpacity))
                    )
            }
            .buttonStyle(.plain)
            .disabled(detailVM.selectedIndex == UIConfig.Pagination.initialPageIndex)

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
                Image(systemName: UIStrings.Icons.chevronRight)
                    .font(.title2)
                    .foregroundColor(.primary)
                    .padding(UILayout.buttonPadding)
                    .background(
                        Circle()
                            .fill(Color.black.opacity(UILayout.circleButtonBackgroundOpacity))
                    )
            }
            .buttonStyle(.plain)
            .disabled(detailVM.selectedIndex >= detailVM.imageItems.count - 1)
        }
    }

    func fallbackImageSection(currentBreed: CatBreed) -> some View {
        CatImageView(
            urlString: currentBreed.image?.url ?? currentBreed.referenceImageUrl,
            height: UIDimensions.detailImageHeightFallback,
            cornerRadius: UILayout.imageCornerRadius,
            contentMode: .fill
        )
        .contentShape(Rectangle())
        .onTapGesture {
            if let url = currentBreed.image?.url ?? currentBreed.referenceImageUrl {
                detailVM.fullscreenURL = url
                detailVM.isPresentingFullscreen = true
            }
        }
        .frame(maxWidth: .infinity)
    }

    func titleSection(currentBreed: CatBreed) -> some View {
        Text(currentBreed.name)
            .font(.largeTitle)
            .bold()
    }

    func infoSection(currentBreed: CatBreed) -> some View {
        VStack(alignment: .leading, spacing: UILayout.searchRowVerticalSpacing) {
            if let origin = currentBreed.origin {
                Text("\(UIStrings.Detail.originPrefix) \(origin)")
                    .font(.subheadline)
            }

            if let temperament = currentBreed.temperament {
                Text("\(UIStrings.Detail.temperamentPrefix) \(temperament)")
                    .font(.subheadline)
            }

            if let lifeSpan = currentBreed.lifeSpan {
                Text("\(UIStrings.Detail.lifeSpanPrefix) \(lifeSpan) \(UIStrings.Common.years)")
                    .font(.subheadline)
            }
        }
    }

    func descriptionSection(currentBreed: CatBreed) -> some View {
        Group {
            if let description = currentBreed.description {
                Text(description)
                    .padding(.top, UILayout.textTopPaddingSmall)
            }
        }
    }

    func favoriteButtonSection(currentBreed: CatBreed) -> some View {
        Button(action: {
            viewModel.toggleFavorite(for: currentBreed)
        }) {
            HStack(spacing: UILayout.tileContentSpacing) {
                Image(systemName: viewModel.isFavorite(currentBreed) ? UIStrings.Icons.heartFill : UIStrings.Icons.heart)
                    .foregroundColor(.red)
                Text(viewModel.isFavorite(currentBreed) ? UIStrings.Detail.removeFromFavorites : UIStrings.Detail.addToFavorites)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(buttonBackground)
            .cornerRadius(UILayout.defaultCornerRadius)
        }
        .padding(.top, UILayout.textTopPaddingMedium)
    }
}

// MARK: - Lifecycle handlers
private extension BreedDetailView {
    func onAppearDetail() {
        // VM decide o que carregar e como construir imagens
        detailVM.prepare(for: breed)
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
                    cornerRadius: UILayout.fullscreenImageCornerRadius,
                    contentMode: .fit
                )
                .id(urlString) // força reload quando a URL muda
                .frame(width: side, height: side, alignment: .center)

                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        Spacer()
                        Button(action: onClose) {
                            Image(systemName: UIStrings.Icons.closeCircleFill)
                                .font(.largeTitle)
                                .foregroundColor(.white.opacity(UILayout.fullscreenCloseButtonOpacity))
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
