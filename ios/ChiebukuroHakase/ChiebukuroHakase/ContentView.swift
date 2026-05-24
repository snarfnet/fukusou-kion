import SwiftUI

struct ContentView: View {
    private let wisdoms = WisdomStore.load()
    private let isEnglish = Locale.preferredLanguages.first?.hasPrefix("en") == true

    @State private var currentIndex = 0
    @State private var typedText = ""
    @State private var previousTexts: [String] = []
    @State private var isPaused = false
    @State private var typingTask: Task<Void, Never>?

    private var currentWisdom: WisdomItem {
        wisdoms[currentIndex]
    }

    var body: some View {
        ZStack {
            background

            VStack(spacing: 0) {
                header
                Spacer(minLength: 0)
                typewriterArea
                controls
            }
            .ignoresSafeArea(.keyboard)
        }
        .preferredColorScheme(.dark)
        .task {
            start(at: dailyIndex())
        }
        .onDisappear {
            typingTask?.cancel()
        }
    }

    private var background: some View {
        ZStack {
            Image("ChiebukuroBackground")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            LinearGradient(
                colors: [.black.opacity(0.62), .black.opacity(0.18), .black.opacity(0.82)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            LinearGradient(
                colors: [.black.opacity(0.52), .clear, .black.opacity(0.45)],
                startPoint: .leading,
                endPoint: .trailing
            )
            .ignoresSafeArea()
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text(isEnglish ? "Grandma Scholar" : "煙草屋のおばぁちゃん")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.78))
                Text(isEnglish ? "Tobacco Shop Wisdom" : "博士の知恵袋")
                    .font(.system(size: isEnglish ? 28 : 36, weight: .bold, design: .serif))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.8), radius: 12, y: 3)
            }

            Spacer()

            Text(isEnglish ? "50,000" : "50,000件")
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.9))
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(.black.opacity(0.35), in: Capsule())
                .overlay(Capsule().stroke(.white.opacity(0.18), lineWidth: 1))
        }
        .padding(.horizontal, 22)
        .padding(.top, 20)
    }

    private var typewriterArea: some View {
        VStack(alignment: .leading, spacing: 18) {
            flowLog

            Text("\(isEnglish ? "Category" : "分類") / \(currentWisdom.category)")
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.72))

            Text(typedText)
                .font(.system(size: 29, weight: .bold, design: .serif))
                .lineSpacing(9)
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.92), radius: 10, y: 3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(alignment: .bottomTrailing) {
                    if !isPaused {
                        Rectangle()
                            .fill(.white)
                            .frame(width: 2, height: 34)
                            .opacity(0.9)
                    }
                }
                .animation(.easeInOut(duration: 0.35), value: typedText)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 18)
    }

    private var flowLog: some View {
        VStack(alignment: .trailing, spacing: 10) {
            ForEach(Array(previousTexts.prefix(3).enumerated()), id: \.offset) { index, text in
                Text(text)
                    .font(.system(size: 13, weight: .semibold, design: .serif))
                    .lineLimit(2)
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(.white.opacity(0.5 - Double(index) * 0.12))
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .frame(height: 92, alignment: .bottomTrailing)
    }

    private var controls: some View {
        HStack(spacing: 14) {
            Button {
                start(at: currentIndex - 1)
            } label: {
                Image(systemName: "chevron.left")
            }

            Button {
                togglePause()
            } label: {
                Image(systemName: isPaused ? "play.fill" : "pause.fill")
            }
            .tint(.red.opacity(0.84))

            Button {
                start(at: currentIndex + 1)
            } label: {
                Image(systemName: "chevron.right")
            }

            Button(isEnglish ? "Random" : "おまかせ") {
                start(at: randomIndex())
            }
            .font(.system(size: 15, weight: .bold, design: .rounded))
        }
        .buttonStyle(.borderedProminent)
        .tint(.white.opacity(0.18))
        .controlSize(.large)
        .padding(.bottom, 8)
    }

    private func start(at rawIndex: Int) {
        typingTask?.cancel()
        isPaused = false
        currentIndex = wrapped(rawIndex)
        typedText = ""
        typingTask = Task { await typeCurrentWisdom() }
    }

    private func typeCurrentWisdom() async {
        let wisdom = currentWisdom
        let separator = isEnglish ? ". " : "。"
        let text = "\(wisdom.title)\(separator)\(wisdom.content)"

        for offset in 1...text.count {
            guard !Task.isCancelled else { return }

            while isPaused && !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(120))
            }

            await MainActor.run {
                typedText = String(text.prefix(offset))
            }

            let char = text[text.index(text.startIndex, offsetBy: offset - 1)]
            let wait: UInt64 = "。、，.!?".contains(char) ? 260 : 64
            try? await Task.sleep(for: .milliseconds(wait))
        }

        guard !Task.isCancelled else { return }
        await MainActor.run {
            previousTexts.insert(text, at: 0)
            previousTexts = Array(previousTexts.prefix(5))
        }

        try? await Task.sleep(for: .milliseconds(3800))
        guard !Task.isCancelled else { return }

        await MainActor.run {
            start(at: currentIndex + 1)
        }
    }

    private func togglePause() {
        isPaused.toggle()
    }

    private func dailyIndex() -> Int {
        let day = Calendar.current.ordinality(of: .day, in: .era, for: .now) ?? 0
        return day % wisdoms.count
    }

    private func randomIndex() -> Int {
        guard wisdoms.count > 1 else { return 0 }
        var next = currentIndex
        while next == currentIndex {
            next = Int.random(in: 0..<wisdoms.count)
        }
        return next
    }

    private func wrapped(_ index: Int) -> Int {
        let count = wisdoms.count
        return (index % count + count) % count
    }
}

#Preview {
    ContentView()
}
