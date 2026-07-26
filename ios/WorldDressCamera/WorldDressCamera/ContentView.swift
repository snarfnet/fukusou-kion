import SwiftUI
import Photos

struct ContentView: View {
    @State private var photo: UIImage?
    @State private var selected: Garment?
    @State private var pickerSource: UIImagePickerController.SourceType = .camera
    @State private var showsPicker = false
    @State private var showsCatalog = false
    @State private var showsGuide = true
    @State private var offset: CGSize = .zero
    @State private var committedOffset: CGSize = .zero
    @State private var scale: CGFloat = 1
    @State private var committedScale: CGFloat = 1
    @State private var rotation = Angle.zero
    @State private var committedRotation = Angle.zero
    @State private var notice: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.055, green: 0.06, blue: 0.075).ignoresSafeArea()
                VStack(spacing: 14) {
                    editor
                    controls
                }
                .padding(.horizontal)
            }
            .navigationTitle("民族衣装カメラ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showsPicker) {
                ImagePicker(sourceType: pickerSource, image: $photo)
                    .ignoresSafeArea()
            }
            .sheet(isPresented: $showsCatalog) {
                CatalogView(selection: $selected)
            }
            .alert("お知らせ", isPresented: Binding(get: { notice != nil }, set: { if !$0 { notice = nil } })) {
                Button("OK") { notice = nil }
            } message: {
                Text(notice ?? "")
            }
            .onChange(of: selected?.id) { _, _ in resetTransform() }
        }
        .preferredColorScheme(.dark)
    }

    private var editor: some View {
        GeometryReader { proxy in
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(red: 0.11, green: 0.12, blue: 0.15))

                if let photo {
                    Image(uiImage: photo)
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "person.crop.rectangle")
                            .font(.system(size: 48, weight: .thin))
                        Text("全身が入るように撮影してください")
                            .font(.headline)
                        Text("正面を向き、腕を少し体から離すと\n衣装を合わせやすくなります")
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                    }
                }

                if showsGuide { FullBodyGuide().padding(12) }

                if let selected, UIImage(named: selected.imageName) != nil {
                    Image(selected.imageName)
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(scale)
                        .rotationEffect(rotation)
                        .offset(offset)
                        .gesture(
                            DragGesture()
                                .onChanged {
                                    offset = CGSize(width: committedOffset.width + $0.translation.width,
                                                    height: committedOffset.height + $0.translation.height)
                                }
                                .onEnded { _ in committedOffset = offset }
                        )
                        .simultaneousGesture(
                            MagnificationGesture()
                                .onChanged { scale = min(max(committedScale * $0, 0.45), 2.5) }
                                .onEnded { _ in committedScale = scale }
                        )
                        .simultaneousGesture(
                            RotationGesture()
                                .onChanged { rotation = committedRotation + $0 }
                                .onEnded { _ in committedRotation = rotation }
                        )
                        .accessibilityLabel("\(selected.community)の\(selected.garmentName)")
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(alignment: .topTrailing) {
                Button { showsGuide.toggle() } label: {
                    Label("ガイド", systemImage: showsGuide ? "viewfinder.circle.fill" : "viewfinder.circle")
                        .labelStyle(.iconOnly)
                        .font(.title2)
                        .padding(12)
                        .background(.black.opacity(0.4), in: Circle())
                }
                .padding(10)
            }
        }
        .aspectRatio(3 / 4, contentMode: .fit)
    }

    private var controls: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                action("撮影", "camera.fill") {
                    pickerSource = .camera
                    showsPicker = true
                }
                action("写真", "photo.on.rectangle") {
                    pickerSource = .photoLibrary
                    showsPicker = true
                }
                action("衣装", "tshirt.fill") { showsCatalog = true }
                action("保存", "square.and.arrow.down.fill") { save() }
            }
            if let selected {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(selected.garmentName).font(.headline)
                        Text("\(selected.community)・\(selected.region)")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button {
                        resetTransform()
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                    }
                    .accessibilityLabel("衣装の位置を戻す")
                    NavigationLink("詳しく見る") { GarmentDetailView(garment: selected) }
                        .font(.subheadline.bold())
                }
                .padding(12)
                .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    private func resetTransform() {
        offset = .zero
        committedOffset = .zero
        scale = 1
        committedScale = 1
        rotation = .zero
        committedRotation = .zero
    }

    private func action(_ title: String, _ icon: String, perform: @escaping () -> Void) -> some View {
        Button(action: perform) {
            VStack(spacing: 5) {
                Image(systemName: icon).font(.title3)
                Text(title).font(.caption.bold())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 13))
        }
    }

    @MainActor
    private func save() {
        guard let photo else {
            notice = "先に写真を撮影するか、写真ライブラリから選んでください。"
            return
        }
        let output = ImageComposer.compose(photo: photo, garment: selected.flatMap { UIImage(named: $0.imageName) },
                                           offset: offset, scale: scale, rotation: rotation)
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else {
                Task { @MainActor in notice = "写真への保存を許可してください。" }
                return
            }
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: output)
            } completionHandler: { success, error in
                Task { @MainActor in
                    notice = success ? "合成写真を保存しました。" : "保存できませんでした。\(error?.localizedDescription ?? "")"
                }
            }
        }
    }
}

private struct CatalogView: View {
    @Binding var selection: Garment?
    @Environment(\.dismiss) private var dismiss
    @State private var gender: GarmentGender = .women
    @State private var search = ""

    var filtered: [Garment] {
        GarmentCatalog.all.filter {
            $0.gender == gender && (search.isEmpty || "\($0.community) \($0.garmentName) \($0.region)".localizedCaseInsensitiveContains(search))
        }
    }

    var body: some View {
        NavigationStack {
            VStack {
                Picker("種類", selection: $gender) {
                    ForEach(GarmentGender.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                List(filtered) { item in
                    Button {
                        selection = item
                        dismiss()
                    } label: {
                        HStack(spacing: 14) {
                            Image(item.imageName)
                                .resizable().scaledToFit()
                                .frame(width: 58, height: 78)
                                .background(.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 9))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.garmentName).font(.headline)
                                Text(item.community).foregroundStyle(.secondary)
                                Text(item.region).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
                .searchable(text: $search, prompt: "民族・衣装・地域を検索")
            }
            .navigationTitle("衣装を選ぶ")
            .toolbar { Button("閉じる") { dismiss() } }
        }
    }
}

struct GarmentDetailView: View {
    let garment: Garment
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Image(garment.imageName)
                    .resizable().scaledToFit()
                    .frame(maxWidth: .infinity).frame(height: 330)
                    .background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 22))
                Text(garment.community).font(.title3.bold())
                detail("地域", garment.region)
                detail("衣装について", garment.summary)
                detail("歴史", garment.history)
                detail("着用場面", garment.occasions)
                detail("素材・技法", garment.materials)
                Text("衣装は地域、時代、家族、宗教、着用場面によって異なります。この解説は代表例を簡潔に紹介したものです。")
                    .font(.footnote).foregroundStyle(.secondary)
                if let url = garment.sourceURL {
                    Link("参考資料：\(garment.sourceTitle)", destination: url)
                }
            }
            .padding()
        }
        .navigationTitle(garment.garmentName)
        .navigationBarTitleDisplayMode(.inline)
    }
    private func detail(_ heading: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(heading).font(.headline)
            Text(text).font(.body).foregroundStyle(.secondary)
        }
    }
}
