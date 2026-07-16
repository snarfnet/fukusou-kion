import SwiftUI
import UIKit

struct NativeKanaInput: UIViewRepresentable {
    @Binding var isFocused: Bool
    let onInput: (Character) -> Void
    let onDelete: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeUIView(context: Context) -> UITextField {
        let field = UITextField(frame: .zero)
        field.autocorrectionType = .no
        field.autocapitalizationType = .none
        field.spellCheckingType = .no
        field.returnKeyType = .done
        field.delegate = context.coordinator
        field.addTarget(context.coordinator, action: #selector(Coordinator.textChanged(_:)), for: .editingChanged)
        return field
    }

    func updateUIView(_ field: UITextField, context: Context) {
        context.coordinator.parent = self
        if isFocused, !field.isFirstResponder { field.becomeFirstResponder() }
        if !isFocused, field.isFirstResponder { field.resignFirstResponder() }
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: NativeKanaInput

        init(parent: NativeKanaInput) { self.parent = parent }

        @objc func textChanged(_ field: UITextField) {
            guard field.markedTextRange == nil, let text = field.text, !text.isEmpty else { return }
            for character in text where character.isJapaneseCrosswordCharacter {
                parent.onInput(character)
            }
            field.text = ""
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            parent.isFocused = false
            return true
        }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            if string.isEmpty, (textField.text ?? "").isEmpty {
                parent.onDelete()
                return false
            }
            return true
        }
    }
}

private extension Character {
    var isJapaneseCrosswordCharacter: Bool {
        unicodeScalars.allSatisfy { scalar in
            (0x3040...0x30FF).contains(scalar.value) || scalar.value == 0x30FC
        }
    }
}
