import SwiftUI

struct TimerTodosView: View {
    @Environment(AppState.self) var appState
    @Environment(TimerService.self) var timerService
    var onToggleView: () -> Void
    var isShowingTodos: Bool
    @State private var searchText = ""
    @State private var showDone = false
    @State private var sourceFilter: String? = nil
    @State private var showSourcePicker = false
    @State private var todos: [TodoItem] = []
    @State private var totalTimes: [String: TimeInterval] = [:]

    private var sourceFiles: [String] {
        Array(Set(todos.map { $0.sourceFile.id })).sorted()
    }

    var filteredTodos: [TodoItem] {
        var items = todos
        if !showDone { items = items.filter { !$0.isDone } }
        if let src = sourceFilter { items = items.filter { $0.sourceFile.id == src } }
        if !searchText.isEmpty {
            items = items.filter { $0.text.localizedCaseInsensitiveContains(searchText) }
        }
        return items
    }

    var body: some View {
        VStack(spacing: 0) {
            // Combined toolbar: search + filters + todo list toggle
            HStack(spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                    TextField("Search", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color.primary.opacity(0.06)))

                Button(action: { showDone.toggle() }) {
                    Image(systemName: showDone ? "checkmark.circle.fill" : "checkmark.circle")
                        .font(.system(size: 13))
                        .foregroundStyle(showDone ? appState.settings.accent : Color.secondary.opacity(0.5))
                }
                .buttonStyle(.plain)
                .help(showDone ? "Hide completed" : "Show completed")

                Menu {
                    Button("All Files") { sourceFilter = nil }
                    Divider()
                    ForEach(sourceFiles, id: \.self) { src in
                        Button(src) { sourceFilter = src }
                    }
                } label: {
                    HStack(spacing: 2) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 12))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 8, weight: .semibold))
                    }
                    .foregroundStyle(sourceFilter != nil ? appState.settings.accent : Color.secondary.opacity(0.5))
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
                .help("Filter by file")

                Button(action: onToggleView) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 13))
                        .padding(6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(isShowingTodos ? appState.settings.accent : Color.primary.opacity(0.06))
                        )
                        .foregroundStyle(isShowingTodos ? .white : .secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.top, 10)
            .padding(.bottom, 6)

            ScrollView {
                LazyVStack(spacing: 1) {
                    ForEach(filteredTodos) { todo in
                        let key = "\(todo.text)|\(todo.sourceFile.id)"
                        TodoRow(
                            todo: todo,
                            totalSeconds: totalTimes[key] ?? 0,
                            timerService: timerService
                        ) {
                            toggleTodo(todo)
                        } onStart: {
                            startTimer(for: todo)
                        } onNavigate: {
                            navigateToFile(todo)
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
            }
        }
        .onAppear { loadTodos() }
        .onChange(of: appState.sidebar.noteFiles) { _, _ in loadTodos() }
        .onChange(of: timerService.isRunning) { _, _ in loadTodos() }
    }

    private func loadTodos() {
        var allTodos: [TodoItem] = []
        for file in appState.sidebar.noteFiles {
            let extracted = MarkdownParser.extractTodos(from: file.url, noteFile: file)
            allTodos.append(contentsOf: extracted)
        }
        totalTimes = timerService.allTotalTimes()
        todos = allTodos
    }

    private func toggleTodo(_ todo: TodoItem) {
        _ = MarkdownParser.toggleTodo(at: todo.lineIndex, in: todo.sourceFile.url)
        loadTodos()
    }

    private func startTimer(for todo: TodoItem) {
        if timerService.isTracking(todoText: todo.text, sourceFile: todo.sourceFile.id) {
            timerService.pause()
        } else {
            timerService.start(todoText: todo.text, sourceFile: todo.sourceFile.id)
        }
    }

    private func navigateToFile(_ todo: TodoItem) {
        appState.selectFile(todo.sourceFile)
    }
}
