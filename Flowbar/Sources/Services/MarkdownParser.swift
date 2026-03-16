import Foundation

/// Reads and writes markdown files to extract/toggle todos.
///
/// Used by TimerTodosView to build the todo list and by TimerService callers to mark
/// todos done on completion. All methods are static — no instance state.
/// Uses "\n" splitting consistently to match how files are written back.
enum MarkdownParser {
    static func extractTodos(from url: URL, noteFile: NoteFile) -> [TodoItem] {
        guard let content = try? String(contentsOf: url, encoding: .utf8) else { return [] }
        let lines = content.components(separatedBy: "\n")
        var todos: [TodoItem] = []

        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("- [ ] ") {
                let text = String(trimmed.dropFirst(6))
                todos.append(TodoItem(text: text, isDone: false, sourceFile: noteFile, lineIndex: index))
            } else if trimmed.hasPrefix("- [x] ") || trimmed.hasPrefix("- [X] ") {
                let text = String(trimmed.dropFirst(6))
                todos.append(TodoItem(text: text, isDone: true, sourceFile: noteFile, lineIndex: index))
            }
        }
        return todos
    }

    static func toggleTodo(at lineIndex: Int, in url: URL) -> Bool {
        guard var content = try? String(contentsOf: url, encoding: .utf8) else { return false }
        var lines = content.components(separatedBy: "\n")
        guard lineIndex < lines.count else { return false }

        let line = lines[lineIndex]
        if line.contains("- [ ] ") {
            lines[lineIndex] = line.replacingOccurrences(of: "- [ ] ", with: "- [x] ")
        } else if line.contains("- [x] ") || line.contains("- [X] ") {
            lines[lineIndex] = line.replacingOccurrences(of: "- [x] ", with: "- [ ] ")
                .replacingOccurrences(of: "- [X] ", with: "- [ ] ")
        } else {
            return false
        }

        content = lines.joined(separator: "\n")
        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
            return true
        } catch {
            return false
        }
    }

    /// Toggle a todo at the given line index, but only if the line is still `- [ ] <text>`.
    /// Returns true if the toggle happened. Single file read+write (no double I/O).
    static func toggleTodoIfMatches(text: String, at lineIndex: Int, in url: URL) -> Bool {
        guard var content = try? String(contentsOf: url, encoding: .utf8) else { return false }
        var lines = content.components(separatedBy: "\n")
        guard lineIndex < lines.count else { return false }
        let trimmed = lines[lineIndex].trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("- [ ] ") && String(trimmed.dropFirst(6)) == text else { return false }
        lines[lineIndex] = lines[lineIndex].replacingOccurrences(of: "- [ ] ", with: "- [x] ")
        content = lines.joined(separator: "\n")
        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
            return true
        } catch {
            return false
        }
    }

    /// Find a specific incomplete todo by text and mark it done. Single read+write.
    static func markTodoDone(text: String, in url: URL) {
        guard var content = try? String(contentsOf: url, encoding: .utf8) else { return }
        var lines = content.components(separatedBy: "\n")
        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("- [ ] ") && String(trimmed.dropFirst(6)) == text {
                lines[index] = line.replacingOccurrences(of: "- [ ] ", with: "- [x] ")
                content = lines.joined(separator: "\n")
                try? content.write(to: url, atomically: true, encoding: .utf8)
                return
            }
        }
    }
}
