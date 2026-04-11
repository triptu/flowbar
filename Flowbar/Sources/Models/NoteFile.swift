import Foundation

/// Represents a single markdown file in the configured folder.
/// Used throughout the app for sidebar listing, note editing, and todo source tracking.
struct NoteFile: Identifiable, Hashable {
    let id: String       // relative path without .md (e.g. "subfolder/note")
    let url: URL         // full file path
    var name: String { url.deletingPathExtension().lastPathComponent }

    init(url: URL) {
        self.url = url
        self.id = url.deletingPathExtension().lastPathComponent
    }

    /// Create with pre-computed root path components (avoids repeated standardizedFileURL calls).
    init(url: URL, rootComponents: [String]) {
        self.url = url
        let fileComponents = url.standardizedFileURL.deletingPathExtension().pathComponents
        if fileComponents.starts(with: rootComponents) {
            self.id = fileComponents.dropFirst(rootComponents.count).joined(separator: "/")
        } else {
            self.id = url.deletingPathExtension().lastPathComponent
        }
    }
}

/// A node in the sidebar tree — either a folder (with children) or a file.
enum SidebarItem: Identifiable {
    case folder(name: String, relativePath: String, children: [SidebarItem])
    case file(NoteFile)

    var id: String {
        switch self {
        case .folder(_, let path, _): return "folder:\(path)"
        case .file(let note): return "file:\(note.id)"
        }
    }

    var name: String {
        switch self {
        case .folder(let name, _, _): return name
        case .file(let note): return note.name
        }
    }
}
