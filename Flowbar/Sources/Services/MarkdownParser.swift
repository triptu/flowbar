import Foundation

/// A parsed markdown block for rendering in the preview.
enum MarkdownBlock: Equatable {
    case heading(level: Int, text: String)
    case todo(isDone: Bool, text: String, lineIndex: Int, indent: Int)
    case bullet(text: String, indent: Int)
    case numbered(number: Int, text: String, indent: Int)
    case codeBlock(String)
    case blockquote(String)
    case horizontalRule
    case paragraph(String)
    case empty
}

/// Reads and writes markdown files to extract/toggle todos.
///
/// Also parses markdown into blocks for preview rendering.
/// All methods are static — no instance state.
/// Uses "\n" splitting consistently to match how files are written back.
enum MarkdownParser {

    // MARK: - Block parsing

    static func parseBlocks(from content: String) -> [MarkdownBlock] {
        let lines = content.components(separatedBy: "\n")
        var blocks: [MarkdownBlock] = []
        var inCodeBlock = false
        var codeLines: [String] = []

        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Code fence toggle
            if trimmed.hasPrefix("```") {
                if inCodeBlock {
                    blocks.append(.codeBlock(codeLines.joined(separator: "\n")))
                    codeLines = []
                }
                inCodeBlock.toggle()
                continue
            }
            if inCodeBlock {
                codeLines.append(line)
                continue
            }

            let indent = line.prefix(while: { $0 == " " || $0 == "\t" }).count

            if trimmed.isEmpty {
                blocks.append(.empty)
            } else if let (level, text) = parseHeading(trimmed) {
                blocks.append(.heading(level: level, text: text))
            } else if trimmed.hasPrefix("- [ ] ") {
                blocks.append(.todo(isDone: false, text: String(trimmed.dropFirst(6)), lineIndex: index, indent: indent))
            } else if trimmed.hasPrefix("- [x] ") || trimmed.hasPrefix("- [X] ") {
                blocks.append(.todo(isDone: true, text: String(trimmed.dropFirst(6)), lineIndex: index, indent: indent))
            } else if isHorizontalRule(trimmed) {
                blocks.append(.horizontalRule)
            } else if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
                blocks.append(.bullet(text: String(trimmed.dropFirst(2)), indent: indent))
            } else if let (num, text) = parseNumberedList(trimmed) {
                blocks.append(.numbered(number: num, text: text, indent: indent))
            } else if trimmed.hasPrefix("> ") {
                blocks.append(.blockquote(String(trimmed.dropFirst(2))))
            } else {
                blocks.append(.paragraph(trimmed))
            }
        }

        // Close unclosed code block
        if inCodeBlock && !codeLines.isEmpty {
            blocks.append(.codeBlock(codeLines.joined(separator: "\n")))
        }

        return blocks
    }

    private static func parseHeading(_ line: String) -> (Int, String)? {
        let hashes = line.prefix(while: { $0 == "#" })
        let level = hashes.count
        guard level >= 1, level <= 6, line.dropFirst(level).hasPrefix(" ") else { return nil }
        return (level, String(line.dropFirst(level + 1)))
    }

    private static func parseNumberedList(_ line: String) -> (Int, String)? {
        guard let dotIndex = line.firstIndex(of: ".") else { return nil }
        let numStr = String(line[line.startIndex..<dotIndex])
        guard let num = Int(numStr),
              line.index(after: dotIndex) < line.endIndex,
              line[line.index(after: dotIndex)...].hasPrefix(" ") else { return nil }
        let textStart = line.index(dotIndex, offsetBy: 2)
        return (num, String(line[textStart...]))
    }

    private static func isHorizontalRule(_ line: String) -> Bool {
        let stripped = line.filter { $0 != " " }
        return stripped.count >= 3 && stripped.allSatisfy({ $0 == "-" || $0 == "*" || $0 == "_" })
            && Set(stripped).count == 1
    }

    // MARK: - Line-level todo toggle

    /// Toggles a single line between `- [ ]` and `- [x]`. Returns the toggled line, or nil if not a todo.
    static func toggleTodoLine(_ line: String) -> String? {
        if line.contains("- [ ] ") {
            return line.replacingOccurrences(of: "- [ ] ", with: "- [x] ")
        } else if line.contains("- [x] ") || line.contains("- [X] ") {
            return line.replacingOccurrences(of: "- [x] ", with: "- [ ] ")
                .replacingOccurrences(of: "- [X] ", with: "- [ ] ")
        }
        return nil
    }

    // MARK: - Todo extraction
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
        guard lineIndex < lines.count,
              let toggled = toggleTodoLine(lines[lineIndex]) else { return false }
        lines[lineIndex] = toggled
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
