import SwiftUI

enum AppTheme {
    static let navy = Color(red: 0.02, green: 0.12, blue: 0.26)
    static let navy2 = Color(red: 0.04, green: 0.19, blue: 0.39)
    static let blue = Color(red: 0.0, green: 0.33, blue: 0.66)
    static let paleBlue = Color(red: 0.90, green: 0.95, blue: 1.0)
    static let background = Color(red: 0.965, green: 0.972, blue: 0.982)
    static let surface = Color.white
    static let line = Color(red: 0.82, green: 0.85, blue: 0.89)
    static let grayText = Color(red: 0.32, green: 0.36, blue: 0.42)
    static let alert = Color(red: 0.72, green: 0.12, blue: 0.10)
    static let warning = Color(red: 0.78, green: 0.42, blue: 0.04)
    static let success = Color(red: 0.05, green: 0.48, blue: 0.26)
}

struct OfficialCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(14)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(AppTheme.line, lineWidth: 1)
            )
    }
}

struct Badge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .stroke(color.opacity(0.25), lineWidth: 1)
            )
    }
}

struct SectionTitle: View {
    let title: String
    let caption: String?

    init(_ title: String, caption: String? = nil) {
        self.title = title
        self.caption = caption
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(AppTheme.navy)
            if let caption {
                Text(caption)
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.grayText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
