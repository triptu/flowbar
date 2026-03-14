import Foundation

/// A single todo item extracted from a markdown file.
/// The model is intentionally immutable — runtime state like "is this todo's timer running"
/// is computed at the view level from TimerService, not baked into the model.
struct TodoItem: Identifiable {
    let id: String
    let text: String
    let isDone: Bool
    let sourceFile: NoteFile
    let lineIndex: Int

    init(text: String, isDone: Bool, sourceFile: NoteFile, lineIndex: Int) {
        self.text = text
        self.isDone = isDone
        self.sourceFile = sourceFile
        self.lineIndex = lineIndex
        self.id = "\(sourceFile.id):\(lineIndex):\(text)"
    }
}
