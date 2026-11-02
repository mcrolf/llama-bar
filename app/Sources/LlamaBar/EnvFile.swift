import Foundation

/// A dotenv file edited in place: assignments change, comments and order survive.
struct EnvFile: Equatable {
    private var lines: [String]

    init(text: String) {
        lines = text.components(separatedBy: "\n")
    }

    var text: String { lines.joined(separator: "\n") }

    /// The last assignment wins, as when bash sources the file.
    func value(for key: String) -> String? {
        lines.compactMap(Self.assignment).last { $0.key == key }?.value
    }

    mutating func set(_ key: String, to value: String) {
        let line = "\(key)=\(value)"
        if let index = lines.lastIndex(where: { Self.assignment(in: $0)?.key == key }) {
            lines[index] = line
        } else if lines.last == "" {
            lines.insert(line, at: lines.count - 1)
        } else {
            lines.append(line)
        }
    }

    private static func assignment(in line: String) -> (key: String, value: String)? {
        var trimmed = line.trimmingCharacters(in: .whitespaces)
        guard !trimmed.hasPrefix("#") else { return nil }
        if trimmed.hasPrefix("export ") { trimmed.removeFirst("export ".count) }
        guard let equals = trimmed.firstIndex(of: "=") else { return nil }
        let key = trimmed[..<equals].trimmingCharacters(in: .whitespaces)
        let value = trimmed[trimmed.index(after: equals)...].trimmingCharacters(in: .whitespaces)
        return (key, unquoted(value))
    }

    private static func unquoted(_ value: String) -> String {
        for quote in ["\"", "'"] where value.count >= 2 && value.hasPrefix(quote) && value.hasSuffix(quote) {
            return String(value.dropFirst().dropLast())
        }
        return value
    }
}
