import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

struct VideoPicker: View {
    @Binding var selection: PhotosPickerItem?

    var body: some View {
        PhotosPicker(selection: $selection, matching: .videos) {
            Label("動画を選択", systemImage: "video.badge.plus")
        }
    }
}

struct PickedVideo: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { video in
            SentTransferredFile(video.url)
        } importing: { received in
            let filename = received.file.lastPathComponent.isEmpty ? "picked.mov" : received.file.lastPathComponent
            let copyURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension((filename as NSString).pathExtension.isEmpty ? "mov" : (filename as NSString).pathExtension)
            if FileManager.default.fileExists(atPath: copyURL.path) {
                try FileManager.default.removeItem(at: copyURL)
            }
            try FileManager.default.copyItem(at: received.file, to: copyURL)
            return PickedVideo(url: copyURL)
        }
    }
}
