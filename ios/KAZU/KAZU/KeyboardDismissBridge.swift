import SwiftUI
import UIKit

struct KeyboardDismissBridge: UIViewRepresentable {
    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WindowObserverView {
        let view = WindowObserverView()
        view.isUserInteractionEnabled = false
        view.onWindowChanged = { context.coordinator.attach(to: $0) }
        return view
    }

    func updateUIView(_ uiView: WindowObserverView, context: Context) {}

    static func dismantleUIView(_ uiView: WindowObserverView, coordinator: Coordinator) {
        coordinator.detach()
    }

    static func dismiss() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }

    final class WindowObserverView: UIView {
        var onWindowChanged: ((UIWindow?) -> Void)?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            onWindowChanged?(window)
        }
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        private weak var window: UIWindow?
        private lazy var recognizer: UITapGestureRecognizer = {
            let value = UITapGestureRecognizer(target: self, action: #selector(handleTap))
            value.cancelsTouchesInView = false
            value.delegate = self
            return value
        }()

        func attach(to newWindow: UIWindow?) {
            guard window !== newWindow else { return }
            detach()
            guard let newWindow else { return }
            window = newWindow
            newWindow.addGestureRecognizer(recognizer)
        }

        func detach() {
            window?.removeGestureRecognizer(recognizer)
            window = nil
        }

        @objc private func handleTap() {
            window?.endEditing(true)
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            var current = touch.view
            while let view = current {
                if view is UITextField || view is UITextView { return false }
                current = view.superview
            }
            return true
        }
    }
}
