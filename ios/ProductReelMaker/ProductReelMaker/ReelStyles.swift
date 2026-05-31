import SwiftUI

struct PrimaryPillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.bold())
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .padding(.horizontal, 12)
            .frame(height: 42)
            .background(Color.red, in: RoundedRectangle(cornerRadius: 8))
            .foregroundStyle(.white)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(.black, lineWidth: 2))
            .shadow(color: .black, radius: 0, x: configuration.isPressed ? 1 : 3, y: configuration.isPressed ? 1 : 3)
            .offset(x: configuration.isPressed ? 2 : 0, y: configuration.isPressed ? 2 : 0)
    }
}

struct SecondaryPillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.bold())
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .padding(.horizontal, 12)
            .frame(height: 38)
            .background(Color.white.opacity(0.76), in: RoundedRectangle(cornerRadius: 8))
            .foregroundStyle(.primary)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(.black, lineWidth: 2))
            .shadow(color: .black, radius: 0, x: configuration.isPressed ? 1 : 2, y: configuration.isPressed ? 1 : 2)
            .offset(x: configuration.isPressed ? 1 : 0, y: configuration.isPressed ? 1 : 0)
    }
}

struct SquareToolButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.bold())
            .frame(width: 38, height: 38)
            .background(Color.white.opacity(0.76), in: RoundedRectangle(cornerRadius: 8))
            .foregroundStyle(.primary)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(.black, lineWidth: 2))
            .shadow(color: .black, radius: 0, x: configuration.isPressed ? 1 : 2, y: configuration.isPressed ? 1 : 2)
            .offset(x: configuration.isPressed ? 1 : 0, y: configuration.isPressed ? 1 : 0)
    }
}

struct AddPhotoButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .frame(width: 86, height: 86)
            .background(
                ZStack {
                    Circle().fill(Color.red)
                    Circle().stroke(.white, lineWidth: 5)
                    Circle().stroke(.black, lineWidth: 2)
                }
            )
            .shadow(color: .black.opacity(0.48), radius: 0, x: configuration.isPressed ? 2 : 6, y: configuration.isPressed ? 2 : 6)
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .rotationEffect(.degrees(configuration.isPressed ? -2 : -5))
    }
}

struct SceneButtonStyle: ButtonStyle {
    var active: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption.bold())
            .background(active ? Color.red : Color.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 8))
            .foregroundStyle(active ? .white : .primary)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(.black, lineWidth: 2))
    }
}

struct StickerChipStyle: ButtonStyle {
    var active: Bool
    var colors: [Color]

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 8)
            .background(
                LinearGradient(colors: active ? colors : [Color.white.opacity(0.78), Color.white.opacity(0.66)], startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: 8)
            )
            .foregroundStyle(active ? .white : .primary)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(active ? Color.red : Color.black, lineWidth: 2))
            .shadow(color: .black.opacity(active ? 0.35 : 0.18), radius: 0, x: 2, y: 2)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct MotionChipStyle: ButtonStyle {
    var active: Bool
    var color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 8)
            .background(active ? color.opacity(0.85) : Color.white.opacity(0.74), in: RoundedRectangle(cornerRadius: 8))
            .foregroundStyle(active ? .white : .primary)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(active ? Color.red : Color.black, lineWidth: 2))
            .shadow(color: .black.opacity(active ? 0.35 : 0.16), radius: 0, x: 2, y: 2)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

extension Color {
    static let mint = Color(red: 0.31, green: 0.75, blue: 0.65)
}
