import Foundation

/// Represents a single markdown file in the configured folder.
/// Used throughout the app for sidebar listing, note editing, and todo source tracking.
struct NoteFile: Identifiable, Hashable {
    let id: String       // filename without .md extension
    let url: URL         // full file path
    let name: String     // display name ("daily-journal" → "Daily Journal")

    init(url: URL) {
        self.url = url
        self.id = url.deletingPathExtension().lastPathComponent
        self.name = Self.formatName(self.id)
    }

    static func formatName(_ id: String) -> String {
        id.split(separator: "-")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }
}
