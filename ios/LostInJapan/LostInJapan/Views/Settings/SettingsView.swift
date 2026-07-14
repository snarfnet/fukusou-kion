import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage("appLanguage") private var language = "system"
    @AppStorage("hasCompletedOnboarding") private var onboarding = true
    @Environment(\.modelContext) private var context
    @State private var confirmDelete = false
    var body: some View {
        Form {
            Section("settings.language") {
                Picker("settings.language", selection: $language) {
                    ForEach(AppLanguage.allCases) { option in
                        Text(LocalizedStringKey(option.titleKey)).tag(option.rawValue)
                    }
                }
            }
            Section("settings.privacy") {
                Text("settings.localOnly")
                Text("settings.noCardNumbers")
                Button("settings.deleteAll", role: .destructive) { confirmDelete = true }
            }
            Section("settings.about") {
                Text("settings.disclaimer")
                Button("settings.showOnboarding") { onboarding = false }
            }
        }
        .navigationTitle("settings.title")
        .alert("settings.deleteTitle", isPresented: $confirmDelete) {
            Button("common.cancel", role: .cancel) {}
            Button("settings.delete", role: .destructive) { try? context.delete(model: LostItemCase.self) }
        } message: {
            Text("settings.deleteMessage")
        }
    }
}
