import SwiftUI

struct SpotCard: View {
    let spot: Spot
    let distance: Double

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: spot.categoryIcon)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(spot.categoryColor.gradient, in: Circle())
            VStack(alignment: .leading, spacing: 5) {
                Text(spot.name).font(.headline).foregroundStyle(.primary).lineLimit(2)
                Text("\(spot.category) ・ \(String(format: "%.1f", distance))km")
                    .font(.caption).foregroundStyle(.secondary)
                HStack(spacing: 6) {
                    Badge(spot.priceText)
                    Badge(spot.airConditioned == true ? "冷房あり" : "冷房未確認")
                    if spot.verificationStatus == "verified" { Badge("確認済み", emphasis: true) }
                }
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(.tertiary)
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

struct Badge: View {
    let text: String
    var emphasis = false

    init(_ text: String, emphasis: Bool = false) {
        self.text = text
        self.emphasis = emphasis
    }

    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .lineLimit(1)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(emphasis ? Theme.blue : Theme.ice, in: Capsule())
            .foregroundStyle(emphasis ? .white : Theme.deepBlue)
    }
}

extension Spot {
    var categoryIcon: String {
        if category.contains("図書") { return "books.vertical.fill" }
        if category.contains("ギャラリー") { return "photo.artframe" }
        if category.contains("博物館") { return "building.columns.fill" }
        if category.contains("ビジター") || category.contains("見学") { return "map.fill" }
        if category.contains("ショールーム") { return "sparkles.rectangle.stack.fill" }
        return "building.2.fill"
    }

    var categoryColor: Color {
        if category.contains("図書") { return .indigo }
        if category.contains("ギャラリー") || category.contains("文化") { return .purple }
        if category.contains("ビジター") || category.contains("見学") { return .teal }
        return Theme.blue
    }
}
