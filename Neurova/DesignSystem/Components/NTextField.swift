import SwiftUI
import UIKit

struct NTextField: View {
    @Binding private var text: String
    @State private var isFocused = false

    private let title: String

    init(title: String, text: Binding<String>) {
        self.title = title
        _text = text
    }

    var body: some View {
        NOptimizedTextField(
            placeholder: title,
            text: $text,
            isFocused: $isFocused,
            returnKeyType: .done,
            autocapitalization: .sentences
        )
        .font(NTypography.body)
        .foregroundStyle(NColors.Text.textPrimary)
        .padding(.horizontal, NSpacing.md)
        .frame(height: 48)
        .background(NColors.Neutrals.surfaceAlt)
        .overlay(
            RoundedRectangle(cornerRadius: NRadius.button, style: .continuous)
                .stroke(isFocused ? NColors.Brand.neuroBlue : NColors.Neutrals.border, lineWidth: 1)
        )
        .clipShape(
            RoundedRectangle(cornerRadius: NRadius.button, style: .continuous)
        )
    }
}

struct NOptimizedTextField: UIViewRepresentable {
    let placeholder: String
    @Binding var text: String
    @Binding var isFocused: Bool
    var returnKeyType: UIReturnKeyType = .done
    var autocapitalization: UITextAutocapitalizationType = .sentences
    var font: UIFont = .systemFont(ofSize: 15, weight: .regular)
    var textColor: UIColor = UIColor.label
    var tintColor: UIColor = UIColor.systemBlue
    var onSubmit: (() -> Void)? = nil

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UITextField {
        NKeyboardWarmup.prepareIfNeeded()

        let textField = UITextField(frame: .zero)
        textField.delegate = context.coordinator
        textField.returnKeyType = returnKeyType
        textField.autocorrectionType = .no
        textField.autocapitalizationType = autocapitalization
        textField.spellCheckingType = .no
        textField.smartDashesType = .no
        textField.smartQuotesType = .no
        textField.smartInsertDeleteType = .no
        textField.textContentType = .none
        textField.clearButtonMode = .never
        textField.adjustsFontForContentSizeCategory = true
        textField.font = font
        textField.text = text
        textField.placeholder = placeholder
        textField.textColor = textColor
        textField.tintColor = tintColor
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textDidChange(_:)), for: .editingChanged)
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        context.coordinator.parent = self

        if uiView.text != text {
            uiView.text = text
        }

        if uiView.placeholder != placeholder {
            uiView.placeholder = placeholder
        }

        uiView.returnKeyType = returnKeyType
        uiView.autocapitalizationType = autocapitalization
        uiView.font = font
        uiView.textColor = textColor
        uiView.tintColor = tintColor

        if isFocused, uiView.isFirstResponder == false {
            uiView.becomeFirstResponder()
        } else if isFocused == false, uiView.isFirstResponder {
            uiView.resignFirstResponder()
        }
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: NOptimizedTextField

        init(_ parent: NOptimizedTextField) {
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
            parent.onSubmit?()
            parent.isFocused = false
            textField.resignFirstResponder()
            return false
        }
    }
}

struct NOptimizedInputField: View {
    let placeholder: String
    @Binding var text: String
    var returnKeyType: UIReturnKeyType = .done
    var autocapitalization: UITextAutocapitalizationType = .sentences
    var font: UIFont = .systemFont(ofSize: 15, weight: .regular)
    var textColor: UIColor = UIColor.label
    var tintColor: UIColor = UIColor.systemBlue
    var onSubmit: (() -> Void)? = nil

    @State private var isFocused = false

    var body: some View {
        NOptimizedTextField(
            placeholder: placeholder,
            text: $text,
            isFocused: $isFocused,
            returnKeyType: returnKeyType,
            autocapitalization: autocapitalization,
            font: font,
            textColor: textColor,
            tintColor: tintColor,
            onSubmit: onSubmit
        )
    }
}

enum NKeyboardWarmup {
    private static var hasPrepared = false

    static func prepareIfNeeded() {
        guard hasPrepared == false else { return }
        hasPrepared = true
        _ = UITextInputMode.activeInputModes
        _ = UITextChecker()
    }
}
