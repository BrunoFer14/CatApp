import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: CatBreedsViewModel
    @State private var showConfirmClear = false
    @State private var clearedToast = false

    var body: some View {
        Form {
            Section(header: Text("Cache")) {
                Button(role: .destructive) {
                    showConfirmClear = true
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("Clear cache")
                    }
                }
                .alert("Clear cached breeds?", isPresented: $showConfirmClear) {
                    Button("Cancel", role: .cancel) {}
                    Button("Clear", role: .destructive) {
                        viewModel.clearCache()
                        clearedToast = true
                    }
                } message: {
                    Text("This removes cached pages (not your favorites). You can still fetch again when online.")
                }

                if clearedToast {
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
