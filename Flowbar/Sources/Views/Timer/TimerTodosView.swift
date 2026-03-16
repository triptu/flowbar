import SwiftUI

struct TimerTodosView: View {
    @Environment(AppState.self) var appState
    @Environment(TimerService.self) var timerService
    @State private var searchText = ""
    @AppStorage("todoFilter.showDone") private var showDone = false
    @AppStorage("todoFilter.sourceFile") private var sourceFilter: String = ""
    @State private var showSourcePicker = false
    @State private var todos: [TodoItem] = []
    @State private var totalTimes: [String: TimeInterval] = [:]

    private var sourceFiles: [String] {
        Array(Set(todos.map { $0.sourceFile.id })).sorted()
    }

    var filteredTodos: [TodoItem] {
        var items = todos
        if !showDone { items = items.filter { !$0.isDone } }
        if !sourceFilter.isEmpty { items = items.filter { $0.sourceFile.id == sourceFilter } }
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

                Menu {
                    Button("All Files") { sourceFilter = "" }
                    Divider()
                    ForEach(sourceFiles, id: \.self) { src in
                        Button {
                            sourceFilter = src
                        } label: {
                            if sourceFilter == src {
                                Label(src, systemImage: "checkmark")
                            } else {
                                Text(src)
                            }
                        }
                    }
                } label: {
                    toolbarIcon("doc.text", isActive: !sourceFilter.isEmpty)
                }
                .menuIndicator(.hidden)
                .menuStyle(.borderlessButton)
                .fixedSize()
                .help("Filter by file")

                Button(action: { showDone.toggle() }) {
                    toolbarIcon("checkmark", isActive: showDone, weight: .semibold)
                }
                .buttonStyle(.plain)
                .help(showDone ? "Hide completed" : "Show completed")
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
        .onChange(of: timerService.isRunning) { _, _ in refreshTimes() }
    }

    private func loadTodos() {
        var allTodos: [TodoItem] = []
        for file in appState.sidebar.noteFiles {
            let extracted = MarkdownParser.extractTodos(from: file.url, noteFile: file)
            allTodos.append(contentsOf: extracted)
        }
        todos = allTodos
        refreshTimes()
    }

    private func refreshTimes() {
        totalTimes = timerService.allTotalTimes()
    }

    private func toggleTodo(_ todo: TodoItem) {
        timerService.toggleTodo(todo)
        loadTodos()
    }

    private func startTimer(for todo: TodoItem) {
        timerService.startTodo(todo)
        loadTodos()
    }

    private func toolbarIcon(_ systemName: String, isActive: Bool, weight: Font.Weight = .regular) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 11, weight: weight))
            .foregroundStyle(isActive ? .primary : .secondary)
            .frame(width: 26, height: 26)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isActive ? appState.settings.accent : Color.primary.opacity(0.06))
            )
    }

    private func navigateToFile(_ todo: TodoItem) {
        appState.selectFile(todo.sourceFile)
    }
}
