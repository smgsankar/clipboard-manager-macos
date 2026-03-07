import Foundation

struct ClipboardItem: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: UUID
    let content: String
    let timestamp: Date
    let sourceApplication: String?
}
