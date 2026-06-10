import SwiftUI

enum PetTheme {
    static let background = Color(red: 0.973, green: 0.957, blue: 0.925)
    static let surface = Color.white.opacity(0.74)
    static let ink = Color(red: 0.176, green: 0.169, blue: 0.153)
    static let muted = Color(red: 0.510, green: 0.482, blue: 0.439)
    static let coral = Color(red: 0.890, green: 0.467, blue: 0.373)
    static let sage = Color(red: 0.498, green: 0.616, blue: 0.525)
    static let sageDark = Color(red: 0.259, green: 0.420, blue: 0.333)
    static let line = Color.black.opacity(0.09)
}

struct SoftCard<Content: View>: View {
    let padding: CGFloat
    @ViewBuilder var content: Content

    init(padding: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(.white.opacity(0.70))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(PetTheme.line, lineWidth: 1)
            )
    }
}

struct SectionKicker: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption2.weight(.bold))
            .foregroundStyle(PetTheme.muted)
            .textCase(.uppercase)
    }
}

struct IconBubble: View {
    let systemName: String
    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(PetTheme.coral)
            .frame(width: 34, height: 34)
            .background(PetTheme.coral.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
    }
}

struct PetHeader: View {
    let title: String
    @Binding var state: AppState

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button {
                    state.showingDetail = true
                    state.detailTitle = "通知"
                    state.detailText = "薬、通院、家族タスクの通知をまとめて確認できます。"
                } label: {
                    Image(systemName: "bell")
                        .frame(width: 44, height: 44)
                        .background(.white.opacity(0.68))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 2) {
                    SectionKicker(text: "うちの子カルテ")
                    Text(title)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(PetTheme.ink)
                }

                Spacer()

                Button {
                    state.showingPetProfile = true
                } label: {
                    Image("MokaHomeHero")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            if state.selectedTab != .home {
                HStack(spacing: 12) {
                    Image("MokaHomeHero")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 54, height: 54)
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 3) {
                        Text("モカ")
                            .font(.headline.weight(.bold))
                        Text("12歳・ミックス犬・4.8kg")
                            .font(.caption)
                            .foregroundStyle(PetTheme.muted)
                    }
                    Spacer()
                }
                .padding(12)
                .background(.white.opacity(0.62))
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(PetTheme.line))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 18)
    }
}

struct BottomTabs: View {
    @Binding var state: AppState

    var body: some View {
        HStack(spacing: 4) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Button {
                    state.selectedTab = tab
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: tab.icon)
                            .font(.system(size: tab == .record ? 19 : 16, weight: .semibold))
                        Text(tab.rawValue)
                            .font(.system(size: 10, weight: .bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)
                    }
                    .foregroundStyle(state.selectedTab == tab ? PetTheme.coral : PetTheme.muted)
                    .frame(maxWidth: .infinity)
                    .frame(height: tab == .record ? 62 : 54)
                    .background(tab == .record ? PetTheme.coral : (state.selectedTab == tab ? PetTheme.coral.opacity(0.13) : .clear))
                    .foregroundStyle(tab == .record ? Color.white : (state.selectedTab == tab ? PetTheme.coral : PetTheme.muted))
                    .clipShape(tab == .record ? AnyShape(Circle()) : AnyShape(RoundedRectangle(cornerRadius: 18, style: .continuous)))
                    .offset(y: tab == .record ? -15 : 0)
                    .shadow(color: tab == .record ? PetTheme.coral.opacity(0.25) : .clear, radius: 14, y: 8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .frame(maxWidth: 430)
        .frame(height: 76)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 28).stroke(PetTheme.line))
        .padding(.horizontal, 18)
        .padding(.bottom, 10)
    }
}

struct AnyShape: Shape {
    private let pathBuilder: @Sendable (CGRect) -> Path

    init<S: Shape>(_ shape: S) {
        pathBuilder = { rect in shape.path(in: rect) }
    }

    func path(in rect: CGRect) -> Path {
        pathBuilder(rect)
    }
}
