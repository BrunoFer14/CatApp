import SwiftUI
import ComposableArchitecture

/// Home screen view displaying a grid of cat breeds with navigation
/// All data comes from TCA state, all interactions send actions
struct HomeListView: View {
    /// TCA store containing the home feature state and actions
    let store: StoreOf<HomePageReducer>
    
    /// Grid layout configuration for breed tiles with fixed spacing for alignment
    private var columns: [GridItem] {
        Array(repeating: GridItem(.fixed(UIDimensions.breedCardWidth), spacing: UILayout.gridSpacing), count: UIDimensions.homeGridColumnCount)
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
                            state: \.breedDetail!,
                            action: \.breedDetail
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
    func content(viewStore: ViewStoreOf<HomePageReducer>) -> some View {
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
            ProgressView.standardCircular(UIStrings.Common.loadingBreeds)
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

    /// Main grid section displaying actual breed data + filter controls
    func breedsGridSection(viewStore: ViewStoreOf<HomePageReducer>) -> some View {
        VStack(spacing: UILayout.sectionSpacing) {
            filterSection(viewStore: viewStore)

            ScrollView {
                LazyVGrid(columns: columns, spacing: UILayout.gridSpacing) {
                    /// Display each breed with index for pagination tracking
                    ForEach(Array(viewStore.breeds.enumerated()), id: \.element.id) { index, breed in
                        breedTileLink(index: index, breed: breed, viewStore: viewStore)
                    }

                    /// Show loading indicator at bottom when fetching next page
                    if viewStore.isLoadingPage {
                        ProgressView.standardCircular
                            .gridCellColumns(UIDimensions.homeGridColumnCount)
                    }
                }
                .padding(.horizontal, UILayout.listPadding)
                .padding(.bottom, UILayout.listPadding)
            }
        }
    }

    /// Filter controls for lifespan range
    func filterSection(viewStore: ViewStoreOf<HomePageReducer>) -> some View {
        VStack(alignment: .leading, spacing: UILayout.gridSpacing) {
            HStack {
                Text("Filtrar por idade (anos)")
                    .font(.headline)
                Spacer()
                Button {
                    // Clear both filters
                    viewStore.send(.binding(.set(\.minAgeFilter, nil)))
                    viewStore.send(.binding(.set(\.maxAgeFilter, nil)))
                } label: {
                    Text("Limpar filtro")
                }
                .disabled(viewStore.minAgeFilter == nil && viewStore.maxAgeFilter == nil)
            }

            // Min age
            VStack(alignment: .leading, spacing: UILayout.searchRowVerticalSpacing) {
                Toggle(isOn: minEnabledBinding(viewStore: viewStore)) {
                    Text("Idade mínima: \(formattedAge(viewStore.minAgeFilter))")
                }
                .toggleStyle(.switch)

                if viewStore.minAgeFilter != nil {
                    Slider(
                        value: minValueBinding(viewStore: viewStore),
                        in: 0...25,
                        step: 1
                    ) {
                        Text("Mín.")
                    } minimumValueLabel: {
                        Text("0")
                    } maximumValueLabel: {
                        Text("25")
                    }
                }
            }

            // Max age
            VStack(alignment: .leading, spacing: UILayout.searchRowVerticalSpacing) {
                Toggle(isOn: maxEnabledBinding(viewStore: viewStore)) {
                    Text("Idade máxima: \(formattedAge(viewStore.maxAgeFilter))")
                }
                .toggleStyle(.switch)

                if viewStore.maxAgeFilter != nil {
                    Slider(
                        value: maxValueBinding(viewStore: viewStore),
                        in: 0...25,
                        step: 1
                    ) {
                        Text("Máx.")
                    } minimumValueLabel: {
                        Text("0")
                    } maximumValueLabel: {
                        Text("25")
                    }
                }
            }
        }
        .padding(.horizontal, UILayout.listPadding)
        .padding(.top, UILayout.listPadding)
    }
}

// MARK: - Components
/// Individual UI components used within the view
private extension HomeListView {
    @ViewBuilder
    func breedTileLink(index: Int, breed: CatBreed, viewStore: ViewStoreOf<HomePageReducer>) -> some View {
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

// MARK: - Bindings for filter
private extension HomeListView {
    func formattedAge(_ value: Double?) -> String {
        guard let value else { return "—" }
        if value.rounded(.towardZero) == value {
            return String(format: "%.0f", value)
        } else {
            return String(format: "%.1f", value)
        }
    }

    // Toggle for enabling/disabling min filter
    func minEnabledBinding(viewStore: ViewStoreOf<HomePageReducer>) -> Binding<Bool> {
        Binding(
            get: { viewStore.minAgeFilter != nil },
            set: { isOn in
                if isOn {
                    // if enabling and nil, default to 0
                    if viewStore.minAgeFilter == nil {
                        viewStore.send(.binding(.set(\.minAgeFilter, 0)))
                    }
                } else {
                    viewStore.send(.binding(.set(\.minAgeFilter, nil)))
                }
            }
        )
    }

    // Slider value for min filter
    func minValueBinding(viewStore: ViewStoreOf<HomePageReducer>) -> Binding<Double> {
        Binding(
            get: { viewStore.minAgeFilter ?? 0 },
            set: { newValue in
                viewStore.send(.binding(.set(\.minAgeFilter, newValue)))
            }
        )
    }

    // Toggle for enabling/disabling max filter
    func maxEnabledBinding(viewStore: ViewStoreOf<HomePageReducer>) -> Binding<Bool> {
        Binding(
            get: { viewStore.maxAgeFilter != nil },
            set: { isOn in
                if isOn {
                    if viewStore.maxAgeFilter == nil {
                        viewStore.send(.binding(.set(\.maxAgeFilter, 25)))
                    }
                } else {
                    viewStore.send(.binding(.set(\.maxAgeFilter, nil)))
                }
            }
        )
    }

    // Slider value for max filter
    func maxValueBinding(viewStore: ViewStoreOf<HomePageReducer>) -> Binding<Double> {
        Binding(
            get: { viewStore.maxAgeFilter ?? 25 },
            set: { newValue in
                viewStore.send(.binding(.set(\.maxAgeFilter, newValue)))
            }
        )
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
    func onTileAppear(index: Int, totalCount: Int, viewStore: ViewStoreOf<HomePageReducer>) {
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
