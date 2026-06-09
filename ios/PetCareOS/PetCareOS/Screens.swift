import SwiftUI

struct MemoriesView: View {
    @Binding var state: AppState

    var body: some View {
        VStack(spacing: 14) {
            SoftCard(padding: 0) {
                VStack(alignment: .leading, spacing: 14) {
                    Image("MokaSpringMemory")
                        .resizable()
                        .scaledToFill()
                        .frame(height: 220)
                        .clipped()
                    VStack(alignment: .leading, spacing: 8) {
                        SectionKicker(text: "思い出アルバム")
                        Text("写真だけでなく、日付・体調・家族メモまで残せます。")
                            .font(.title3.weight(.bold))
                        Text("無料版は30枚まで。Plusで保存数アップ。")
                            .font(.caption)
                            .foregroundStyle(PetTheme.muted)
                    }
                    .padding([.horizontal, .bottom], 16)
                }
            }

            HStack(spacing: 10) {
                albumTile("今日の1枚", "MokaMorningSun", "camera")
                albumTile("春のおさんぽ", "MokaSpringMemory", "leaf")
            }

            SoftCard {
                VStack(spacing: 10) {
                    ActionRow(title: "迷子QRカード", subtitle: "緊急連絡先と投薬メモを表示", icon: "qrcode") {
                        state.showingSafetyCard = true
                    }
                    ActionRow(title: "家族共有", subtitle: "招待コードでメンバー追加", icon: "person.2") {
                        state.showingFamily = true
                    }
                    ActionRow(title: "成長アルバム書き出し", subtitle: "有料追加パック 500円", icon: "square.and.arrow.up") {
                        state.detailTitle = "成長アルバム書き出し"
                        state.detailText = "月ごとの写真と体重メモを、家族に送れるアルバムとして書き出します。"
                        state.showingDetail = true
                    }
                    ActionRow(title: "思い出カードテーマ", subtitle: "160円から300円", icon: "sparkles") {
                        state.detailTitle = "思い出カードテーマ"
                        state.detailText = "季節、誕生日、通院記録などに合わせたカードテーマを追加できます。"
                        state.showingDetail = true
                    }
                }
            }
        }
    }

