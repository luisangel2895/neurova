import SwiftUI

enum NImages {
    enum Brand {
        static let logoMark = Image("LogoMark")
        static let logoPrimary = Image("LogoPrimary")
        // Use this universal asset on dark surfaces until a dedicated dark variant exists.
        static let logoOutline = Image("LogoOutline")
    }

    enum Mascot {
        static let neruDefault = Image("NeruDefault")
        static let neruWave = Image("NeruWave")
        static let neruHappy = Image("NeruHappy")
        static let neruCelebrate = Image("NeruCelebrate")
        static let neruThinking = Image("NeruThinking")
        static let neruConfused = Image("NeruConfused")
        static let neruError = Image("NeruError")
        static let neruMinimal = Image("NeruMinimal")
    }
}
