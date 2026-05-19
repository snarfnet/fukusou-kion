import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var store: AngelMessageStore
    let message: AngelMessage

    var body: some View {
        NavigationStack {
            ZStack {
                AngelBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        header
                        MessageCard(message: message, showDay: false)
                        actionPanel
                        reminderPanel
                        notePanel
                    }
                    .padding(20)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("天使の手紙")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button {
                    store.toggleSaved(message)
                } label: {
                    Image(systemName: store.isSaved(message) ? "bookmark.fill" : "bookmark")
                }
                .accessibilityLabel(store.isSaved(message) ? "保存を解除" : "保存")
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                CapsuleLabel(text: "Day \(message.day)", systemImage: "calendar")
                CapsuleLabel(text: message.themeJa, systemImage: AngelTheme.colorName(for: message.theme))
            }

            Text("今日届いた言葉")
                .font(.system(size: 36, weight: .black, design: .serif))
                .foregroundStyle(AngelColors.ink)
                .fixedSize(horizontal: false, vertical: true)

            Text("天使語風の短い言葉を、日本語と英語で読めます。")
                .font(.callout)
                .foregroundStyle(AngelColors.ink.opacity(0.72))
        }
    }

    private var actionPanel: some View {
        MessagePanel {
            VStack(alignment: .leading, spacing: 10) {
                Label("今日の小さな行動", systemImage: "checkmark.circle")
                    .font(.headline)
                    .foregroundStyle(AngelColors.teal)

                Text(message.actionJa)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(AngelColors.ink)

                Text(message.actionEn)
                    .font(.subheadline)
                    .foregroundStyle(AngelColors.ink.opacity(0.68))
            }
        }
    }

    private var reminderPanel: some View {
        MessagePanel {
            HStack(alignment: .center, spacing: 14) {
                Image(systemName: store.reminderEnabled ? "bell.fill" : "bell")
                    .font(.title2)
                    .foregroundStyle(AngelColors.gold)
                    .frame(width: 34)

                VStack(alignment: .leading, spacing: 4) {
                    Text("毎朝 7:30 に受け取る")
                        .font(.headline)
                        .foregroundStyle(AngelColors.ink)
                    Text("通知は端末内だけで動きます。")
                        .font(.caption)
                        .foregroundStyle(AngelColors.ink.opacity(0.62))
                }

                Spacer()

                Toggle("", isOn: Binding(
                    get: { store.reminderEnabled },
                    set: { enabled in
                        if enabled {
                            Task { await store.scheduleDailyReminder() }
                        } else {
                            store.cancelDailyReminder()
                        }
                    }
                ))
                .labelsHidden()
            }
        }
    }

    private var notePanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("天使語は、エノク語に着想を得た雰囲気フレーズです。未来を断定するものではありません。")
                .font(.footnote)
                .foregroundStyle(AngelColors.ink.opacity(0.62))
        }
        .padding(.horizontal, 4)
    }
}

struct MessageCard: View {
    let message: AngelMessage
    var showDay = true

    var body: some View {
        MessagePanel {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    if showDay {
                        CapsuleLabel(text: "Day \(message.day)", systemImage: "calendar")
                    }
                    Spacer()
                    Image(systemName: AngelTheme.colorName(for: message.theme))
                        .font(.title3)
                        .foregroundStyle(AngelColors.gold)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("ANGELIC")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(AngelColors.gold)
                    Text(message.angelic)
                        .font(.system(size: 30, weight: .black, design: .serif))
                        .foregroundStyle(AngelColors.cobalt)
                        .minimumScaleFactor(0.78)
                        .lineLimit(2)
                }

                Divider().overlay(AngelColors.ink.opacity(0.16))

                VStack(alignment: .leading, spacing: 8) {
                    Text("日本語")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AngelColors.teal)
                    Text(message.ja)
                        .font(.title3.weight(.semibold))
                        .lineSpacing(4)
                        .foregroundStyle(AngelColors.ink)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("English")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AngelColors.teal)
                    Text(message.en)
                        .font(.body)
                        .lineSpacing(3)
                        .foregroundStyle(AngelColors.ink.opacity(0.78))
                }
            }
        }
    }
}

#Preview {
    TodayView(message: AngelMessageStore().todayMessage)
        .environmentObject(AngelMessageStore())
}
