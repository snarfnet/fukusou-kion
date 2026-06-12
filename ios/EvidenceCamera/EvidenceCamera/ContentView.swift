import MapKit
import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var store = EvidenceStore()

    var body: some View {
        TabView {
            CaptureView()
                .environmentObject(store)
                .tabItem {
                    Label("撮る", systemImage: "camera.fill")
                }

            EvidenceListView()
                .environmentObject(store)
                .tabItem {
                    Label("記録", systemImage: "checklist.checked")
                }
        }
        .tint(.green)
    }
}

struct CaptureView: View {
    @EnvironmentObject private var store: EvidenceStore
    @StateObject private var camera = CameraModel()
    @StateObject private var context = CaptureContext()
    @State private var sessionID = UUID()
    @State private var note = ""
    @State private var sequenceNumber = 1
    @State private var status = "撮影できます"

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if camera.isReady {
                    CameraPreview(session: camera.session)
                        .ignoresSafeArea()
                } else {
                    CameraPlaceholder(permissionDenied: camera.permissionDenied)
                }

                VStack(spacing: 0) {
                    EvidenceOverlay(
                        context: context,
                        sequenceNumber: sequenceNumber,
                        status: status
                    )
                    .padding()

                    Spacer()

                    VStack(spacing: 12) {
                        TextField("メモ 例：置き配、清掃後、駐車位置", text: $note)
                            .textFieldStyle(.plain)
                            .padding(.horizontal, 14)
                            .frame(height: 46)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                        HStack(spacing: 18) {
                            Button {
                                startNewSession()
                            } label: {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.title2)
                                    .frame(width: 54, height: 54)
                            }
                            .buttonStyle(.bordered)
                            .tint(.white)
                            .accessibilityLabel("新しい連続撮影ログ")

                            Button {
                                capture()
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(.white)
                                        .frame(width: 76, height: 76)
                                    Circle()
                                        .stroke(.black.opacity(0.35), lineWidth: 3)
                                        .frame(width: 64, height: 64)
                                }
                            }
                            .disabled(!camera.isReady || camera.isCapturing)
                            .accessibilityLabel("証拠写真を撮影")

                            NavigationLink {
                                EvidenceListView()
                                    .environmentObject(store)
                            } label: {
                                Image(systemName: "photo.stack")
                                    .font(.title2)
                                    .frame(width: 54, height: 54)
                            }
                            .buttonStyle(.bordered)
                            .tint(.white)
                            .accessibilityLabel("撮影記録")
                        }
                    }
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.clear, .black.opacity(0.65)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .ignoresSafeArea()
                    )
                }
            }
            .navigationTitle("証拠カメラ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.black.opacity(0.25), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .onAppear {
            camera.configure()
            context.start()
        }
        .onDisappear {
            context.stop()
        }
    }

    private func capture() {
        status = "保存中"
        camera.capture { result in
            switch result {
            case .success(let imageData):
                do {
                    let previousHash = store.records.first { $0.metadata.sessionID == sessionID }?.hash
                    let metadata = CaptureMetadata(
                        capturedAt: Date(),
                        latitude: context.location?.coordinate.latitude,
                        longitude: context.location?.coordinate.longitude,
                        altitude: context.location?.altitude,
                        horizontalAccuracy: context.location?.horizontalAccuracy,
                        address: context.address,
                        trueHeading: context.heading?.trueHeading,
                        magneticHeading: context.heading?.magneticHeading,
                        pitch: context.pitch,
                        roll: context.roll,
                        yaw: context.yaw,
                        deviceModel: UIDevice.current.model,
                        systemVersion: UIDevice.current.systemVersion,
                        sessionID: sessionID,
                        sequenceNumber: sequenceNumber,
                        previousHash: previousHash,
                        note: note
                    )
                    try store.saveCapture(imageData: imageData, metadata: metadata)
                    sequenceNumber += 1
                    status = "保存しました"
                } catch {
                    status = "保存に失敗しました"
                }
            case .failure:
                status = "撮影に失敗しました"
            }
        }
    }

    private func startNewSession() {
        sessionID = UUID()
        sequenceNumber = 1
        note = ""
        status = "新しいログを開始"
    }
}

struct EvidenceOverlay: View {
    @ObservedObject var context: CaptureContext
    let sequenceNumber: Int
    let status: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(status, systemImage: "shield.checkered")
                Spacer()
                Text("#\(sequenceNumber)")
            }
            .font(.headline)

            Divider().overlay(.white.opacity(0.4))

            Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 6) {
                GridRow {
                    Text("日時")
                    Text(Date.now, format: .dateTime.year().month().day().hour().minute().second())
                }
                GridRow {
                    Text("位置")
                    Text(locationText)
                }
                GridRow {
                    Text("方角")
                    Text(degreeText(context.heading?.trueHeading))
                }
                GridRow {
                    Text("傾き")
                    Text(tiltText)
                }
            }
            .font(.caption)
        }
        .foregroundStyle(.white)
        .padding(14)
        .background(.black.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var locationText: String {
        guard let location = context.location else {
            return context.authorizationText
        }
        return String(format: "%.5f, %.5f", location.coordinate.latitude, location.coordinate.longitude)
    }

    private var tiltText: String {
        String(
            format: "P %.1f / R %.1f",
            radiansToDegrees(context.pitch),
            radiansToDegrees(context.roll)
        )
    }
}

