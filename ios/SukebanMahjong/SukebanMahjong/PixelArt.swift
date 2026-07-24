import SwiftUI

struct TitleBackdrop: View {
    var body: some View {
        Canvas { context, size in
            let unit = min(size.width / 32, size.height / 24)
            let offsetX = (size.width - unit * 32) / 2
            let offsetY = (size.height - unit * 24) / 2
            func block(_ x: Int, _ y: Int, _ w: Int, _ h: Int, _ color: Color) {
                context.fill(
                    Path(CGRect(
                        x: offsetX + CGFloat(x) * unit,
                        y: offsetY + CGFloat(y) * unit,
                        width: CGFloat(w) * unit,
                        height: CGFloat(h) * unit
                    )),
                    with: .color(color)
                )
            }

            let night = Color(red: 0.03, green: 0.07, blue: 0.12)
            let dusk = Color(red: 0.38, green: 0.08, blue: 0.12)
            let sunset = Color(red: 0.96, green: 0.58, blue: 0.16)
            let ink = Color(red: 0.02, green: 0.025, blue: 0.04)
            let window = Color(red: 0.95, green: 0.82, blue: 0.43)

            block(0, 0, 32, 10, night)
            block(0, 10, 32, 5, dusk)
            block(0, 15, 32, 9, ink)

            block(23, 3, 4, 1, sunset)
            block(21, 4, 8, 1, sunset)
            block(20, 5, 10, 3, sunset)
            block(21, 8, 8, 1, sunset)
            block(23, 9, 4, 1, sunset)

            block(3, 11, 19, 9, ink)
            block(6, 9, 13, 2, ink)
            for x in stride(from: 5, through: 19, by: 4) {
                block(x, 13, 2, 2, window)
            }
            block(11, 15, 3, 5, night)

            block(1, 17, 2, 7, ink)
            block(27, 17, 2, 7, ink)
            block(1, 17, 28, 1, ink)
            for x in stride(from: 4, through: 25, by: 3) {
                block(x, 18, 1, 6, night)
            }
            block(0, 22, 32, 2, ink)
        }
        .accessibilityHidden(true)
    }
}

struct BlinkingStartLabel: View {
    let text: String
    @State private var visible = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Text(text)
            .opacity(visible ? 1 : 0.35)
            .task(id: reduceMotion) {
                visible = true
                guard !reduceMotion else { return }
                while !Task.isCancelled {
                    do {
                        try await Task<Never, Never>.sleep(nanoseconds: 520_000_000)
                    } catch {
                        return
                    }
                    visible.toggle()
                }
            }
    }
}

struct PixelPortrait: View {
    let girl: Sukeban
    var size: CGFloat = 150

    var body: some View {
        Canvas { context, canvas in
            let u = canvas.width / 16
            // 初期の家庭用ゲーム機を意識し、人物一人につき
            // 黒・肌色・テーマ色・白の4色だけで描く。
            let ink = Color(red: 0.04, green: 0.04, blue: 0.08)
            let skin = Color(red: 1.0, green: 0.72, blue: 0.48)
            let main = girl.colors[0]
            let light = Color(red: 0.94, green: 0.91, blue: 0.76)
            func block(_ x: Int, _ y: Int, _ w: Int, _ h: Int, _ color: Color) {
                context.fill(Path(CGRect(x: CGFloat(x)*u, y: CGFloat(y)*u, width: CGFloat(w)*u, height: CGFloat(h)*u)), with: .color(color))
            }
            block(1, 1, 14, 14, ink)
            block(5, 4, 6, 8, skin)
            switch girl.hair {
            case .pompadour:
                block(3, 2, 10, 3, main); block(5, 0, 8, 3, main); block(3, 5, 3, 7, main)
            case .perm:
                for x in stride(from: 3, through: 11, by: 2) { block(x, x % 4, 3, 4, main) }
                block(3, 4, 3, 9, main); block(10, 4, 3, 9, main)
            case .sidePony:
                block(3, 1, 9, 4, main); block(11, 3, 4, 3, light); block(12, 5, 3, 7, main)
            case .wolf:
                block(3, 1, 10, 5, main); block(2, 5, 4, 5, main); block(10, 5, 4, 6, main)
            case .long:
                block(3, 1, 10, 4, main); block(2, 4, 4, 10, main); block(10, 4, 4, 10, main)
            case .beehive:
                block(4, 0, 8, 2, main); block(3, 2, 10, 3, main)
                block(2, 4, 4, 8, main); block(10, 4, 4, 8, main)
                block(1, 2, 3, 3, light)
            }
            block(6, 7, 1, 1, ink); block(9, 7, 1, 1, ink)
            switch girl.id {
            case 0:
                block(5, 6, 2, 1, main)
            case 1:
                block(5, 9, 2, 1, light)
            case 2:
                block(10, 7, 1, 2, light)
            case 3:
                block(10, 8, 1, 1, light)
            case 4:
                block(5, 9, 3, 1, light)
            case 5:
                block(4, 6, 1, 2, light)
            default:
                break
            }
            block(7, 10, 3, 1, main)
            block(4, 12, 8, 4, main)
            block(7, 12, 2, 4, light)
            if girl.id >= 6 {
                // 地方連盟94人は、制服の七つの鋲をIDの二進数で配置する。
                // 髪型・色・顔飾りとの組み合わせで、百人を別スプライトにする。
                let studs = [
                    (4, 13), (5, 14), (6, 13), (9, 13),
                    (10, 14), (11, 13), (10, 15)
                ]
                for (bit, position) in studs.enumerated()
                where girl.id & (1 << bit) != 0 {
                    block(position.0, position.1, 1, 1, light)
                }
                switch girl.id % 5 {
                case 0: block(11, 7, 1, 2, light)   // 大ぶりの耳飾り
                case 1: block(5, 9, 2, 1, light)    // 頬の絆創膏
                case 2: block(10, 6, 2, 1, main)    // 太い眉
                case 3: block(5, 6, 1, 1, light)    // 目尻の飾り
                default: block(10, 9, 1, 1, ink)    // ほくろ
                }
            }
        }
        .frame(width: size, height: size)
        .overlay(Rectangle().stroke(Color.white.opacity(0.8), lineWidth: 3))
        .shadow(color: girl.colors[0], radius: 0, x: 5, y: 5)
        .accessibilityLabel("\(girl.name)のドット絵")
    }
}

struct PixelText: ViewModifier {
    func body(content: Content) -> some View {
        content.font(.system(.body, design: .monospaced).weight(.bold))
    }
}

extension View {
    func pixelText() -> some View { modifier(PixelText()) }
}
