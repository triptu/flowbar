import SwiftUI

/// Spotlight-style search overlay — text field at top, results below.
/// Shown over the main content when ⌘F or ⌘K is pressed.
struct SearchOverlayView: View {
    @Environment(AppState.self) var appState
    @FocusState private var isFocused: Bool

    private var search: SearchState { appState.search }

    var body: some View {
        VStack(spacing: 0) {
            searchField
            if !search.results.isEmpty {
                Divider().opacity(0.3)
                resultsList
            }
        }
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(.ultraThickMaterial)
                .shadow(color: .black.opacity(0.2), radius: 12, y: 4)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
        }
        .frame(maxWidth: 400)
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                isFocused = true
            }
        }
        .accessibilityIdentifier("search-overlay")
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)

            TextField("Search notes…", text: Binding(
                get: { search.query },
                set: { newValue in
                    search.query = newValue
                    search.search()
                }
            ))
            .textFieldStyle(.plain)
            .font(.system(size: 14))
            .focused($isFocused)
            .onKeyPress(.upArrow) { search.moveUp(); return .handled }
            .onKeyPress(.downArrow) { search.moveDown(); return .handled }
            .onKeyPress(.return) { confirmSelection(); return .handled }
            .onKeyPress(.escape) { search.close(); return .handled }
            .accessibilityIdentifier("search-field")

            if !search.query.isEmpty {
                Button(action: { search.query = ""; search.search() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var resultsList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    let results = search.results
                    ForEach(results.indices, id: \.self) { index in
                        resultRow(results[index], isSelected: index == search.selectedIndex)
                            .id(results[index].id)
                            .onTapGesture {
                                search.selectedIndex = index
                                confirmSelection()
                            }
                    }
                }
                .padding(.vertical, 4)
            }
            .frame(maxHeight: 260)
            .onChange(of: search.selectedIndex) { _, newIndex in
                guard search.results.indices.contains(newIndex) else { return }
                proxy.scrollTo(search.results[newIndex].id, anchor: .center)
            }
        }
    }

    @ViewBuilder
    private func resultRow(_ result: SearchResult, isSelected: Bool) -> some View {
        HStack(spacing: 8) {
            switch result {
            case .file(let file):
                Image(systemName: "doc.text")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                    .frame(width: 14)
                Text(file.name)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                Spacer(minLength: 0)

            case .content(let file, _, let lineText):
                let parsed = parseTodoPrefix(lineText)
                Group {
                    if let isDone = parsed.isDone {
                        Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(isDone ? .tertiary : .secondary)
                    } else {
                        Image(systemName: "text.alignleft")
                            .foregroundStyle(.tertiary)
                    }
                }
                .font(.system(size: 12))
                .frame(width: 14)

                highlightedText(parsed.text, query: search.query)
                    .font(.system(size: 13))
                    .lineLimit(1)
                    .layoutPriority(-1)
                Spacer(minLength: 4)
                Text(file.name)
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .layoutPriority(1)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: 6)
                    .fill(appState.settings.accent.opacity(0.15))
                    .padding(.horizontal, 4)
            }
        }
        .contentShape(Rectangle())
    }

    /// Strip markdown todo prefix, returning the clean text and whether it's a checkbox.
    private func parseTodoPrefix(_ text: String) -> (text: String, isDone: Bool?) {
        if text.hasPrefix("- [x] ") { return (String(text.dropFirst(6)), true) }
        if text.hasPrefix("- [ ] ") { return (String(text.dropFirst(6)), false) }
        if text.hasPrefix("- ") { return (String(text.dropFirst(2)), nil) }
        return (text, nil)
    }

    /// Highlight matching portions of text with accent color.
    private func highlightedText(_ text: String, query: String) -> Text {
        guard !query.isEmpty else { return Text(text) }

        let lower = text.lowercased()
        let queryLower = query.lowercased()

        guard let range = lower.range(of: queryLower) else { return Text(text) }

        let before = String(text[text.startIndex..<range.lowerBound])
        let match = String(text[range.lowerBound..<range.upperBound])
        let after = String(text[range.upperBound..<text.endIndex])

        return Text(before) + Text(match).bold().foregroundColor(appState.settings.accent) + Text(after)
    }

    private func confirmSelection() {
        guard let result = search.selectedResult else { return }
        appState.selectFile(result.noteFile)
        search.close()
    }
}