    private func albumTile(_ title: String, _ image: String, _ icon: String) -> some View {
        Button {
            state.detailTitle = title
            state.detailText = "写真にメモを添えて、体調の変化や大切な瞬間を残します。"
            state.showingDetail = true
        } label: {
            ZStack(alignment: .bottomLeading) {
                Image(image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 150)
                    .clipped()
                LinearGradient(colors: [.clear, .black.opacity(0.45)], startPoint: .top, endPoint: .bottom)
                HStack {
                    Image(systemName: icon)
                    Text(title)
                }
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .padding(12)
            }
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct RecordView: View {
    @Binding var state: AppState

    var body: some View {
        VStack(spacing: 14) {
            SoftCard {
                VStack(alignment: .leading, spacing: 12) {
                    SectionKicker(text: "記録する")
                    Text("今日の変化を短く残すだけで、病院で話しやすくなります。")
                        .font(.title3.weight(.bold))
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 76), spacing: 10)], spacing: 10) {
                        ForEach(RecordKind.allCases, id: \.self) { kind in
                            recordKindButton(kind)
                        }
                    }
                }
            }

            SoftCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        IconBubble(systemName: state.selectedRecordKind.icon)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(state.selectedRecordKind.rawValue)
                                .font(.headline.weight(.bold))
                            Text("記録内容を選んでメモを足します")
                                .font(.caption)
                                .foregroundStyle(PetTheme.muted)
                        }
                    }

                    if state.selectedRecordKind == .photo {
                        photoPickerMock
                    }

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 8)], spacing: 8) {
                        ForEach(state.selectedRecordKind.options, id: \.self) { option in
                            Button {
                                state.selectedRecordOption = option
                            } label: {
                                Text(option)
                                    .font(.caption.weight(.bold))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 38)
                                    .background(state.selectedRecordOption == option ? PetTheme.coral.opacity(0.18) : .white.opacity(0.58))
                                    .clipShape(Capsule())
                                    .overlay(Capsule().stroke(state.selectedRecordOption == option ? PetTheme.coral.opacity(0.45) : PetTheme.line))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    TextEditor(text: $state.recordNote)
                        .frame(minHeight: 116)
                        .scrollContentBackground(.hidden)
                        .padding(10)
                        .background(.white.opacity(0.58))
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(alignment: .topLeading) {
                            if state.recordNote.isEmpty {
                                Text(state.selectedRecordKind.notePlaceholder)
                                    .font(.caption)
                                    .foregroundStyle(PetTheme.muted)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 18)
                            }
                        }

                    Button {
                        saveRecord()
                    } label: {
                        Label("記録を保存", systemImage: "checkmark.circle.fill")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(PetTheme.coral)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .onChange(of: state.selectedRecordKind) { _, newKind in
            state.selectedRecordOption = newKind.options.first ?? ""
        }
    }

    private func recordKindButton(_ kind: RecordKind) -> some View {
        Button {
            state.selectedRecordKind = kind
        } label: {
            VStack(spacing: 7) {
                Image(systemName: kind.icon)
                    .font(.system(size: 20, weight: .semibold))
                Text(kind.rawValue)
                    .font(.caption.weight(.bold))
            }
            .foregroundStyle(state.selectedRecordKind == kind ? .white : PetTheme.ink)
            .frame(maxWidth: .infinity)
            .frame(height: 72)
            .background(state.selectedRecordKind == kind ? PetTheme.sageDark : .white.opacity(0.62))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var photoPickerMock: some View {
        Button {
            state.detailTitle = "写真を追加"
            state.detailText = "実装時はPhotosUIでカメラロールから選択し、写真・日付・メモを同じ記録に保存します。"
            state.showingDetail = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "photo.badge.plus")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(PetTheme.coral)
                    .frame(width: 52, height: 52)
                    .background(PetTheme.coral.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                VStack(alignment: .leading, spacing: 3) {
                    Text("写真を追加")
                        .font(.headline.weight(.bold))
                    Text("症状写真や思い出写真を記録に添付")
                        .font(.caption)
                        .foregroundStyle(PetTheme.muted)
                }
                Spacer()
            }
            .padding(12)
            .background(.white.opacity(0.58))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func saveRecord() {
        let detail = state.recordNote.isEmpty ? state.selectedRecordOption : "\(state.selectedRecordOption)・\(state.recordNote)"
        state.timeline.insert(TimelineEntry(icon: state.selectedRecordKind.icon, title: state.selectedRecordKind.rawValue, detail: detail, time: "今"), at: 0)
        state.recordNote = ""
        state.selectedTab = .home
    }
}

struct CalendarView: View {
    @Binding var state: AppState
    private let days = Array(1...30)

    var body: some View {
        VStack(spacing: 14) {
            Button {
                withAnimation(.snappy) {
                    state.calendarFormOpen.toggle()
                }
            } label: {
                Label(state.calendarFormOpen ? "登録欄を閉じる" : "予定を追加", systemImage: "plus")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(PetTheme.sageDark)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)

            if state.calendarFormOpen {
                SoftCard {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionKicker(text: "カレンダー登録")
                        Picker("予定", selection: $state.calendarKind) {
                            ForEach(["通院", "ワクチン", "薬", "トリミング", "保険更新"], id: \.self) { Text($0) }
                        }
                        .pickerStyle(.segmented)
                        TextField("例: 青葉動物病院 10:30", text: $state.calendarNote)
                            .textFieldStyle(.roundedBorder)
                        Button {
                            state.detailTitle = "予定を登録しました"
                            state.detailText = "\(state.calendarKind)の予定を6月18日に追加しました。通知も設定できます。"
                            state.showingDetail = true
                            state.calendarFormOpen = false
                            state.calendarNote = ""
                        } label: {
                            Text("この内容で登録")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(PetTheme.coral)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            SoftCard {
                VStack(alignment: .leading, spacing: 12) {
                    SectionKicker(text: "2026年6月")
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 8) {
                        ForEach(days, id: \.self) { day in
                            VStack(spacing: 4) {
                                Text("\(day)")
                                    .font(.caption.weight(.bold))
                                Circle()
                                    .fill([9, 18, 23].contains(day) ? PetTheme.coral : .clear)
                                    .frame(width: 5, height: 5)
                            }
                            .frame(height: 42)
                            .background(day == 18 ? PetTheme.coral.opacity(0.16) : .white.opacity(0.45))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }
                }
            }

            SoftCard {
                VStack(spacing: 10) {
                    ActionRow(title: "定期検診", subtitle: "6月18日 10:30 青葉動物病院", icon: "stethoscope") {
                        state.showingVet = true
                    }
                    ActionRow(title: "ワクチン予定", subtitle: "6月23日 通知あり", icon: "syringe") {
                        state.detailTitle = "ワクチン予定"
                        state.detailText = "接種履歴、次回予定、病院メモを一緒に管理します。"
                        state.showingDetail = true
                    }
                    ActionRow(title: "保険更新", subtitle: "証券番号と補償内容を保存", icon: "doc.text") {
                        state.showingInsurance = true
                    }
                }
            }
        }
    }
}

struct HealthView: View {
    @Binding var state: AppState

    var body: some View {
        VStack(spacing: 14) {
            SoftCard {
                VStack(alignment: .leading, spacing: 14) {
                    SectionKicker(text: "健康管理")
                    Text("体重は安定。食欲だけ少し様子見。")
                        .font(.title2.weight(.bold))
                    Text("診察で見せられる30日レポートを作れます。無料版は月3回まで、残り2回です。")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.88))
                    Button {
                        state.showingHospital = true
                    } label: {
                        Label("病院用PDFを作成", systemImage: "doc.text")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(PetTheme.sageDark.opacity(0.7))
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                .foregroundStyle(.white)
                .padding(6)
                .background(PetTheme.sageDark)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            }

            HStack(spacing: 10) {
                MetricPill(value: "4.8kg", label: "体重", icon: "waveform.path.ecg")
                MetricPill(value: "96%", label: "薬の実施率", icon: "pills")
                MetricPill(value: "2回", label: "食欲少なめ", icon: "takeoutbag.and.cup.and.straw")
            }

            SoftCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            SectionKicker(text: "体重推移")
                            Text("ゆるやかで安定")
                                .font(.title3.weight(.bold))
                        }
                        Spacer()
                        Text("30日")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(PetTheme.coral)
                    }
                    WeightChart()
                }
            }

            SoftCard {
                VStack(spacing: 10) {
                    ActionRow(title: "AI健康メモ", subtitle: "入力した記録から、病院で伝える要点を整理", icon: "sparkles") {
                        state.detailTitle = "AI健康メモ"
                        state.detailText = "例: ここ3日で食欲少なめが2回、体重は4.8kgで安定。咳や嘔吐は未記録。診察では食欲低下のタイミングと薬の実施状況を伝えるとよさそうです。"
                        state.showingDetail = true
                    }
                    ActionRow(title: "保険情報", subtitle: "証券番号、補償割合、請求メモ", icon: "shield") {
                        state.showingInsurance = true
                    }
                    ActionRow(title: "かかりつけ病院", subtitle: "電話、住所、診察メモ", icon: "cross.case") {
                        state.showingVet = true
                    }
                    ActionRow(title: "Plus 買い切り 1,480円", subtitle: "複数ペット、家族共有、通知無制限、PDF、広告なし", icon: "star") {
                        state.showingPlus = true
                    }
                }
            }

            SoftCard {
                VStack(alignment: .leading, spacing: 12) {
                    SectionKicker(text: "症状テンプレ")
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 102), spacing: 8)], spacing: 8) {
                        ForEach(["咳", "嘔吐", "下痢", "かゆみ", "食欲低下", "元気なし"], id: \.self) { symptom in
                            Button {
                                state.selectedRecordKind = .symptom
                                state.selectedRecordOption = symptom
                                state.selectedTab = .record
                            } label: {
                                Text(symptom)
                                    .font(.caption.weight(.bold))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 38)
                                    .background(.white.opacity(0.58))
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
}

struct ActionRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                IconBubble(systemName: icon)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.subheadline.weight(.bold))
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(PetTheme.muted)
                        .lineLimit(2)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(PetTheme.muted)
            }
            .padding(.vertical, 7)
        }
        .buttonStyle(.plain)
    }
}

