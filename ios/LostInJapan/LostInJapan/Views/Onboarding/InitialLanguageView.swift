import SwiftUI

struct InitialLanguageView: View {
    let completion: (AppLanguage) -> Void
    @State private var selection: AppLanguage?

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "globe.asia.australia.fill")
                .font(.system(size: 58))
                .foregroundStyle(Color.brandBlue)

            VStack(spacing: 6) {
                Text("Choose your language")
                    .font(.largeTitle.bold())
                Text("言語を選択してください · 请选择语言")
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)

            ScrollView {
                LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 12) {
                    ForEach(AppLanguage.selectableLanguages) { language in
                        Button {
                            selection = language
                        } label: {
                            HStack {
                                Text(language.nativeTitle)
                                    .font(.headline)
                                Spacer()
                                if selection == language {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.brandBlue)
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, minHeight: 58)
                            .background(.background, in: RoundedRectangle(cornerRadius: 14))
                            .overlay {
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(selection == language ? Color.brandBlue : Color.secondary.opacity(0.2), lineWidth: selection == language ? 2 : 1)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Button("Continue") {
                if let selection { completion(selection) }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(selection == nil)
            .opacity(selection == nil ? 0.45 : 1)
        }
        .padding()
    }
}

#Preview { InitialLanguageView { _ in } }
