import SwiftUI

@main struct ShowThisJapanApp: App {
    @StateObject private var app = AppViewModel()
    var body: some Scene { WindowGroup { RootView().environmentObject(app) } }
}

struct RootView: View {
    @EnvironmentObject var app: AppViewModel
    @AppStorage("didOnboard") private var didOnboard = false
    var body: some View {
        Group {
            if let error = app.loadError { ContentUnavailableView("Unable to open cards", systemImage: "exclamationmark.triangle", description: Text(error)) }
            else if !didOnboard { OnboardingView(didOnboard: $didOnboard) }
            else { HomeView() }
        }.tint(.navy)
    }
}

struct OnboardingView: View {
    @EnvironmentObject var app: AppViewModel; @Binding var didOnboard: Bool
    var body: some View {
        VStack(spacing: 28) {
            Spacer(); Image(systemName: "rectangle.and.hand.point.up.left").font(.system(size: 72)).foregroundStyle(.navy)
            Text("Show This Japan").font(.largeTitle.bold()); Text("Choose your language").font(.title3)
            Picker("Language", selection: $app.language) { ForEach(AppLanguage.allCases) { Text($0.name).tag($0) } }.pickerStyle(.wheel)
            Button("Start") { didOnboard = true }.buttonStyle(PrimaryButtonStyle()).accessibilityHint("Opens the home screen")
            Button("Set up later") { didOnboard = true }.padding(.bottom)
        }.padding()
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View { configuration.label.font(.headline).frame(maxWidth: .infinity, minHeight: 52).foregroundStyle(.white).background(configuration.isPressed ? Color.navy.opacity(0.7) : .navy, in: RoundedRectangle(cornerRadius: 14)) }
}
extension Color { static let navy = Color(red: 0.04, green: 0.12, blue: 0.25) }

#Preview { RootView().environmentObject(AppViewModel()) }

