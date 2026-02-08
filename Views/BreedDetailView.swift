import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif
import ComposableArchitecture

struct BreedDetailView: View {
    let store: StoreOf<BreedDetailReducer>

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
        WithViewStore(store, observe: { $0 }) { viewStore in
            content(viewStore: viewStore)
                .onAppear {
                    viewStore.send(.onAppear)
                }
                #if os(iOS)
                .fullScreenCover(
                    isPresented: viewStore.binding(
                        get: \.isPresentingFullscreen,
                        send: { $0 ? .presentFullscreenForSelected : .dismissFullscreen }
                    )
                ) {
                    FullscreenImageView(urlString: viewStore.fullscreenURL) {
                        viewStore.send(.dismissFullscreen)
                    }
                }
                #elseif os(macOS)
                .sheet(
                    isPresented: viewStore.binding(
                        get: \.isPresentingFullscreen,
                        send: { $0 ? .presentFullscreenForSelected : .dismissFullscreen }
                    )
                ) {
                    FullscreenImageView(urlString: viewStore.fullscreenURL) {
                        viewStore.send(.dismissFullscreen)
                    }
                }
                #endif
        }
    }
}

// MARK: - Body composition
private extension BreedDetailView {
    @ViewBuilder
    func content(viewStore: ViewStoreOf<BreedDetailReducer>) -> some View {
        Group {
            switch viewStore.screenState {
            case .loading:
                loadingSection
            case .error(let message):
                errorSection(message: message)
            case .content:
                contentSection(viewStore: viewStore, currentBreed: viewStore.breed)
            }
        }
    }
}

// MARK: - Sections
private extension BreedDetailView {
    var loadingSection: some View {
        VStack(spacing: UILayout.sectionSpacing) {
            ProgressView.standardCircular
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

    func contentSection(viewStore: ViewStoreOf<BreedDetailReducer>, currentBreed: CatBreed) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: UILayout.sectionSpacing) {
                if !viewStore.imageItems.isEmpty {
                    headerCarouselSection(viewStore: viewStore)
                } else {
                    fallbackImageSection(currentBreed: currentBreed, viewStore: viewStore)
                }

                titleSection(currentBreed: currentBreed)
                infoSection(currentBreed: currentBreed)
                descriptionSection(currentBreed: currentBreed)
                favoriteButtonSection(viewStore: viewStore)
            }
            .padding()
        }
        .navigationTitle(currentBreed.name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    func headerCarouselSection(viewStore: ViewStoreOf<BreedDetailReducer>) -> some View {
        VStack(spacing: 0) {
            TabView(
                selection: viewStore.binding(
                    get: \.selectedIndex,
                    send: { .selectImage(index: $0) }
                )
            ) {
                ForEach(Array(viewStore.imageItems.enumerated()), id: \.element.id) { index, item in
                    CatImageView(
                        urlString: item.url,
                        height: UIDimensions.detailImageHeightPrimary,
                        cornerRadius: UILayout.imageCornerRadius,
                        contentMode: .fill
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewStore.send(.selectImage(index: index))
                        viewStore.send(.presentFullscreenForSelected)
                    }
                    .tag(index)
                }
            }
            #if os(iOS)
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            #endif
            .frame(height: UIDimensions.detailImageHeightPrimary)

            carouselControlsSection(viewStore: viewStore)
                .padding(.horizontal)
                .padding(.top, UILayout.gridSpacing)
        }
    }

    func carouselControlsSection(viewStore: ViewStoreOf<BreedDetailReducer>) -> some View {
        HStack(spacing: UILayout.gridSpacing) {
            carouselNavigationButton(
                icon: UIStrings.Icons.chevronLeft,
                action: { withAnimation { _ = viewStore.send(.goPrev) } },
                isDisabled: viewStore.selectedIndex == UIConfig.Pagination.initialPageIndex
            )

            Spacer()

            if viewStore.isLoadingGallery {
                ProgressView.standardCircular
                    .padding(.horizontal, 0)
            }

            Spacer()

            carouselNavigationButton(
                icon: UIStrings.Icons.chevronRight,
                action: { withAnimation { _ = viewStore.send(.goNext) } },
                isDisabled: viewStore.selectedIndex >= max(0, viewStore.imageItems.count - 1)
            )
        }
    }
    
    @ViewBuilder
    private func carouselNavigationButton(
        icon: String,
        action: @escaping () -> Void,
        isDisabled: Bool
    ) -> some View {
        Button {
            action()
        } label: {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.primary)
                .padding(UILayout.buttonPadding)
                .background(
                    Circle()
                        .fill(Color.black.opacity(UILayout.circleButtonBackgroundOpacity))
                )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }

    func fallbackImageSection(currentBreed: CatBreed, viewStore: ViewStoreOf<BreedDetailReducer>) -> some View {
        CatImageView(
            urlString: currentBreed.image?.url ?? currentBreed.referenceImageUrl,
            height: UIDimensions.detailImageHeightFallback,
            cornerRadius: UILayout.imageCornerRadius,
            contentMode: .fill
        )
        .contentShape(Rectangle())
        .onTapGesture {
            if currentBreed.image?.url ?? currentBreed.referenceImageUrl != nil {
                viewStore.send(.selectImage(index: 0))
                viewStore.send(.presentFullscreenForSelected)
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

    func favoriteButtonSection(viewStore: ViewStoreOf<BreedDetailReducer>) -> some View {
        Button(action: {
            viewStore.send(.toggleFavorite)
        }) {
            HStack(spacing: UILayout.tileContentSpacing) {
                Image(systemName: viewStore.isFavorite ? UIStrings.Icons.heartFill : UIStrings.Icons.heart)
                    .foregroundColor(.red)
                    .scaleEffect(viewStore.isFavorite ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewStore.isFavorite)
                Text(viewStore.isFavorite ? UIStrings.Detail.removeFromFavorites : UIStrings.Detail.addToFavorites)
                    .animation(.easeInOut(duration: 0.2), value: viewStore.isFavorite)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(buttonBackground)
            .scaleEffect(viewStore.isFavorite ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewStore.isFavorite)
            .cornerRadius(UILayout.defaultCornerRadius)
        }
        .padding(.top, UILayout.textTopPaddingMedium)
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
                .id(urlString)
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
