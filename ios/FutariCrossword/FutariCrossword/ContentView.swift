import SwiftUI

struct ContentView: View {
    @StateObject private var game = GameViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.10, green: 0.06, blue: 0.04).ignoresSafeArea()
                if game.isShowingSetup { setup }
                else { gameScreen }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var setup: some View {
        VStack(spacing: 24) {
            Spacer()
            CompanionView(line: game.companion).padding(.horizontal)
            VStack(spacing: 16) {
                Text("ふたりでクロスワード").font(.largeTitle.bold()).foregroundStyle(.cream)
                Text("盤面の大きさ").foregroundStyle(.cream.opacity(0.7))
                HStack {
                    Button { game.selectedSize = max(1, game.selectedSize - 1) } label: { Image(systemName: "minus") }
                    Picker("盤面サイズ", selection: $game.selectedSize) {
                        ForEach(1...20, id: \.self) { Text("\($0) × \($0)").tag($0) }
                    }.pickerStyle(.wheel).frame(height: 110)
                    Button { game.selectedSize = min(20, game.selectedSize + 1) } label: { Image(systemName: "plus") }
                }.font(.title2.bold()).foregroundStyle(.amber)
                Button { game.generate() } label: { Label("生成する", systemImage: "sparkles").font(.headline).frame(maxWidth: .infinity).padding() }
                    .buttonStyle(.plain).background(Color(red: 0.66, green: 0.16, blue: 0.12), in: Capsule()).foregroundStyle(.white)
            }.padding(24).background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 28)).padding(.horizontal)
            Spacer()
        }
    }

    private var gameScreen: some View {
        VStack(spacing: 10) {
            HStack {
                Button { game.isShowingSetup = true } label: { Image(systemName: "chevron.left") }
                Spacer(); Text("\(game.selectedSize) × \(game.selectedSize)").font(.headline); Spacer()
                Button { game.generate() } label: { Image(systemName: "arrow.clockwise") }
            }.foregroundStyle(.cream).padding(.horizontal)
            CompanionView(line: game.companion).padding(.horizontal)
            if let puzzle = game.puzzle {
                CrosswordGridView(puzzle: puzzle, answers: game.answers, selectedEntry: game.selectedEntry, selectedPoint: game.selectedPoint, onSelect: game.select)
                    .frame(maxHeight: .infinity).padding(.horizontal, 8)
            }
            cluePanel
            kanaKeyboard
        }.padding(.vertical, 6)
    }

    private var cluePanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let entry = game.selectedEntry {
                Text("\(entry.direction == .across ? "ヨコ" : "タテ") \(entry.number)").font(.caption.bold()).foregroundStyle(.amber)
                Text(entry.word.clues.first ?? "").font(.headline).foregroundStyle(Color(red: 0.20, green: 0.12, blue: 0.08))
            } else { Text("白いマスを選んでね").foregroundStyle(.brown) }
            if let feedback = game.feedback { Text(feedback).font(.caption).foregroundStyle(.red) }
            HStack {
                Button { game.hint() } label: { Label("1文字ヒント", systemImage: "lightbulb") }
                Spacer()
                Button { game.check() } label: { Label("答え合わせ", systemImage: "checkmark.circle") }
            }.font(.subheadline.bold()).foregroundStyle(.brown)
        }.padding(14).background(Color.cream, in: RoundedRectangle(cornerRadius: 20)).padding(.horizontal)
    }

    private var kanaKeyboard: some View {
        KanaKeyboardView(onInput: game.type, onDelete: game.deleteCurrent)
            .padding(.horizontal, 8)
    }
}

#Preview { ContentView() }
