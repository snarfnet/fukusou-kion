import SwiftUI

struct CategoryStyle {
    let symbol: String
    let color: Color

    static func style(for category: String) -> CategoryStyle {
        switch category {
        case "離婚・夫婦":
            return .init(symbol: "heart.slash", color: .pink)
        case "マンション管理・ゴミ":
            return .init(symbol: "building.2", color: .teal)
        case "近隣・住まい":
            return .init(symbol: "house", color: .green)
        case "事故・ケガ":
            return .init(symbol: "cross.case", color: .red)
        case "買い物・契約":
            return .init(symbol: "cart", color: .orange)
        case "職場・お金":
            return .init(symbol: "briefcase", color: .blue)
        case "ネット・SNS":
            return .init(symbol: "network", color: .purple)
        case "家族・相続":
            return .init(symbol: "person.3", color: .indigo)
        case "学校・子ども":
            return .init(symbol: "graduationcap", color: .cyan)
        case "落とし物・所有物":
            return .init(symbol: "key", color: .brown)
        case "ペット・動物":
            return .init(symbol: "pawprint", color: .mint)
        case "行政・役所・手続き":
            return .init(symbol: "building.columns", color: .gray)
        case "医療・美容":
            return .init(symbol: "stethoscope", color: .red)
        case "交通・車・自転車":
            return .init(symbol: "car", color: .blue)
        case "賃貸・不動産":
            return .init(symbol: "door.left.hand.open", color: .green)
        case "税金・副業・フリーランス":
            return .init(symbol: "yensign.circle", color: .yellow)
        case "防犯・警察相談":
            return .init(symbol: "shield", color: .purple)
        case "マニアック日常":
            return .init(symbol: "sparkles", color: .orange)
        default:
            return .init(symbol: "questionmark.bubble", color: .brown)
        }
    }
}

struct CategoryIcon: View {
    let category: String
    var size: CGFloat = 34

    var body: some View {
        let style = CategoryStyle.style(for: category)
        Image(systemName: style.symbol)
            .font(.system(size: size * 0.48, weight: .bold))
            .foregroundStyle(style.color)
            .frame(width: size, height: size)
            .background(style.color.opacity(0.14), in: RoundedRectangle(cornerRadius: 8))
    }
}
