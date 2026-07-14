import SwiftUI

struct PhraseCardView: View {
    @EnvironmentObject var app: AppViewModel; @StateObject private var speech = SpeechService(); let card: PhraseCard
    @State private var large = false; @State private var showingResponses = false
    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                Text(card.text(in: app.language)).font(.headline).foregroundStyle(.secondary)
                Text("Show this screen to a Japanese person").font(.subheadline)
                Text(card.japaneseText).font(.system(size: large ? 54 : 40, weight: .bold)).minimumScaleFactor(0.45).multilineTextAlignment(.center).frame(maxWidth: .infinity, minHeight: 260).padding().background(.white, in: RoundedRectangle(cornerRadius: 20)).foregroundStyle(.black).shadow(color:.black.opacity(0.08), radius: 8)
                if card.categoryID == "medical" { Label("このアプリは診断を行いません。緊急時は119番へ連絡してください。", systemImage:"cross.case").font(.footnote).foregroundStyle(.red) }
                HStack { action(speech.isSpeaking ? "Stop" : "Speak", speech.isSpeaking ? "stop.fill" : "speaker.wave.2.fill") { speech.toggle(card.japaneseText) }; action("Larger", "textformat.size") { large.toggle() }; action("Favorite", app.favorites.contains(card.id) ? "star.fill":"star") { app.toggleFavorite(card.id) } }
                ShareLink(item: card.japaneseText) { Label("Share Japanese phrase", systemImage:"square.and.arrow.up").frame(maxWidth:.infinity) }.buttonStyle(.bordered)
                if card.responseType != .none { Button("Japanese response buttons") { showingResponses = true }.buttonStyle(PrimaryButtonStyle()) }
            }.padding()
        }.background(Color(.systemGroupedBackground)).navigationBarTitleDisplayMode(.inline).onAppear { app.record(card.id) }.sheet(isPresented:$showingResponses) { ResponseView(language: app.language) }
    }
    func action(_ title:String,_ icon:String, perform:@escaping()->Void)->some View { Button(action:perform){VStack{Image(systemName:icon).font(.title2);Text(title).font(.caption)}}.frame(maxWidth:.infinity,minHeight:54).buttonStyle(.bordered).accessibilityLabel(title) }
}

struct ResponseView: View {
    @Environment(\.dismiss) var dismiss; let language: AppLanguage; @State private var selected: Response?
    var body: some View { NavigationStack { Group { if let selected { VStack(spacing:24){ Text(selected.translation[language.rawValue] ?? selected.translation["en"]!).font(.system(size:44,weight:.bold)).multilineTextAlignment(.center); Button("Back to responses"){self.selected=nil}.buttonStyle(.borderedProminent) }.padding() } else { List(Response.all) { response in Button(response.japanese){selected=response}.font(.title3).frame(minHeight:44) } } }.navigationTitle("Response").toolbar{Button("Done"){dismiss()}} } }
    struct Response: Identifiable { let id:String; let japanese:String; let translation:[String:String]
        static let all = [
            Response(id:"yes",japanese:"はい",translation:["en":"Yes.","zh-Hans":"是。","ko":"네.","es":"Sí."]), Response(id:"no",japanese:"いいえ",translation:["en":"No.","zh-Hans":"不是。","ko":"아니요.","es":"No."]),
            Response(id:"wait",japanese:"少々お待ちください",translation:["en":"Please wait a moment.","zh-Hans":"请稍等。","ko":"잠시만 기다려 주세요.","es":"Espere un momento."]), Response(id:"cash",japanese:"現金のみです",translation:["en":"Cash only.","zh-Hans":"只收现金。","ko":"현금만 가능합니다.","es":"Solo efectivo."]),
            Response(id:"unknown",japanese:"わかりません",translation:["en":"I do not know.","zh-Hans":"我不知道。","ko":"잘 모르겠습니다.","es":"No lo sé."]),
            Response(id:"not_here",japanese:"ここではできません",translation:["en":"It is not available here.","zh-Hans":"这里不能办理。","ko":"여기에서는 할 수 없습니다.","es":"Aquí no se puede."]),
            Response(id:"elsewhere",japanese:"別の場所でできます",translation:["en":"It is available at another location.","zh-Hans":"可以在其他地方办理。","ko":"다른 곳에서 할 수 있습니다.","es":"Se puede hacer en otro lugar."]),
            Response(id:"sold_out",japanese:"売り切れです",translation:["en":"It is sold out.","zh-Hans":"已经售罄。","ko":"품절입니다.","es":"Está agotado."]),
            Response(id:"card",japanese:"カードが使えます",translation:["en":"You can pay by card.","zh-Hans":"可以用卡支付。","ko":"카드를 사용할 수 있습니다.","es":"Puede pagar con tarjeta."]),
            Response(id:"reservation",japanese:"予約が必要です",translation:["en":"A reservation is required.","zh-Hans":"需要预约。","ko":"예약이 필요합니다.","es":"Se necesita reserva."]),
            Response(id:"ten",japanese:"約10分です",translation:["en":"It will take about 10 minutes.","zh-Hans":"大约需要10分钟。","ko":"약 10분 걸립니다.","es":"Tardará unos 10 minutos."]),
            Response(id:"thirty",japanese:"約30分です",translation:["en":"It will take about 30 minutes.","zh-Hans":"大约需要30分钟。","ko":"약 30분 걸립니다.","es":"Tardará unos 30 minutos."])
        ]
    }
}

#Preview { NavigationStack { PhraseCardView(card: .init(id:"1",categoryID:"food",iconName:"fork.knife",japaneseText:"お会計をお願いします。",translations:["en":"The check, please."],searchKeywords:[],responseType:.payment,isEmergency:false)) }.environmentObject(AppViewModel()) }
