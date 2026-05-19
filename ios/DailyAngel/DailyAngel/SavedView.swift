import SwiftUI

struct SavedView: View {
    @EnvironmentObject private var store: AngelMessageStore

    var body: some View {
        NavigationStack {
            ZStack {
                AngelBackground()

                if store.savedMessages.isEmpty {
                    VStack(spacing: 14) {
                        Image(systemName: "bookmark")
                            .font(.system(size: 48))
                            .foregroundStyle(AngelColors.gold)
                        Text("まだ保存された手紙はありません")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(AngelColors.ink)
                        Text("心に残った言葉は、今日の画面か詳細画面から保存できます。")
                            .font(.callout)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(AngelColors.ink.opacity(0.66))
                            .padding(.horizontal, 34)
                    }
                } else {
                    List(store.savedMessages) { message in
                        NavigationLink {
                            MessageDetailView(message: message)
                        } label: {
                            MessageRow(message: message, saved: true)
                        }
                        .listRowBackground(Color.white.opacity(0.54))
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("保存した手紙")
        }
    }
}