struct MetricPill: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        SoftCard(padding: 12) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(PetTheme.coral)
                Text(value)
                    .font(.headline.weight(.bold))
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(PetTheme.muted)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 92)
        }
    }
}

struct WeightChart: View {
    private let points: [CGFloat] = [0.38, 0.42, 0.36, 0.46, 0.44, 0.50, 0.47, 0.52]

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(LinearGradient(colors: [PetTheme.sage.opacity(0.18), PetTheme.coral.opacity(0.11)], startPoint: .topLeading, endPoint: .bottomTrailing))
            GeometryReader { proxy in
                let width = proxy.size.width
                let height = proxy.size.height
                Path { path in
                    for index in points.indices {
                        let x = width * CGFloat(index) / CGFloat(points.count - 1)
                        let y = height * (1 - points[index])
                        if index == points.startIndex {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(PetTheme.sageDark, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))

                ForEach(points.indices, id: \.self) { index in
                    Circle()
                        .fill(index == points.indices.last ? PetTheme.coral : .white)
                        .overlay(Circle().stroke(PetTheme.sageDark, lineWidth: 2))
                        .frame(width: 13, height: 13)
                        .position(x: width * CGFloat(index) / CGFloat(points.count - 1), y: height * (1 - points[index]))
                }
            }
            .padding(18)
        }
        .frame(height: 172)
        .overlay(alignment: .topLeading) {
            Text("4.8kg")
                .font(.caption.weight(.bold))
                .foregroundStyle(PetTheme.sageDark)
                .padding(14)
        }
    }
}

struct DetailSheet: View {
    let title: String
    let text: String

