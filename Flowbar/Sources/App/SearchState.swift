import SwiftUI
import Observation

/// Result from searching notes — either a filename match or a content line match.
enum SearchResult: Identifiable {
    case file(NoteFile)
    case content(NoteFile, lineIndex: Int, lineText: String)

    var id: String {
        switch self {
        case .file(let f): return "file:\(f.id)"
        case .content(let f, let line, _): return "content:\(f.id):\(line)"
        }
    }

    var noteFile: NoteFile {
        switch self {
        case .file(let f): return f
        case .content(let f, _, _): return f
        }
    }

    var isFileMatch: Bool {
        if case .file = self { return true }
        return false
    }
}

/// State for the unified search bar (⌘F / ⌘K).
///
/// Caches file contents on open to avoid disk I/O per keystroke.
/// Results: filename matches first, then content matches (capped at 50).
@Observable
@MainActor
final class SearchState {
    var isOpen = false
    var query = ""
    var results: [SearchResult] = []
    var selectedIndex = 0

    /// Cached file contents, loaded once when search opens.
    @ObservationIgnored private var fileCache: [(file: NoteFile, content: String)] = []

    func open(files: [NoteFile]) {
        isOpen = true
        reset()
        fileCache = files.compactMap { file in
            guard let content = try? String(contentsOf: file.url, encoding: .utf8) else { return nil }
            return (file, content)
        }
    }

    func close() {
        isOpen = false
        reset()
        fileCache = []
    }

    func toggle(files: [NoteFile]) {
        if isOpen { close() } else { open(files: files) }
    }

    private func reset() {
        query = ""
        results = []
        selectedIndex = 0
    }

    /// Search cached file contents by filename and content.
    func search() {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else {
            results = []
            selectedIndex = 0
            return
        }

        var fileMatches: [SearchResult] = []
        var contentMatches: [SearchResult] = []
        let maxContentMatches = 50

        for (file, content) in fileCache {
            if file.name.localizedCaseInsensitiveContains(q) {
                fileMatches.append(.file(file))
            }

            let lines = content.components(separatedBy: "\n")
            for (index, line) in lines.enumerated() {
                guard contentMatches.count < maxContentMatches else { break }
                guard line.localizedCaseInsensitiveContains(q) else { continue }
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty else { continue }
                contentMatches.append(.content(file, lineIndex: index, lineText: trimmed))
            }
        }

        results = fileMatches + contentMatches
        selectedIndex = 0
    }

    func moveUp() {
        guard !results.isEmpty else { return }
        selectedIndex = (selectedIndex - 1 + results.count) % results.count
    }

    func moveDown() {
        guard !results.isEmpty else { return }
        selectedIndex = (selectedIndex + 1) % results.count
    }

    var selectedResult: SearchResult? {
        guard results.indices.contains(selectedIndex) else { return nil }
        return results[selectedIndex]
    }
}
