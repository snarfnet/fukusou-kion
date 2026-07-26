import SwiftUI
import UIKit

struct ImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(sourceType) ? sourceType : .photoLibrary
        if picker.sourceType == .camera {
            picker.cameraCaptureMode = .photo
            picker.cameraDevice = .rear
            let guide = UIHostingController(
                rootView: ZStack {
                    FullBodyGuide()
                    VStack {
                        Text("頭から足元まで枠内に入れてください")
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(.black.opacity(0.55), in: Capsule())
                            .padding(.top, 54)
                        Spacer()
                        Text("正面を向き、腕を少し体から離します")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(.black.opacity(0.55), in: Capsule())
                            .padding(.bottom, 118)
                    }
                }
            )
            guide.view.backgroundColor = .clear
            guide.view.isUserInteractionEnabled = false
            guide.view.frame = UIScreen.main.bounds
            picker.cameraOverlayView = guide.view
            context.coordinator.overlayController = guide
        }
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        var overlayController: UIViewController?
        init(_ parent: ImagePicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            parent.image = info[.originalImage] as? UIImage
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
