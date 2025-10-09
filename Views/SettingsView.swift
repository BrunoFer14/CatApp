import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: CatBreedsViewModel
    @StateObject private var settingsVM: SettingsViewModel

    init(viewModel: CatBreedsViewModel) {
        self.viewModel = viewModel
        _settingsVM = StateObject(wrappedValue: SettingsViewModel(catViewModel: viewModel))
    }

    var body: some View {
        Form {
            Section(header: Text("Cache")) {
                Button(role: .destructive) {
                    settingsVM.showConfirmClear = true
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("Clear cache")
                    }
                }
                .alert("Clear cached breeds?", isPresented: $settingsVM.showConfirmClear) {
                    Button("Cancel", role: .cancel) {}
                    Button("Clear", role: .destructive) {
                        settingsVM.clearCache()
                    }
                } message: {
                    Text("This removes cached pages (not your favorites). You can still fetch again when online.")
                }

                if settingsVM.clearedToast {
                    Text("Cache cleared.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }

            Section(header: Text("About")) {
                Text("CatApp")
                Text("Version 1.0")
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Settings")
    }
}
