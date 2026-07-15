import SwiftUI

struct CrosswordGridView: View {
    let puzzle: CrosswordPuzzle
    let answers: [GridPoint: Character]
    let selectedEntry: CrosswordEntry?
    let selectedPoint: GridPoint?
    let onSelect: (GridPoint) -> Void
    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1

    var body: some View {
        GeometryReader { proxy in
            let base = min(44, max(24, (proxy.size.width - 8) / CGFloat(min(puzzle.size, 10))))
            ScrollView([.horizontal, .vertical]) {
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(base), spacing: 1), count: puzzle.size), spacing: 1) {
                    ForEach(0..<(puzzle.size * puzzle.size), id: \.self) { index in
                        let point = GridPoint(row: index / puzzle.size, column: index % puzzle.size)
                        cell(point, size: base)
                    }
                }
                .padding(4)
                .background(Color.black.opacity(0.6))
                .scaleEffect(scale, anchor: .topLeading)
                .frame(width: base * CGFloat(puzzle.size) * scale, height: base * CGFloat(puzzle.size) * scale, alignment: .topLeading)
                .gesture(MagnifyGesture().onChanged { value in scale = min(2.5, max(0.75, lastScale * value.magnification)) }.onEnded { _ in lastScale = scale })
            }
            .scrollIndicators(.visible)
        }
    }

    @ViewBuilder private func cell(_ point: GridPoint, size: CGFloat) -> some View {
        if puzzle.solution[point.row][point.column] == nil {
            Rectangle().fill(Color(red: 0.11, green: 0.07, blue: 0.05)).frame(width: size, height: size)
        } else {
            let active = selectedEntry?.points.contains(point) == true
            let selected = selectedPoint == point
            Button { onSelect(point) } label: {
                ZStack(alignment: .topLeading) {
                    Rectangle().fill(selected ? Color.amber : active ? Color.amber.opacity(0.35) : Color.cream)
                    if let number = puzzle.numbers[point] { Text("\(number)").font(.system(size: max(7, size * 0.22), weight: .bold)).foregroundStyle(.brown).padding(2) }
                    if let answer = answers[point] { Text(String(answer)).font(.system(size: size * 0.48, weight: .semibold, design: .rounded)).foregroundStyle(Color(red: 0.19, green: 0.12, blue: 0.08)).frame(maxWidth: .infinity, maxHeight: .infinity) }
                }
            }.buttonStyle(.plain).frame(width: size, height: size)
        }
    }
}

