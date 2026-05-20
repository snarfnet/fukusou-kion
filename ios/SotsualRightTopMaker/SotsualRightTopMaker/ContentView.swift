import PhotosUI
import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @State private var path: [PhotoTemplate] = []
    @State private var purchasePack: TemplatePack?

    var body: some View {
        NavigationStack(path: $path) {
            HomeView(
                onChooseTemplate: { path.append(TemplateLibrary.templates[0]) },
                onPurchase: { purchasePack = .eventPack }
            )
            .navigationDestination(for: PhotoTemplate.self) { template in
                EditorView(template: template)
            }
            .sheet(item: $purchasePack) { pack in
                PurchaseView(pack: pack)
            }
        }
    }
}

private struct HomeView: View {
    let onChooseTemplate: () -> Void
    let onPurchase: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(colors: [.white, Color(red: 0.93, green: 0.96, blue: 0.95)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                Spacer(minLength: 30)

                VStack(spacing: 10) {
                    Text("卒業写真にのれなかった君へ")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.78)

                    Text("集合写真にいなかった人を、あの右上の丸いやつで救うアプリ。")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                AlbumHeroPreview()
                    .frame(height: 250)
                    .padding(.horizontal, 18)

                VStack(spacing: 12) {
                    NavigationLink {
                        TemplatePickerView()
                    } label: {
                        Label("テンプレートを選ぶ", systemImage: "photo.on.rectangle.angled")
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Button {
                    } label: {
                        Label("作成履歴", systemImage: "clock.arrow.circlepath")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .disabled(true)

                    Button(action: onPurchase) {
                        Label("追加テンプレートを購入", systemImage: "lock.open")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                .padding(.horizontal, 18)

                Text("写真はサーバーへ送らず、端末内で処理します。本人または保護者の許可を得た写真を使ってください。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 22)

                Spacer(minLength: 20)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct TemplatePickerView: View {
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @State private var purchasePack: TemplatePack?

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                ForEach(TemplateLibrary.templates) { template in
                    if template.isPaid && !purchaseManager.isUnlocked(template) {
                        Button {
                            purchasePack = template.category == .secondPack ? .secondPack : .eventPack
                        } label: {
                            TemplateCard(template: template, isLocked: true)
                        }
                        .buttonStyle(.plain)
                    } else {
                        NavigationLink(value: template) {
                            TemplateCard(template: template, isLocked: false)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(16)
        }
        .background(Color(red: 0.96, green: 0.97, blue: 0.96))
        .navigationTitle("テンプレート")
        .sheet(item: $purchasePack) { pack in
            PurchaseView(pack: pack)
        }
    }
}

private struct TemplateCard: View {
    let template: PhotoTemplate
    let isLocked: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(uiImage: AlbumImageExporter.render(template: template, state: {
                var state = EditorState()
                state.applyDefaults(from: template)
                return state
            }(), absentImage: nil))
            .resizable()
            .scaledToFill()
            .frame(width: 126, height: 92)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(template.name)
                        .font(.headline.weight(.bold))
                    if isLocked {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(.secondary)
                    }
                }

                Text(template.category.rawValue)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(template.isPaid ? .orange : .green)

                Text(template.defaultTitleText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()
            Image(systemName: isLocked ? "cart.fill" : "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(.white, in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.black.opacity(0.06)))
    }
}

private struct EditorView: View {
    let template: PhotoTemplate

    @State private var state = EditorState()
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var absentImage: UIImage?
    @State private var selectedTool: EditorTool = .photo
    @State private var showsTextEditor = false
    @State private var showsSave = false
    @State private var hasLoadedDefaults = false

    private var renderedImage: UIImage {
        AlbumImageExporter.render(template: template, state: state, absentImage: absentImage)
    }

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { proxy in
                ZStack {
                    Image(uiImage: renderedImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    circleHandle(in: proxy.size)
                }
                .padding(10)
                .background(Color(red: 0.90, green: 0.92, blue: 0.92))
            }

            Picker("編集", selection: $selectedTool) {
                ForEach(EditorTool.allCases) { tool in
                    Text(tool.rawValue).tag(tool)
                }
            }
            .pickerStyle(.segmented)
            .padding([.horizontal, .top], 12)

            toolPanel
                .frame(minHeight: 178)
                .padding(12)
                .background(.white)
        }
        .navigationTitle(template.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            guard !hasLoadedDefaults else { return }
            state.applyDefaults(from: template)
            hasLoadedDefaults = true
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                guard let data = try? await newItem?.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else { return }
                absentImage = image
            }
        }
        .sheet(isPresented: $showsTextEditor) {
            TextInputView(text: $state.text)
        }
        .sheet(isPresented: $showsSave) {
            SaveView(image: renderedImage)
        }
    }

    @ViewBuilder
    private var toolPanel: some View {
        switch selectedTool {
        case .photo:
            VStack(alignment: .leading, spacing: 12) {
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Label(absentImage == nil ? "顔写真を選ぶ" : "写真を変更", systemImage: "person.crop.circle")
                }
                .buttonStyle(PrimaryButtonStyle())

                Text("選んだ写真は端末内だけで使います。顔の位置は丸窓調整で整えてください。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        case .circle:
            VStack(spacing: 12) {
                SliderRow(title: "丸窓サイズ", value: $state.circleSize, range: 0.12...0.28)
                SliderRow(title: "写真拡大", value: $state.photoScale, range: 0.7...2.4)
                SliderRow(title: "写真左右", value: Binding(get: {
                    state.photoOffset.width
                }, set: {
                    state.photoOffset.width = $0
                }), range: -0.08...0.08)
                SliderRow(title: "写真上下", value: Binding(get: {
                    state.photoOffset.height
                }, set: {
                    state.photoOffset.height = $0
                }), range: -0.08...0.08)
                SliderRow(title: "枠の太さ", value: $state.borderWidth, range: 0...24)
                SliderRow(title: "回転", value: Binding(get: {
                    state.photoRotation.degrees
                }, set: {
                    state.photoRotation = .degrees($0)
                }), range: -30...30)

                HStack {
                    Toggle("白フチ", isOn: $state.showsBorder)
                    Toggle("影", isOn: $state.showsShadow)
                }
                .font(.subheadline.weight(.semibold))
            }
        case .text:
            VStack(alignment: .leading, spacing: 12) {
                Text(state.text.titleLine)
                    .font(.headline)
                    .lineLimit(1)
                Text(state.text.schoolLine)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Button {
                    showsTextEditor = true
                } label: {
                    Label("文字を編集", systemImage: "text.cursor")
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        case .filter:
            VStack(alignment: .leading, spacing: 12) {
                Picker("フィルター", selection: $state.filter) {
                    ForEach(TemplateFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                Text("戦後まもないテンプレートは白黒が初期値です。必要に応じて変更できます。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        case .save:
            VStack(alignment: .leading, spacing: 12) {
                Button {
                    showsSave = true
                } label: {
                    Label("保存画面へ", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(PrimaryButtonStyle())
                Text("背景、丸窓、文字を1枚の画像として書き出します。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func circleHandle(in size: CGSize) -> some View {
        let previewSize = fittedImageSize(container: size, aspect: AlbumImageExporter.outputSize.width / AlbumImageExporter.outputSize.height)
        let origin = CGPoint(x: (size.width - previewSize.width) / 2 + 10, y: (size.height - previewSize.height) / 2 + 10)
        let side = previewSize.width * state.circleSize
        let center = CGPoint(
            x: origin.x + previewSize.width * state.circleCenter.x,
            y: origin.y + previewSize.height * state.circleCenter.y
        )

        return Circle()
            .stroke(.yellow, lineWidth: 3)
            .frame(width: side, height: side)
            .position(center)
            .contentShape(Circle())
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let x = (value.location.x - origin.x) / previewSize.width
                        let y = (value.location.y - origin.y) / previewSize.height
                        state.circleCenter = CGPoint(x: min(max(x, 0.08), 0.92), y: min(max(y, 0.06), 0.55))
                    }
            )
    }

    private func fittedImageSize(container: CGSize, aspect: CGFloat) -> CGSize {
        let available = CGSize(width: max(1, container.width - 20), height: max(1, container.height - 20))
        let byWidth = CGSize(width: available.width, height: available.width / aspect)
        if byWidth.height <= available.height {
            return byWidth
        }
        return CGSize(width: available.height * aspect, height: available.height)
    }
}

private struct TextInputView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var text: AlbumText

    private let titleOptions = ["卒業記念", "卒業記念写真", "修学旅行記念", "体育祭記念", "文化祭記念", "林間学校", "遠足記念", "集合写真"]

    var body: some View {
        NavigationStack {
            Form {
                Section("年度とタイトル") {
                    TextField("年度", text: $text.year)
                    Picker("タイトル", selection: $text.title) {
                        ForEach(titleOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    TextField("タイトルを自由入力", text: $text.title)
                }

                Section("学校情報") {
                    TextField("学校名", text: $text.schoolName)
                    TextField("学年", text: $text.grade)
                        .keyboardType(.numberPad)
                    TextField("組", text: $text.classroom)
                }

                Section("欠席者") {
                    TextField("欠席者名", text: $text.absenteeName)
                    TextField("コメント", text: $text.comment, axis: .vertical)
                }

                Section("表示") {
                    Text(text.titleLine)
                    Text(text.schoolLine)
                }
            }
            .navigationTitle("文字入力")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct SaveView: View {
    let image: UIImage

    @Environment(\.dismiss) private var dismiss
    @State private var message: String?
    @State private var saveHandler = PhotoSaveHandler()
    @State private var showsShare = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(.black.opacity(0.08)))

                VStack(spacing: 12) {
                    Button {
                        saveHandler.save(image) { success, error in
                            message = success ? "写真アプリに保存しました" : (error?.localizedDescription ?? "保存できませんでした")
                        }
                    } label: {
                        Label("画像として保存", systemImage: "square.and.arrow.down")
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Button {
                        showsShare = true
                    } label: {
                        Label("共有", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(SecondaryButtonStyle())

                    Button {
                        saveHandler.save(image) { success, error in
                            message = success ? "高画質画像を保存しました" : (error?.localizedDescription ?? "保存できませんでした")
                        }
                    } label: {
                        Label("印刷用高画質保存", systemImage: "printer")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }

                if let message {
                    Text(message)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .navigationTitle("保存")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showsShare) {
                ActivityView(items: [image])
            }
        }
    }
}

private struct PurchaseView: View {
    let pack: TemplatePack

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var purchaseManager: PurchaseManager

    private var priceText: String {
        purchaseManager.product(for: pack)?.displayPrice ?? ""
    }

    private var buyLabel: String {
        priceText.isEmpty ? "購入" : "\(priceText)で購入"
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Text(pack.title)
                    .font(.system(size: 28, weight: .black, design: .rounded))
                Text(pack.description)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(pack.templateNames, id: \.self) { name in
                        Label(name, systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.headline)
                    }
                }

                Spacer()

                if let message = purchaseManager.purchaseMessage {
                    Text(message)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                Button {
                    Task { await purchaseManager.purchase(pack) }
                } label: {
                    Label(purchaseManager.isUnlocked(pack) ? "購入済み" : buyLabel, systemImage: "cart.fill")
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(purchaseManager.isUnlocked(pack))

                Button {
                    Task { await purchaseManager.restore() }
                } label: {
                    Label("購入を復元", systemImage: "arrow.clockwise")
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            .padding()
            .navigationTitle("追加テンプレート")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct AlbumHeroPreview: View {
    var body: some View {
        Image(uiImage: AlbumImageExporter.render(template: TemplateLibrary.templates[0], state: EditorState(), absentImage: nil))
            .resizable()
            .scaledToFit()
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(color: .black.opacity(0.18), radius: 18, y: 10)
            .rotationEffect(.degrees(-1.2))
    }
}

private struct SliderRow: View {
    let title: String
    @Binding var value: CGFloat
    let range: ClosedRange<CGFloat>

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.caption.weight(.bold))
                .frame(width: 74, alignment: .leading)
            Slider(value: $value, in: range)
        }
    }
}

private struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
    }
}

private struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.bold))
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .foregroundStyle(.white)
            .background(Color.black.opacity(configuration.isPressed ? 0.72 : 0.92), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.bold))
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .foregroundStyle(.black)
            .background(Color.white.opacity(configuration.isPressed ? 0.72 : 1), in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(.black.opacity(0.10)))
    }
}

#Preview {
    ContentView()
        .environmentObject(PurchaseManager())
}
