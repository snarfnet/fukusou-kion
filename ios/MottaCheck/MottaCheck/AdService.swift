import SwiftUI

enum AdUnitID {
    static let homeBanner = "home"
    static let templateBanner = "template"
}

struct AdBannerSlot: View {
    let unitID: String

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.white)
            HStack(spacing: 8) {
                Image(systemName: "rectangle.and.text.magnifyingglass")
                Text("広告")
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(AppTheme.muted)
        }
        .frame(height: 50)
        .overlay(Rectangle().stroke(Color.black.opacity(0.06), lineWidth: 1))
            .accessibilityLabel("広告")
    }
}