    var body: some View {
        SheetScaffold(title: title, icon: "info.circle") {
            Text(text)
                .font(.body)
                .foregroundStyle(PetTheme.muted)
                .lineSpacing(4)
        }
    }
}

struct PlusSheet: View {
    var body: some View {
        SheetScaffold(title: "Plus 買い切り", icon: "star.fill") {
            Text("1,480円で、長く使う人向けの制限を外します。月額ではありません。")
                .font(.subheadline)
                .foregroundStyle(PetTheme.muted)
            VStack(spacing: 10) {
                FeatureRow("複数ペット", "家族共有", "person.2")
                FeatureRow("通知無制限", "PDFレポート", "doc.text")
                FeatureRow("広告なし", "写真保存数アップ", "photo")
            }
            Divider()
            Text("追加パック: AI健康メモ50回 300円、病院用PDFテンプレ 300円、成長アルバム書き出し 500円、思い出カードテーマ 160円から300円。")
                .font(.caption)
                .foregroundStyle(PetTheme.muted)
        }
    }
}

struct PetProfileSheet: View {
    var body: some View {
        SheetScaffold(title: "モカの登録情報", icon: "pawprint.fill") {
            Image("MokaHomeHero")
                .resizable()
                .scaledToFill()
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            FeatureRow("名前", "モカ", "tag")
            FeatureRow("年齢・種類", "12歳・ミックス犬", "calendar")
            FeatureRow("体重", "4.8kg", "waveform.path.ecg")
            FeatureRow("注意メモ", "食欲が落ちた時は早めに相談", "exclamationmark.triangle")
        }
    }
}

struct HospitalSheet: View {
    var body: some View {
        SheetScaffold(title: "病院用PDF", icon: "doc.text.fill") {
            Text("無料版: 月3回まで。今月の残りは2回です。")
                .font(.headline.weight(.bold))
            FeatureRow("30日レポート", "食事、体重、薬、症状を整理", "list.clipboard")
            FeatureRow("診察メモ", "AI健康メモの要約を添付", "sparkles")
            FeatureRow("写真", "症状写真を最大6枚まで掲載", "photo.on.rectangle")
        }
    }
}

struct SafetyCardSheet: View {
    var body: some View {
        SheetScaffold(title: "迷子QRカード", icon: "qrcode") {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.white)
                .frame(height: 180)
                .overlay {
                    Image(systemName: "qrcode")
                        .font(.system(size: 118, weight: .regular))
                        .foregroundStyle(PetTheme.ink)
                }
            FeatureRow("緊急連絡先", "080-0000-0000", "phone")
            FeatureRow("健康メモ", "フィラリア予防薬、食欲低下時は注意", "cross.case")
        }
    }
}

struct FamilySheet: View {
    var body: some View {
        SheetScaffold(title: "家族共有", icon: "person.2.fill") {
            Text("招待コード: MOKA-0629")
                .font(.title3.weight(.bold))
                .frame(maxWidth: .infinity)
                .padding()
                .background(PetTheme.coral.opacity(0.13))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            FeatureRow("ママ", "管理者", "person.crop.circle")
            FeatureRow("パパ", "薬と散歩", "pills")
            FeatureRow("さくら", "写真とごはん", "camera")
        }
    }
}

struct InsuranceSheet: View {
    var body: some View {
        SheetScaffold(title: "保険情報", icon: "shield.fill") {
            FeatureRow("保険会社", "PetLife保険", "building.2")
            FeatureRow("証券番号", "PL-2480-0629", "number")
            FeatureRow("補償割合", "通院70%・手術90%", "percent")
            FeatureRow("請求メモ", "領収書と診療明細を写真保存", "doc.viewfinder")
        }
    }
}

struct VetSheet: View {
    var body: some View {
        SheetScaffold(title: "かかりつけ病院", icon: "cross.case.fill") {
            FeatureRow("青葉動物病院", "東京都世田谷区 / 10:00-19:00", "mappin.and.ellipse")
            FeatureRow("電話", "03-0000-0000", "phone.fill")
            FeatureRow("主治医", "佐藤先生", "stethoscope")
            FeatureRow("次回予定", "6月18日 10:30 定期検診", "calendar.badge.clock")
        }
    }
}

struct FeatureRow: View {
    let title: String
    let subtitle: String
    let icon: String

    init(_ title: String, _ subtitle: String, _ icon: String) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
    }

    var body: some View {
        HStack(spacing: 12) {
            IconBubble(systemName: icon)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(PetTheme.muted)
            }
            Spacer()
        }
        .padding(12)
        .background(.white.opacity(0.58))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct SheetScaffold<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    IconBubble(systemName: icon)
                    Text(title)
                        .font(.title2.weight(.bold))
                    Spacer()
                }
                content
            }
            .padding(20)
        }
        .background(PetTheme.background)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
