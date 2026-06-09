import SwiftUI
import UIKit

struct CaseDetailView: View {
    let item: TroubleCase
    @State private var showCopied = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                detailSection("まずやること", systemImage: "checklist", items: item.steps)
                detailSection("やらないこと", systemImage: "hand.raised", items: item.avoid)
                detailSection("残す証拠", systemImage: "folder", items: item.evidence)
                detailSection("相談先", systemImage: "phone", items: item.contacts)
                memoSection
                sourceSection
            }
            .padding()
            .frame(maxWidth: 860, alignment: .leading)
        }
        .navigationTitle("事例詳細")
        .navigationBarTitleDisplayMode(.inline)
        .alert("相談メモをコピーしました", isPresented: $showCopied) {
            Button("OK", role: .cancel) {}
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                CategoryIcon(category: item.category, size: 42)
                Text(item.urgency.title)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(urgencyColor, in: Capsule())
                Text(item.category)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(item.title)
                .font(.largeTitle.weight(.bold))
                .lineSpacing(4)

            Text(item.summary)
                .foregroundStyle(.secondary)
                .lineSpacing(5)

            Text(item.legalBoundary)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
        }
    }

    private var memoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("相談前メモ", systemImage: "doc.text")
                .font(.title3.weight(.bold))

            Text(memoText)
                .font(.callout.monospaced())
                .textSelection(.enabled)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))

            Button {
                UIPasteboard.general.string = memoText
                showCopied = true
            } label: {
                Label("相談メモをコピー", systemImage: "doc.on.doc")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var sourceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("参考情報", systemImage: "link")
                .font(.title3.weight(.bold))

            ForEach(item.sourceKeys.compactMap { SourceDirectory.links[$0] }) { source in
                Link(destination: source.url) {
                    HStack {
                        Text(source.title)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                    }
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private func detailSection(_ title: String, systemImage: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: systemImage)
                .font(.title3.weight(.bold))
            ForEach(items, id: \.self) { text in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 6))
                        .padding(.top, 7)
                        .foregroundStyle(.secondary)
                    Text(text)
                        .lineSpacing(4)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.separator), lineWidth: 0.5)
        }
    }

    private var urgencyColor: Color {
        switch item.urgency {
        case .high: return .red
        case .medium: return .blue
        case .low: return .green
        }
    }

    private var memoText: String {
        var lines = [
            "【相談テーマ】\(item.title)",
            "【カテゴリー】\(item.category)",
            "【緊急度】\(item.urgency.rawValue)",
            "",
            "【起きたこと】",
            "いつ:",
            "どこで:",
            "誰が関係しているか:",
            "何に困っているか:",
            "",
            "【手元にある証拠】"
        ]
        lines += item.evidence.map { "- \($0): " }
        lines += ["", "【相談先に聞きたいこと】"]
        lines += item.memo.map { "- \($0): " }
        lines += ["", "【注意】\(item.legalBoundary)"]
        return lines.joined(separator: "\n")
    }
}
