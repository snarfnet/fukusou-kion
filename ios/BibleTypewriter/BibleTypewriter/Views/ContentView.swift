import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var viewModel = BibleReaderViewModel()

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                background(size: proxy.size)

                VStack(alignment: .leading, spacing: 0) {
                    header
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                    ReaderPanel(viewModel: viewModel)
                        .padding(.horizontal, 14)
                        .padding(.top, proxy.size.height < 720 ? 28 : 48)

                    Spacer(minLength: 8)

                    controls
                        .padding(.horizontal, 14)
                        .padding(.bottom, 18)
                }
            }
            .foregroundStyle(.white)
            .task {
                viewModel.start()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("静かな聖書朗読")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.70))

            Text("聖書のことば")
                .font(.system(size: 38, weight: .bold, design: .serif))
                .lineLimit(1)
                .minimumScaleFactor(0.78)
                .shadow(color: .black.opacity(0.55), radius: 12, y: 6)
        }
    }

    private var controls: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Picker("翻訳", selection: $viewModel.translation) {
                    ForEach(BibleTranslation.allCases) { translation in
                        Text(translation.title).tag(translation)
                    }
                }
                .onChange(of: viewModel.translation) { _, _ in viewModel.didChangeSelection() }

                Picker("書名", selection: $viewModel.selectedBook) {
                    ForEach(viewModel.books) { book in
                        Text(book.name).tag(book)
                    }
                }
                .onChange(of: viewModel.selectedBook) { _, _ in
                    viewModel.selectedChapter = 1
                    viewModel.didChangeSelection()
                }

                Picker("章", selection: $viewModel.selectedChapter) {
                    ForEach(1...viewModel.selectedBook.chapters, id: \.self) { chapter in
                        Text("\(chapter)章").tag(chapter)
                    }
                }
                .onChange(of: viewModel.selectedChapter) { _, _ in viewModel.didChangeSelection() }
            }

            HStack(spacing: 8) {
                ControlButton(title: "‹", action: viewModel.previousChapter)
                ControlButton(title: viewModel.isPaused ? "▶" : "Ⅱ", action: viewModel.togglePause)
                ControlButton(title: "›", action: viewModel.nextChapter)
            }

            HStack {
                Button("おまかせ", action: viewModel.randomChapter)
                    .buttonStyle(QuietButtonStyle())
                Spacer(minLength: 0)
            }
        }
        .pickerStyle(.menu)
        .tint(.white)
        .padding(10)
        .background(.black.opacity(0.30), in: Rectangle())
        .overlay(Rectangle().stroke(.white.opacity(0.16), lineWidth: 1))
    }

    private func background(size: CGSize) -> some View {
        BundleBackgroundImage(
            name: viewModel.backgroundName,
            category: viewModel.selectedBook.category.rawValue
        )
            .frame(width: size.width, height: size.height)
            .clipped()
            .overlay {
                ZStack {
                    LinearGradient(
                        colors: [.black.opacity(0.50), .clear, .black.opacity(0.66)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    LinearGradient(
                        colors: [.black.opacity(0.48), .clear, .clear, .black.opacity(0.50)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    RadialGradient(
                        colors: [.white.opacity(0.10), .black.opacity(0.10), .black.opacity(0.40)],
                        center: .center,
                        startRadius: 20,
                        endRadius: max(size.width, size.height) * 0.72
                    )
                }
            }
            .ignoresSafeArea()
    }
}

private struct ReaderPanel: View {
    @ObservedObject var viewModel: BibleReaderViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(viewModel.currentChapter?.reference ?? "読み込み中")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.76))
                .lineLimit(1)
                .minimumScaleFactor(0.76)
                .zIndex(2)

            TypewriterScrollText(text: viewModel.visibleText)

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.48))
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .frame(height: readerHeight)
        .background(
            LinearGradient(
                colors: [.black.opacity(0.30), .black.opacity(0.12)],
                startPoint: .top,
                endPoint: .bottom
            ),
            in: Rectangle()
        )
        .overlay(Rectangle().stroke(.white.opacity(0.16), lineWidth: 1))
    }

    private var readerHeight: CGFloat {
        UIScreen.main.bounds.height < 720 ? 333 : 510
    }
}

private struct TypewriterScrollText: View {
    let text: String

    var body: some View {
        ScrollViewReader { reader in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(text)
                        .font(.system(size: UIScreen.main.bounds.height < 720 ? 23 : 27, weight: .semibold, design: .serif))
                        .lineSpacing(13)
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.75), radius: 9, y: 3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 56)
                        .padding(.bottom, 74)

                    Color.clear
                        .frame(height: 1)
                        .id("bottom")
                }
            }
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .black, location: 0.22),
                        .init(color: .black, location: 0.82),
                        .init(color: .clear, location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .onChange(of: text) { _, _ in
                withAnimation(.easeOut(duration: 0.42)) {
                    reader.scrollTo("bottom", anchor: .bottom)
                }
            }
        }
    }

}

private struct BundleBackgroundImage: View {
    let name: String
    let category: String

    var body: some View {
        Group {
            if let image = loadImage() {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                LinearGradient(
                    colors: [
                        Color(red: 0.02, green: 0.06, blue: 0.14),
                        Color(red: 0.13, green: 0.15, blue: 0.20)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
    }

    private func loadImage() -> UIImage? {
        guard let url = Bundle.main.url(
            forResource: name,
            withExtension: "jpg",
            subdirectory: "Backgrounds/\(category)"
        ) else {
            return nil
        }
        return UIImage(contentsOfFile: url.path)
    }
}

private struct ControlButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(title, action: action)
            .buttonStyle(QuietButtonStyle())
            .frame(maxWidth: .infinity)
    }
}

private struct QuietButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.bold))
            .foregroundStyle(.white)
            .frame(height: 42)
            .padding(.horizontal, 18)
            .background(.white.opacity(configuration.isPressed ? 0.16 : 0.08), in: Rectangle())
            .overlay(Rectangle().stroke(.white.opacity(0.16), lineWidth: 1))
    }
}

#Preview {
    ContentView()
}
