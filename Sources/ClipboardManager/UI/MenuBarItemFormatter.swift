import Foundation

enum MenuBarItemFormatter {
    static func preview(for content: String, maxLength: Int = 80) -> String {
        let flattened = content
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard flattened.count > maxLength else {
            return flattened
        }

        let index = flattened.index(flattened.startIndex, offsetBy: maxLength)
        return "\(flattened[..<index])…"
    }
}
