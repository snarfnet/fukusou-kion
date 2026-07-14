import SwiftUI

struct OnboardingView: View {
    let completion: () -> Void
    @State private var page = 0
    private let pages = [
        ("onboarding.title1", "onboarding.body1", "questionmark.circle"),
        ("onboarding.title2", "onboarding.body2", "rectangle.and.hand.point.up.left"),
        ("onboarding.title3", "onboarding.body3", "shield.checkered")
    ]

    var body: some View {
        VStack(spacing: 28) {
            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { index in
                    VStack(spacing: 28) {
                        Image(systemName: pages[index].2).font(.system(size: 76)).foregroundStyle(.brandBlue)
                        Text(LocalizedStringKey(pages[index].0)).font(.largeTitle.bold()).multilineTextAlignment(.center)
                        Text(LocalizedStringKey(pages[index].1)).font(.title3).multilineTextAlignment(.center).foregroundStyle(.secondary)
                    }.padding(30).tag(index)
                }
            }.tabViewStyle(.page(indexDisplayMode: .always))
            Button(page == pages.count - 1 ? "onboarding.start" : "common.next") {
                if page == pages.count - 1 { completion() } else { withAnimation { page += 1 } }
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding()
        }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.headline).frame(maxWidth: .infinity, minHeight: 56).foregroundStyle(.white)
            .background(.brandBlue.opacity(configuration.isPressed ? 0.75 : 1), in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview { OnboardingView {} }

