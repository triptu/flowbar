import SwiftUI

struct SidebarView: View {
    @Environment(AppState.self) var appState

    var body: some View {
        VStack(spacing: 0) {
            // Header bar — sits right of traffic lights
            HStack(spacing: 8) {
                SidebarToggleButton { appState.toggleSidebar() }
                Spacer()
            }
            .padding(.leading, FloatingPanel.trafficLightWidth)
            .padding(.trailing, 20)
            .padding(.top, 10)
            .padding(.bottom, 10)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(appState.sidebar.noteFiles) { file in
                        SidebarFileRow(
                            file: file,
                            isSelected: appState.sidebar.selectedFile?.id == file.id,
                            isRenaming: appState.sidebar.renamingFileID == file.id
                        )
                        .onTapGesture(count: 2) {
                            appState.startRename(file)
                        }
                        .onTapGesture {
                            // If renaming a different file, commit that rename first
                            if let renaming = appState.sidebar.renamingFileID, renaming != file.id {
                                appState.commitRename()
                            }
                            // Skip select while this row is in rename mode
                            if appState.sidebar.renamingFileID != file.id {
                                appState.selectFile(file)
                            }
                        }
                        .contextMenu {
                            Button("New File") {
                                appState.createNewFile()
                            }
                            Divider()
                            Button("Reveal in Finder") {
                                appState.revealInFinder(file)
                            }
                            Button("Open in Obsidian") {
                                appState.openInObsidian(file)
                            }
                            Divider()
                            Button("Rename") {
                                appState.startRename(file)
                            }
                            Divider()
                            Button("Move to Trash", role: .destructive) {
                                appState.trashFile(file)
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
            }

            Spacer()
            SidebarFooter()
        }
        .frame(maxHeight: .infinity)
        .ignoresSafeArea(.all, edges: .top)
        .background(FlowbarColors.sidebarBg)
    }
}

/// A single file row in the sidebar — shows display name, or an inline text field when renaming.
struct SidebarFileRow: View {
    @Environment(AppState.self) var appState
    let file: NoteFile
    let isSelected: Bool
    let isRenaming: Bool

    var body: some View {
        Group {
            if isRenaming {
                RenameTextField(
                    text: appState.sidebar.renameText,
                    fontSize: appState.settings.typography.sidebarSize,
                    accentColor: appState.settings.accentColor.nsColor,
                    onCommit: { newName in
                        appState.sidebar.renameText = newName
                        appState.commitRename()
                    },
                    onCancel: { appState.cancelRename() }
                )
            } else {
                Text(file.name)
                    .font(.system(size: appState.settings.typography.sidebarSize))
                    .foregroundStyle(isSelected ? .white : .secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? appState.settings.accent.opacity(0.4) : Color.clear)
        )
        .contentShape(Rectangle())
    }
}

// MARK: - NSTextField wrapper for inline rename

/// Uses AppKit NSTextField for reliable focus, blinking cursor, Enter/Escape,
/// and click-outside detection in the floating panel.
struct RenameTextField: NSViewRepresentable {
    let text: String
    let fontSize: CGFloat
    let accentColor: NSColor
    let onCommit: (String) -> Void
    let onCancel: () -> Void

    func makeNSView(context: Context) -> NSTextField {
        let field = NSTextField()
        field.font = .systemFont(ofSize: fontSize)
        field.isBordered = false
        field.focusRingType = .none
        field.drawsBackground = true
        field.backgroundColor = .textBackgroundColor
        field.wantsLayer = true
        field.layer?.cornerRadius = 4
        field.layer?.borderWidth = 1.5
        field.layer?.borderColor = accentColor.cgColor
        field.stringValue = text
        field.delegate = context.coordinator

        // Make panel key and focus the field
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak field] in
            guard let field, let window = field.window else { return }
            window.makeKey()
            window.makeFirstResponder(field)
            field.currentEditor()?.selectAll(nil)
        }
        // Delay click-outside monitor so the context menu dismiss click doesn't leak through
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak field] in
            guard let field else { return }
            context.coordinator.startMonitoring(field: field)
        }
        return field
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCommit: onCommit, onCancel: onCancel)
    }

    class Coordinator: NSObject, NSTextFieldDelegate {
        let onCommit: (String) -> Void
        let onCancel: () -> Void
        private nonisolated(unsafe) var monitor: Any?
        private var didFinish = false

        init(onCommit: @escaping (String) -> Void, onCancel: @escaping () -> Void) {
            self.onCommit = onCommit
            self.onCancel = onCancel
            super.init()
        }

        @MainActor func startMonitoring(field: NSTextField) {
            monitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) {
                [weak self, weak field] event in
                guard let self, let field, !self.didFinish else { return event }
                let locationInField = field.convert(event.locationInWindow, from: nil)
                if !field.bounds.contains(locationInField) {
                    self.finish(field.stringValue, isCancel: false)
                }
                return event
            }
        }

        /// Intercept Enter and Escape to prevent them propagating to the panel
        func control(_ control: NSControl, textView: NSTextView, doCommandBy sel: Selector) -> Bool {
            if sel == #selector(NSResponder.insertNewline(_:)) {
                finish((control as? NSTextField)?.stringValue ?? "", isCancel: false)
                return true
            }
            if sel == #selector(NSResponder.cancelOperation(_:)) {
                finish((control as? NSTextField)?.stringValue ?? "", isCancel: true)
                return true
            }
            return false
        }

        /// Fallback for focus loss via Tab or other reasons
        func controlTextDidEndEditing(_ obj: Notification) {
            guard !didFinish, let field = obj.object as? NSTextField else { return }
            finish(field.stringValue, isCancel: false)
        }

        private func finish(_ value: String, isCancel: Bool) {
            guard !didFinish else { return }
            didFinish = true
            removeMonitor()
            if isCancel {
                onCancel()
            } else {
                onCommit(value)
            }
        }

        private func removeMonitor() {
            if let monitor { NSEvent.removeMonitor(monitor) }
            monitor = nil
        }

        deinit {
            if let monitor { NSEvent.removeMonitor(monitor) }
        }
    }
}
