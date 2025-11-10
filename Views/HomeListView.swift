import SwiftUI
import ComposableArchitecture

/// Home screen view displaying a grid of cat breeds with navigation
/// Follows TCA principles - purely presentational, no business logic
/// All data comes from TCA state, all interactions send actions
struct HomeListView: View {
    /// TCA store containing the home feature state and actions
    let store: StoreOf<HomeFeature>
    
    /// Grid layout configuration for breed tiles
    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: UILayout.gridSpacing), count: UIDimensions.homeGridColumnCount)
    }

    var body: some View {
        /// NavigationStackStore handles TCA-driven navigation
        NavigationStackStore(
            store.scope(state: \.path, action: \.path)
        ) {
            /// Main content observes state changes and sends actions
            WithViewStore(self.store, observe: { $0 }) { viewStore in
                content(viewStore: viewStore)
                    .navigationTitle(UIStrings.Home.title)
                    .onAppear {
                        viewStore.send(.onAppear)
                    }
            }
        } destination: { store in
            /// Handle navigation destinations using SwitchStore
            SwitchStore(store) { state in
                switch state {
                case .breedDetail:
                    BreedDetailView(
                        store: store.scope(
                            state: { $0.breedDetail! },
                            action: { .breedDetail($0) }
                        )
                    )
                }
            }
        }
    }
}

// MARK: - Body composition
/// Breaks down the main view into logical sections
private extension HomeListView {
    @ViewBuilder
    func content(viewStore: ViewStoreOf<HomeFeature>) -> some View {
        /// Show loading state when no breeds are available and initial load hasn't completed
        if viewStore.breeds.isEmpty && !viewStore.hasLoadedFirstPage {
            loadingPlaceholderSection
        } else {
            /// Show breeds grid when data is available
            breedsGridSection(viewStore: viewStore)
        }
    }
}

// MARK: - Sections
/// Reusable view sections for different loading states
private extension HomeListView {
    /// Loading state with shimmer placeholder tiles
    var loadingPlaceholderSection: some View {
        VStack {
            ProgressView(UIStrings.Common.loadingBreeds)
                .progressViewStyle(.circular)
                .padding()
            /// Grid of placeholder tiles to maintain visual consistency
            LazyVGrid(columns: columns, spacing: UILayout.gridSpacing) {
                ForEach(0..<UIDimensions.placeholderItemsCount, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: UILayout.cardCornerRadius, style: .continuous)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: UIDimensions.breedCardHeight)
                        .redacted(reason: .placeholder)
                        .shimmer()
                }
            }
            .padding(.all, UILayout.listPadding)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Main grid section displaying actual breed data
    func breedsGridSection(viewStore: ViewStoreOf<HomeFeature>) -> some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: UILayout.gridSpacing) {
                /// Display each breed with index for pagination tracking
                ForEach(Array(viewStore.breeds.enumerated()), id: \.element.id) { index, breed in
                    breedTileLink(index: index, breed: breed, viewStore: viewStore)
                }

                /// Show loading indicator at bottom when fetching next page
                if viewStore.isLoadingPage {
                    ProgressView()
                        .padding()
                        .gridCellColumns(UIDimensions.homeGridColumnCount)
                }
            }
            .padding(.all, UILayout.listPadding)
        }
    }
}

// MARK: - Components
/// Individual UI components used within the view
private extension HomeListView {
    @ViewBuilder
    func breedTileLink(index: Int, breed: CatBreed, viewStore: ViewStoreOf<HomeFeature>) -> some View {
        /// Button wrapper for breed tile with navigation action
        Button {
            viewStore.send(.tappedBreed(breed))
        } label: {
            /// Breed tile component with favorite toggle functionality
            BreedSquareTile(
                breed: breed,
                isFavorite: viewStore.favoriteIDs.contains(breed.id),
                favoriteAction: { viewStore.send(.toggleFavorite(breed: breed)) },
                cardBackground: Color.gray.opacity(0.1),
                shadowColor: Color.black.opacity(0.1)
            )
        }
        .buttonStyle(.plain)
        .onAppear {
            /// Trigger pagination when tile appears near the end of the list
            onTileAppear(index: index, totalCount: viewStore.breeds.count, viewStore: viewStore)
        }
    }
}

// MARK: - Lifecycle handlers
/// Event handlers for view lifecycle and user interactions
private extension HomeListView {
    /// Handles tile appearance for pagination triggering
    /// - Parameters:
    ///   - index: Current tile index in the list
    ///   - totalCount: Total number of breeds currently loaded
    ///   - viewStore: TCA view store for sending actions
    func onTileAppear(index: Int, totalCount: Int, viewStore: ViewStoreOf<HomeFeature>) {
        /// Calculate threshold for triggering next page load
        let threshold = max(0, totalCount - UILayout.homePrefetchThresholdFromEnd)
        if index >= threshold {
            /// Request next page when approaching the end of loaded data
            viewStore.send(.requestNextPageIfNeeded)
        }
    }
}

// MARK: - Placeholder Extensions
/// Extensions for visual enhancements (shimmer effect placeholder)
private extension View {
    @ViewBuilder
    func shimmer() -> some View { self }
}
