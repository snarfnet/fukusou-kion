import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

struct VideoPicker: UIViewControllerRepresentable {
    var onPick: (URL) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .videos
        configuration.selectionLimit = 1
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        var onPick: (URL) -> Void

        init(onPick: @escaping (URL) -> Void) {
            self.onPick = onPick
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let provider = results.first?.itemProvider,
                  provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) else { return }

            provider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { url, _ in
                guard let url else { return }
                let destination = FileManager.default.temporaryDirectory
                    .appendingPathComponent("picked-\(UUID().uuidString)")
                    .appendingPathExtension(url.pathExtension.isEmpty ? "mov" : url.pathExtension)
                do {
                    try? FileManager.default.removeItem(at: destination)
                    try FileManager.default.copyItem(at: url, to: destination)
                    DispatchQueue.main.async {
                        self.onPick(destination)
                    }
                } catch {
                    return
                }
            }
        }
    }
}
