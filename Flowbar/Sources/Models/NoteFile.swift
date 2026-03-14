import Foundation

struct NoteFile: Identifiable, Hashable {
    let id: String // filename without extension
    let url: URL

    var name: String {
        id.split(separator: "-")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }

    init(url: URL) {
        self.url = url
        self.id = url.deletingPathExtension().lastPathComponent
    }
}
