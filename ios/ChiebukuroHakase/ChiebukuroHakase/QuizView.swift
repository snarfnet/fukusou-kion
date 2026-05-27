import SwiftUI

struct QuizView: View {
    let wisdoms: [WisdomItem]
    let tracker: ReadingTracker

    private let isEnglish = Locale.preferredLanguages.first?.hasPrefix("en") == true

    @State private var state: QuizState = .menu
    @State private var currentQuestion: QuizQuestion?
    @State private var selectedAnswer: Int?
    @State private var score = 0
    @State private var questionNumber = 0
    @State private var totalQuestions = 10
    @State private var showResult = false

    private enum QuizState {
        case menu, playing, finished
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                switch state {
                case .menu:
                    menuView
                case .playing:
                    if let q = currentQuestion {
                        questionView(q)
                    }
                case .finished:
                    resultView
                }
            }
            .navigationTitle(isEnglish ? "Quiz" : "知恵クイズ")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var menuView: some View {
        VStack(spacing: 24) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 64))
                .foregroundStyle(.orange.gradient)

            Text(isEnglish ? "Wisdom Quiz" : "おばあちゃんの知恵クイズ")
                .font(.system(size: 24, weight: .bold, design: .serif))

            Text(isEnglish
                 ? "Test how well you know the wisdoms!"
                 : "知恵袋の内容をどれだけ覚えているか試そう！")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                quizButton(isEnglish ? "10 Questions" : "10問", count: 10)
                quizButton(isEnglish ? "20 Questions" : "20問", count: 20)
                quizButton(isEnglish ? "50 Questions" : "50問", count: 50)
            }
            .padding(.top, 8)

            if tracker.quizTotal > 0 {
                VStack(spacing: 6) {
                    Text(isEnglish ? "Your Stats" : "あなたの成績")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 20) {
                        statBadge(
                            isEnglish ? "Played" : "挑戦",
                            value: "\(tracker.quizTotal)"
                        )
                        statBadge(
                            isEnglish ? "Correct" : "正解",
                            value: "\(tracker.quizCorrect)"
                        )
                        statBadge(
                            isEnglish ? "Rate" : "正答率",
                            value: String(format: "%.0f%%", tracker.quizAccuracy)
                        )
                    }
                }
                .padding(.top, 12)
            }
        }
        .padding(32)
    }

    private func quizButton(_ title: String, count: Int) -> some View {
        Button {
            startQuiz(count: count)
        } label: {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .frame(maxWidth: .infinity, minHeight: 50)
        }
        .buttonStyle(.borderedProminent)
        .tint(.orange)
    }

    private func statBadge(_ label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .monospaced))
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
    }

    private func questionView(_ q: QuizQuestion) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                HStack {
                    Text(isEnglish
                         ? "Q\(questionNumber)/\(totalQuestions)"
                         : "第\(questionNumber)問 / \(totalQuestions)問")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(isEnglish
                         ? "Score: \(score)"
                         : "スコア: \(score)")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundStyle(.orange)
                }

                ProgressView(value: Double(questionNumber), total: Double(totalQuestions))
                    .tint(.orange)

                Text(q.question)
                    .font(.system(size: 20, weight: .bold, design: .serif))
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 12)

                VStack(spacing: 12) {
                    ForEach(Array(q.choices.enumerated()), id: \.offset) { index, choice in
                        Button {
                            if selectedAnswer == nil {
                                answerTapped(index, correct: q.correctIndex)
                            }
                        } label: {
                            HStack {
                                Text(choiceLetter(index))
                                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                                    .frame(width: 32, height: 32)
                                    .background(choiceColor(index, correct: q.correctIndex).opacity(0.2), in: Circle())

                                Text(choice)
                                    .font(.system(size: 16, weight: .medium))
                                    .multilineTextAlignment(.leading)

                                Spacer()

                                if let sel = selectedAnswer {
                                    if index == q.correctIndex {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                    } else if index == sel {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.red)
                                    }
                                }
                            }
                            .padding(14)
                            .background(choiceBg(index, correct: q.correctIndex), in: RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(choiceColor(index, correct: q.correctIndex).opacity(0.3))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                if selectedAnswer != nil {
                    Button {
                        nextQuestion()
                    } label: {
                        Text(questionNumber >= totalQuestions
                             ? (isEnglish ? "See Results" : "結果を見る")
                             : (isEnglish ? "Next" : "次の問題"))
                            .font(.system(size: 17, weight: .bold))
                            .frame(maxWidth: .infinity, minHeight: 50)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .padding(.top, 8)
                }
            }
            .padding(24)
        }
    }

    private var resultView: some View {
        VStack(spacing: 24) {
            let pct = Double(score) / Double(totalQuestions) * 100

            Image(systemName: pct >= 80 ? "star.fill" : pct >= 50 ? "hand.thumbsup.fill" : "book.fill")
                .font(.system(size: 64))
                .foregroundStyle(pct >= 80 ? .yellow : pct >= 50 ? .orange : .blue)

            Text(pct >= 80
                 ? (isEnglish ? "Excellent!" : "素晴らしい！")
                 : pct >= 50
                    ? (isEnglish ? "Good job!" : "よくできました！")
                    : (isEnglish ? "Keep learning!" : "もっと読んでみよう！"))
                .font(.system(size: 28, weight: .bold, design: .serif))

            Text(isEnglish
                 ? "\(score) / \(totalQuestions) correct"
                 : "\(totalQuestions)問中 \(score)問正解")
                .font(.system(size: 20))
                .foregroundStyle(.secondary)

            Text(String(format: "%.0f%%", pct))
                .font(.system(size: 56, weight: .black, design: .monospaced))
                .foregroundStyle(.orange)

            VStack(spacing: 12) {
                Button {
                    startQuiz(count: totalQuestions)
                } label: {
                    Text(isEnglish ? "Try Again" : "もう一回")
                        .font(.system(size: 17, weight: .bold))
                        .frame(maxWidth: .infinity, minHeight: 50)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)

                Button {
                    state = .menu
                } label: {
                    Text(isEnglish ? "Back to Menu" : "メニューに戻る")
                        .font(.system(size: 17, weight: .bold))
                        .frame(maxWidth: .infinity, minHeight: 50)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(32)
    }

    // MARK: - Logic

    private func startQuiz(count: Int) {
        totalQuestions = min(count, wisdoms.count / 2)
        score = 0
        questionNumber = 0
        selectedAnswer = nil
        state = .playing
        nextQuestion()
    }

    private func nextQuestion() {
        selectedAnswer = nil
        questionNumber += 1
        if questionNumber > totalQuestions {
            state = .finished
            return
        }
        currentQuestion = generateQuestion()
    }

    private func generateQuestion() -> QuizQuestion {
        let shuffled = wisdoms.shuffled()
        let correct = shuffled[0]
        let wrong = Array(shuffled.dropFirst().prefix(3))

        let questionType = Int.random(in: 0...1)

        if questionType == 0 {
            // "What category does this wisdom belong to?"
            let q = isEnglish
                ? "Which category does this belong to?\n\"\(correct.title)\""
                : "この知恵はどのカテゴリ？\n「\(correct.title)」"
            var choices = [correct.category]
            for w in wrong where !choices.contains(w.category) {
                choices.append(w.category)
                if choices.count >= 4 { break }
            }
            // Fill if not enough unique categories
            let allCats = Array(Set(wisdoms.map(\.category)))
            for cat in allCats.shuffled() where !choices.contains(cat) {
                choices.append(cat)
                if choices.count >= 4 { break }
            }
            let correctIdx = 0
            choices.shuffle()
            let newCorrectIdx = choices.firstIndex(of: correct.category) ?? 0
            return QuizQuestion(question: q, choices: choices, correctIndex: newCorrectIdx)
        } else {
            // "Which is the correct continuation?"
            let q = isEnglish
                ? "What is the wisdom about?\n\"\(correct.title)\""
                : "この知恵の内容は？\n「\(correct.title)」"
            var choices = [correct.content]
            for w in wrong {
                if !choices.contains(w.content) {
                    choices.append(w.content)
                }
                if choices.count >= 4 { break }
            }
            while choices.count < 4 {
                let random = wisdoms.randomElement()!
                if !choices.contains(random.content) {
                    choices.append(random.content)
                }
            }
            choices.shuffle()
            let newCorrectIdx = choices.firstIndex(of: correct.content) ?? 0
            return QuizQuestion(question: q, choices: choices, correctIndex: newCorrectIdx)
        }
    }

    private func answerTapped(_ index: Int, correct: Int) {
        selectedAnswer = index
        let isCorrect = index == correct
        if isCorrect { score += 1 }
        tracker.recordQuiz(correct: isCorrect)
    }

    private func choiceLetter(_ index: Int) -> String {
        ["A", "B", "C", "D"][index]
    }

    private func choiceColor(_ index: Int, correct: Int) -> Color {
        guard let sel = selectedAnswer else { return .primary }
        if index == correct { return .green }
        if index == sel { return .red }
        return .primary
    }

    private func choiceBg(_ index: Int, correct: Int) -> some ShapeStyle {
        guard let sel = selectedAnswer else {
            return AnyShapeStyle(.ultraThinMaterial)
        }
        if index == correct {
            return AnyShapeStyle(Color.green.opacity(0.1))
        }
        if index == sel {
            return AnyShapeStyle(Color.red.opacity(0.1))
        }
        return AnyShapeStyle(.ultraThinMaterial)
    }
}

private struct QuizQuestion {
    let question: String
    let choices: [String]
    let correctIndex: Int
}
