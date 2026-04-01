import SwiftUI
import UIKit

struct OnboardingDeckTextField: UIViewRepresentable {
    let placeholder: String
    @Binding var text: String
    @Binding var isFocused: Bool
    let isDark: Bool
    let onSubmit: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UITextField {
        KeyboardWarmup.prepareServicesIfNeeded()

        let textField = UITextField(frame: .zero)
        textField.delegate = context.coordinator
        textField.returnKeyType = .done
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .words
        textField.spellCheckingType = .no
        textField.smartDashesType = .no
        textField.smartQuotesType = .no
        textField.smartInsertDeleteType = .no
        textField.textContentType = .none
        textField.clearButtonMode = .never
        textField.adjustsFontForContentSizeCategory = true
        textField.font = .systemFont(ofSize: 15, weight: .regular)
        textField.text = text
        textField.placeholder = placeholder
        textField.textColor = uiTextColor
        textField.tintColor = NColors.Onboarding.textFieldTint
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textDidChange(_:)), for: .editingChanged)
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
        if uiView.placeholder != placeholder {
            uiView.placeholder = placeholder
        }
        uiView.textColor = uiTextColor

        if isFocused, uiView.isFirstResponder == false {
            uiView.becomeFirstResponder()
        } else if isFocused == false, uiView.isFirstResponder {
            uiView.resignFirstResponder()
        }
    }

    private var uiTextColor: UIColor {
        NColors.Onboarding.uiTextColor
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        private var parent: OnboardingDeckTextField

        init(_ parent: OnboardingDeckTextField) {
            self.parent = parent
        }

        @objc
        func textDidChange(_ textField: UITextField) {
            parent.text = textField.text ?? ""
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            parent.isFocused = true
            let end = textField.endOfDocument
            textField.selectedTextRange = textField.textRange(from: end, to: end)
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            parent.isFocused = false
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            parent.onSubmit()
            parent.isFocused = false
            textField.resignFirstResponder()
            return false
        }
    }
}

enum KeyboardWarmup {
    private static var hasPrepared = false

    static func prepareServicesIfNeeded() {
        guard hasPrepared == false else { return }
        hasPrepared = true

        _ = UITextInputMode.activeInputModes
        _ = UITextChecker()
    }
}
