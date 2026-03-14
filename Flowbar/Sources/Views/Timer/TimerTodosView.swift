import SwiftUI

struct TimerTodosView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var timerService: TimerService
    @State private var searchText = ""
    @State private var hideDone = false
    @State private var todos: [TodoItem] = []

    var filteredTodos: [TodoItem] {
        var items = todos
        if hideDone {
            items = items.filter { !$0.isDone }
        }
        if !searchText.isEmpty {
            items = items.filter { $0.text.localizedCaseInsensitiveContains(searchText) }
        }
        return items
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search + filter bar
            HStack(spacing: 8) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search todo", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.ultraThinMaterial)
                )

                Button(action: { hideDone.toggle() }) {
                    Image(systemName: hideDone ? "eye.slash" : "eye")
                        .foregroundStyle(hideDone ? FlowbarColors.accent : .secondary)
                }
                .buttonStyle(.plain)
                .help(hideDone ? "Show completed" : "Hide completed")
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.trailing, 44) // space for the list toggle button

            // Todos list
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(filteredTodos) { todo in
                        TodoRow(todo: todo, timerService: timerService) {
                            toggleTodo(todo)
                        } onStart: {
                            startTimer(for: todo)
                        } onNavigate: {
                            navigateToFile(todo)
                        }
                    }
                }
                .padding(12)
            }
        }
        .onAppear { loadTodos() }
        .onChange(of: appState.noteFiles) { loadTodos() }
        .onChange(of: timerService.isRunning) { loadTodos() }
    }

    private func loadTodos() {
        var allTodos: [TodoItem] = []
        for file in appState.noteFiles {
            let extracted = MarkdownParser.extractTodos(from: file.url, noteFile: file)
            allTodos.append(contentsOf: extracted)
        }
        // Enrich with timer data
        for i in allTodos.indices {
            let total = timerService.totalTime(forTodo: allTodos[i].text, sourceFile: allTodos[i].sourceFile.id)
            allTodos[i].totalSeconds = total
            allTodos[i].isRunning = timerService.isRunning &&
                timerService.currentTodoText == allTodos[i].text &&
                timerService.currentSourceFile == allTodos[i].sourceFile.id
        }
        todos = allTodos
    }

    private func toggleTodo(_ todo: TodoItem) {
        _ = MarkdownParser.toggleTodo(at: todo.lineIndex, in: todo.sourceFile.url)
        loadTodos()
    }

    private func startTimer(for todo: TodoItem) {
        if timerService.isRunning && timerService.currentTodoText == todo.text {
            timerService.stop()
        } else {
            timerService.start(todoText: todo.text, sourceFile: todo.sourceFile.id)
        }
        loadTodos()
    }

    private func navigateToFile(_ todo: TodoItem) {
        appState.showingTimer = false
        appState.selectFile(todo.sourceFile)
    }
}