struct CameraPlaceholder: View {
    let permissionDenied: Bool

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: permissionDenied ? "camera.badge.ellipsis" : "camera.metering.center.weighted")
                .font(.system(size: 54))
            Text(permissionDenied ? "カメラの許可が必要です" : "カメラを準備中")
                .font(.headline)
            Text(permissionDenied ? "設定アプリでカメラを許可してください" : "実機で撮影できます")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .foregroundStyle(.white)
    }
}

struct EvidenceListView: View {
    @EnvironmentObject private var store: EvidenceStore

    var body: some View {
        NavigationStack {
            Group {
                if store.records.isEmpty {
                    ContentUnavailableView(
                        "記録はまだありません",
                        systemImage: "camera",
                        description: Text("撮影すると、写真と証拠情報がここに残ります。")
                    )
                } else {
                    List {
                        ForEach(store.records) { record in
                            NavigationLink {
                                EvidenceDetailView(record: record)
                                    .environmentObject(store)
                            } label: {
                                EvidenceRow(record: record)
                                    .environmentObject(store)
                            }
                        }
                        .onDelete { offsets in
                            offsets.map { store.records[$0] }.forEach(store.delete)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("撮影記録")
        }
    }
}

struct EvidenceRow: View {
    @EnvironmentObject private var store: EvidenceStore
    let record: EvidenceRecord

    var body: some View {
        HStack(spacing: 12) {
            if let image = store.image(for: record) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.gray.opacity(0.2))
                    .frame(width: 72, height: 72)
                    .overlay(Image(systemName: "photo"))
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(record.metadata.note.isEmpty ? "証拠写真" : record.metadata.note)
                    .font(.headline)
                    .lineLimit(1)
                Text(record.metadata.capturedAt, format: .dateTime.year().month().day().hour().minute())
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Label(store.verificationState(for: record).title, systemImage: "checkmark.seal")
                    .font(.caption)
                    .foregroundStyle(store.verificationState(for: record) == .verified ? .green : .orange)
            }
        }
        .padding(.vertical, 4)
    }
}

struct EvidenceDetailView: View {
    @EnvironmentObject private var store: EvidenceStore
    let record: EvidenceRecord

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if let image = store.image(for: record) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                VerificationCard(state: store.verificationState(for: record), hash: record.hash)

                if let coordinate = record.coordinate {
                    Map(initialPosition: .region(MKCoordinateRegion(
                        center: coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.006, longitudeDelta: 0.006)
                    ))) {
                        Marker("撮影場所", coordinate: coordinate)
                    }
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                MetadataSection(record: record)
            }
            .padding()
        }
        .navigationTitle("証拠情報")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct VerificationCard: View {
    let state: VerificationState
    let hash: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(state.title, systemImage: state == .verified ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(state == .verified ? .green : .orange)
            Text(state == .verified ? "撮影後の変更は検出されていません。" : "写真または記録情報が変わった可能性があります。")
                .foregroundStyle(.secondary)
            Text(hash)
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct MetadataSection: View {
    let record: EvidenceRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("撮影データ")
                .font(.headline)

            LabeledContent("撮影日時", value: record.metadata.capturedAt.formatted(date: .abbreviated, time: .standard))
            LabeledContent("緯度", value: optionalNumber(record.metadata.latitude, digits: 6))
            LabeledContent("経度", value: optionalNumber(record.metadata.longitude, digits: 6))
            LabeledContent("住所", value: record.metadata.address ?? "未取得")
            LabeledContent("方角", value: degreeText(record.metadata.trueHeading))
            LabeledContent("磁北方角", value: degreeText(record.metadata.magneticHeading))
            LabeledContent("端末の傾き", value: tiltText)
            LabeledContent("端末", value: "\(record.metadata.deviceModel) / iOS \(record.metadata.systemVersion)")
            LabeledContent("連続撮影ログ", value: "#\(record.metadata.sequenceNumber)")
            LabeledContent("写真ID", value: record.id.uuidString)

            if let previousHash = record.metadata.previousHash {
                LabeledContent("前の写真", value: String(previousHash.prefix(12)))
            }
        }
        .font(.subheadline)
    }

    private var tiltText: String {
        String(
            format: "Pitch %.1f / Roll %.1f / Yaw %.1f",
            radiansToDegrees(record.metadata.pitch),
            radiansToDegrees(record.metadata.roll),
            radiansToDegrees(record.metadata.yaw)
        )
    }
}

private func optionalNumber(_ value: Double?, digits: Int) -> String {
    guard let value else { return "未取得" }
    return String(format: "%.\(digits)f", value)
}

private func degreeText(_ value: Double?) -> String {
    guard let value, value >= 0 else { return "未取得" }
    return String(format: "%.1f°", value)
}

private func radiansToDegrees(_ value: Double?) -> Double {
    guard let value else { return 0 }
    return value * 180 / .pi
}
