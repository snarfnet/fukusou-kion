import SwiftUI

struct JapaneseCardView: View {
    let item: LostItemCase
    @Environment(\.dismiss) private var dismiss
    @StateObject private var speech = SpeechService()
    @State private var isLarge = false
    private var text: String { JapaneseCardService().text(for: item) }
    var body: some View { ScrollView { VStack(spacing: 24) { Text("日本語を話す方へ").font(.headline).foregroundStyle(.brandBlue); Text(text).font(isLarge ? .largeTitle : .title2).fontWeight(.semibold).frame(maxWidth: .infinity, alignment: .leading).textSelection(.enabled); if let data = item.photoData.first, let image = UIImage(data: data) { Image(uiImage: image).resizable().scaledToFit().frame(maxHeight: 240).clipShape(RoundedRectangle(cornerRadius: 16)) }; HStack { Button { speech.isSpeaking ? speech.stop() : speech.speak(text) } label: { Label(speech.isSpeaking ? "card.stop" : "card.speak", systemImage: speech.isSpeaking ? "stop.fill" : "speaker.wave.2.fill") }.buttonStyle(.borderedProminent).controlSize(.large); Button { isLarge.toggle() } label: { Label("card.enlarge", systemImage: "textformat.size.larger") }.buttonStyle(.bordered).controlSize(.large) } }.padding() }.navigationTitle("card.title").toolbar { ToolbarItem(placement: .confirmationAction) { Button("common.close") { speech.stop(); dismiss() } } } }
}

