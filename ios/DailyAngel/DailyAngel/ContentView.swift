import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: AngelMessageStore

    var body: some View {
        TabView {
            TodayView(message: store.todayMessage)
                .tabItem {
                    Label("今日", systemImage: "sparkles")
                }

            LibraryView()
                .tabItem {
                    Label("365日", systemImage: "calendar")
                }

            SavedView()
                .tabItem {
                    Label("保存", systemImage: "bookmark")
                }
        }
        .tint(AngelColors.ink)
    }
}

enum AngelColors {
    static let paper = Color(red: 0.97, green: 0.94, blue: 0.86)
    static let paperDeep = Color(red: 0.91, green: 0.85, blue: 0.73)
    static let ink = Color(red: 0.09, green: 0.13, blue: 0.19)
    static let cobalt = Color(red: 0.08, green: 0.20, blue: 0.38)
    static let gold = Color(red: 0.76, green: 0.56, blue: 0.20)
    static let teal = Color(red: 0.03, green: 0.38, blue: 0.42)
}

struct AngelBackground: View {
    var body: some View {
        LinearGradient(
            colors: [AngelColors.paper, Color(red: 0.98, green: 0.91, blue: 0.78), Color(red: 0.86, green: 0.93, blue: 0.90)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .overlay(alignment: .topTrailing) {
            Circle()
                .stroke(AngelColors.gold.opacity(0.22), lineWidth: 40)
                .frame(width: 260, height: 260)
                .offset(x: 110, y: -90)
        }
        .overlay(alignment: .bottomLeading) {
            Circle()
                .fill(AngelColors.teal.opacity(0.12))
                .frame(width: 220, height: 220)
                .offset(x: -80, y: 80)
        }
    }
}

struct MessagePanel<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(18)
            .background(.white.opacity(0.58), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(AngelColors.ink.opacity(0.10), lineWidth: 1)
            }
    }
}

struct CapsuleLabel: View {
    let text: String
    let systemImage: String

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(AngelColors.cobalt)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.white.opacity(0.54), in: Capsule())
    }
}

#Preview {
    ContentView()
        .environmentObject(AngelMessageStore())
}
