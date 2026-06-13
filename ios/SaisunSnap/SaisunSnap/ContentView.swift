import PhotosUI
import SwiftUI

struct ContentView: View {
    @State private var category: ClothingCategory = .tops
    @State private var items: [MeasurementItem] = ClothingCategory.tops.measurementItems
    @State private var photoItem: PhotosPickerItem?
    @State private var image: UIImage?
    @State private var showAnnotator = false

    var body: some View {
        NavigationStack {
            Form {
                Section("カテゴリ") {
                    Picker("カテゴリ", selection: $category) {
                        ForEach(ClothingCategory.allCases) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: category) { _, newValue in
                        items = newValue.measurementItems
                    }
                }

                Section("寸法を入力") {
                    ForEach($items) { $item in
                        HStack {
                            Text(item.name)
                            Spacer()
                            TextField("0.0", text: $item.value)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                            Text("cm")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("写真") {
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        Label(image == nil ? "写真を選ぶ" : "写真を変更", systemImage: "photo")
                    }

                    if let image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 240)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }

                Section("出品説明") {
                    DescriptionView(category: category, items: items)
                }

                Section {
                    Button {
                        showAnnotator = true
                    } label: {
                        Label("写真に寸法を書き込む", systemImage: "pencil.and.outline")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(image == nil || !items.contains(where: \.isFilled))
                }
                .listRowBackground(Color.clear)
            }
            .navigationTitle("採寸カメラ")
            .onChange(of: photoItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let loadedImage = UIImage(data: data) {
                        image = loadedImage.normalizedOrientation()
                    }
                }
            }
            .fullScreenCover(isPresented: $showAnnotator) {
                if let image {
                    AnnotatorView(image: image, items: items.filter(\.isFilled))
                }
            }
        }
    }
}

struct DescriptionView: View {
    let category: ClothingCategory
    let items: [MeasurementItem]
    @State private var copied = false

    var text: String {
        let filled = items.filter(\.isFilled)
        guard !filled.isEmpty else {
            return "寸法を入力すると、出品説明に使える文章を作成します。"
        }

        let lines = filled.map { "・\($0.name): 約\($0.value)cm" }
        return """
        【実寸】
        \(category.rawValue)
        \(lines.joined(separator: "\n"))

        平置き採寸です。多少の誤差はご了承ください。
        """
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(text)
                .font(.footnote)
                .foregroundStyle(.secondary)

            Button {
                UIPasteboard.general.string = text
                copied = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    copied = false
                }
            } label: {
                Label(copied ? "コピーしました" : "説明文をコピー",
                      systemImage: copied ? "checkmark" : "doc.on.doc")
            }
            .font(.footnote)
        }
    }
}

private extension UIImage {
    func normalizedOrientation() -> UIImage {
        guard imageOrientation != .up else { return self }

        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

#Preview {
    ContentView()
}
