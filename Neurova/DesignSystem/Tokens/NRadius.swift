import CoreGraphics

enum NRadius {
    static let small: CGFloat = 8
    static let button: CGFloat = 14
    static let card: CGFloat = 18
    static let sheet: CGFloat = 22
    static let large: CGFloat = 24
    static let navigationBar: CGFloat = 28
    static let chip: CGFloat = 999
}

// Ejemplo: .clipShape(.rect(cornerRadius: NRadius.card))
