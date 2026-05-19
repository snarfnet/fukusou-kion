import SwiftUI

struct LibraryView: View {
    @EnvironmentObject private var store: AngelMessageStore
    @State private var searchText = ""

    private var filteredMessages: [AngelMessage] {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return store.messages
        }

        return store.messages.filter {
            $0.angelic.localizedCaseInsensitiveContains(searchText)
            || $0.ja.localizedCaseInsensitiveContains(searchText)
            || $0.en.localizedCaseInsensitiveContains(searchText)
            || $0.themeJa.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AngelBackground()

                List(filteredMessages) { message in
                    NavigationLink {
                        MessageDetailView(message: message)
                    } label: {
                        MessageRow(message: message, saved: store.isSaved(message))
                    }
                    .listRowBackground(Color.white.opacity(0.54))
                }
                .scrollContentBackground(.hidden)
                .searchable(text: $searchText, prompt: "言葉を探す")
            }
            .navigationTitle("365日の手紙")
        }
    }
}

struct MessageRow: View {
    let message: AngelMessage
    let saved: Bool

    var body: some View {
        HStack(spacing: 12) {
            Text("\(message.day)")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(AngelColors.cobalt, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(message.angelic)
                    .font(.system(.headline, design: .serif).weight(.bold))
                    .foregroundStyle(AngelColors.ink)
                    .lineLimit(1)
                Text(message.ja)
                    .font(.caption)
                    .foregroundStyle(AngelColors.ink.opacity(0.68))
                    .lineLimit(2)
            }

            if saved {
                Image(systemName: "bookmark.fill")
                    .foregroundStyle(AngelColors.gold)
            }
        }
        .padding(.vertical, 4)
    }
}

struct MessageDetailView: View {
    @EnvironmentObject private var store: AngelMessageStore
    let message: AngelMessage

    var body: some View {
        ZStack {
            AngelBackground()
            ScrollView {
                VStack(spacing: 18) {
                    MessageCard(message: message)

                    MessagePanel {
                        VStack(alignment: .leading, spacing: 8) {
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
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Day \(message.day)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button {
                store.toggleSaved(message)
            } label: {
                Image(systemName: store.isSaved(message) ? "bookmark.fill" : "bookmark")
            }
        }
    }
}
