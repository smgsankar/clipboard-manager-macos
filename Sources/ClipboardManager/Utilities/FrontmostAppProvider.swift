import AppKit

@MainActor
protocol FrontmostAppProviding: AnyObject {
    var frontmostApplicationName: String? { get }
}

@MainActor
final class FrontmostAppProvider: FrontmostAppProviding {
    var frontmostApplicationName: String? {
        NSWorkspace.shared.frontmostApplication?.localizedName
    }
}
