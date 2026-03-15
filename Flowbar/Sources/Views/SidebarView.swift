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
                    ForEach(appState.noteFiles) { file in
                        SidebarFileRow(
                            file: file,
                            isSelected: appState.selectedFile?.id == file.id,
                            isRenaming: appState.renamingFileID == file.id
                        )
                        .onTapGesture {
                            if appState.renamingFileID == nil {
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
                                appState.renamingFileID = file.id
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
                    text: file.name,
                    fontSize: appState.typography.sidebarSize,
                    onCommit: { newName in appState.renameFile(file, to: newName) },
                    onCancel: { appState.renamingFileID = nil }
                )
            } else {
                Text(file.name)
                    .font(.system(size: appState.typography.sidebarSize))
                    .foregroundStyle(isSelected ? .white : .secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? FlowbarColors.accent.opacity(0.4) : Color.clear)
        )
        .contentShape(Rectangle())
    }
}

// MARK: - Inline rename field backed by NSTextField for reliable focus, select-all, and click-outside

/// An NSTextField wrapper that auto-focuses, selects all text, and commits on Enter or click-outside.
struct RenameTextField: NSViewRepresentable {
    let text: String
    let fontSize: CGFloat
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
        field.layer?.borderColor = NSColor(FlowbarColors.accent).cgColor
        field.stringValue = text
        field.delegate = context.coordinator
        // Auto-focus and select all text
        DispatchQueue.main.async {
            field.window?.makeFirstResponder(field)
            field.currentEditor()?.selectAll(nil)
        }
        // Delay click-outside monitoring so leftover context menu events don't trigger it
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak field] in
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
        private var didCommit = false

        /// NSTextMovement value for Escape key / cancel operation
        private static let cancelMovement = 23

        init(onCommit: @escaping (String) -> Void, onCancel: @escaping () -> Void) {
            self.onCommit = onCommit
            self.onCancel = onCancel
            super.init()
        }

        /// Install click-outside monitor once the field is live
        @MainActor func startMonitoring(field: NSTextField) {
            monitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { [weak self, weak field] event in
                guard let self, let field, !self.didCommit else { return event }
                let locationInField = field.convert(event.locationInWindow, from: nil)
                if !field.bounds.contains(locationInField) {
                    self.commit(field.stringValue)
                }
                return event
            }
        }

        private func commit(_ value: String) {
            guard !didCommit else { return }
            didCommit = true
            removeMonitor()
            if value.trimmingCharacters(in: .whitespaces).isEmpty {
                onCancel()
            } else {
                onCommit(value)
            }
        }

        func controlTextDidEndEditing(_ obj: Notification) {
            guard !didCommit else { return }
            guard let field = obj.object as? NSTextField else { return }
            if let movement = obj.userInfo?["NSTextMovement"] as? Int, movement == Self.cancelMovement {
                didCommit = true
                removeMonitor()
                onCancel()
            } else {
                commit(field.stringValue)
            }
        }

        private func removeMonitor() {
            if let monitor {
                NSEvent.removeMonitor(monitor)
            }
            monitor = nil
        }

        deinit {
            if let monitor {
                NSEvent.removeMonitor(monitor)
            }
        }
    }
}
