import Foundation

extension Int64 {
    var byteCount: String { formatted(.byteCount(style: .file)) }
}

extension Int {
    /// 1234567 -> "1.2M"
    var compactCount: String { formatted(.number.notation(.compactName).precision(.fractionLength(0...1))) }
}
