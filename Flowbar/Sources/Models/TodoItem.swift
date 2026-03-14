import Foundation

struct TodoItem: Identifiable {
    let id: String // hash of text + source
    let text: String
    let isDone: Bool
    let sourceFile: NoteFile
    let lineIndex: Int // line number in the file

    // Timer state (populated from DB)
    var totalSeconds: TimeInterval = 0
    var isRunning: Bool = false

    init(text: String, isDone: Bool, sourceFile: NoteFile, lineIndex: Int) {
        self.text = text
        self.isDone = isDone
        self.sourceFile = sourceFile
        self.lineIndex = lineIndex
        self.id = "\(sourceFile.id):\(lineIndex):\(text)"
    }
}
