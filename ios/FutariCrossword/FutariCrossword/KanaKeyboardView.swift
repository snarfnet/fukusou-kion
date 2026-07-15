import SwiftUI

struct KanaKeyboardView: View {
    let onInput: (Character) -> Void
    let onDelete: () -> Void
    @State private var page: KanaPage = .basic

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 3), count: 10)

    var body: some View {
        VStack(spacing: 5) {
            HStack(spacing: 6) {
                pageButton("あいう", page: .basic)
                pageButton("がぱ", page: .voiced)
                pageButton("小文字", page: .small)
                Spacer(minLength: 4)
                Button(action: onDelete) {
                    Label("消す", systemImage: "delete.left.fill")
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .frame(height: 30)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.cream)
                .background(.white.opacity(0.12), in: Capsule())
                .accessibilityLabel("1文字消す")
            }

            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(Array(page.characters.enumerated()), id: \.offset) { _, character in
                    if character == "　" {
                        Color.clear.frame(height: 34)
                    } else {
                        Button {
                            onInput(character)
                        } label: {
                            Text(String(character))
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color(red: 0.20, green: 0.12, blue: 0.08))
                                .frame(maxWidth: .infinity)
                                .frame(height: 34)
                                .background(Color.cream, in: RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(character)を入力")
                    }
                }
            }
        }
        .padding(8)
        .background(Color.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 16))
    }

    private func pageButton(_ title: String, page target: KanaPage) -> some View {
        Button(title) { page = target }
            .font(.caption.bold())
            .buttonStyle(.plain)
            .foregroundStyle(page == target ? Color(red: 0.20, green: 0.12, blue: 0.08) : .cream)
            .padding(.horizontal, 12)
            .frame(height: 30)
            .background(page == target ? Color.amber : .white.opacity(0.12), in: Capsule())
    }
}

private enum KanaPage: CaseIterable {
    case basic, voiced, small

    var characters: [Character] {
        switch self {
        case .basic:
            Array("あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめもやゆよ　　らりるれろわをんー　")
        case .voiced:
            Array("がぎぐげござじずぜぞだぢづでどばびぶべぼぱぴぷぺぽ　　　　　　　　　　　　")
        case .small:
            Array("ぁぃぅぇぉゃゅょっゎゔ　　　　　　　　　　　　　　")
        }
    }
}
