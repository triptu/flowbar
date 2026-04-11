import SwiftUI

// Chevron width + gap — used for consistent text alignment between folders and files.
// Files indent by this amount so their text aligns with folder text after the chevron.
// Children indent by this amount so their content starts where parent text starts.
private let chevronIndent: CGFloat = 16

struct SidebarView: View {
    @Environment(AppState.self) var appState

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(appState.sidebar.sidebarItems) { item in
                        SidebarItemView(item: item)
                    }
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
            }
            .contextMenu {
                Button("New File") { appState.createNewFile() }
                Button("New Folder") { appState.createNewFolder() }
            }
            .overlay {
                if appState.sidebar.sidebarItems.isEmpty {
                    VStack(spacing: 8) {
                        Text("No files yet")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.secondary)
                        Text("Right-click to create one")
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }

            Spacer()
            SidebarFooter()
        }
        .frame(maxHeight: .infinity)
        .background(FlowbarColors.sidebarBg)
    }
}

// MARK: - SidebarItemView (dispatches folder vs file)

struct SidebarItemView: View {
    @Environment(AppState.self) var appState
    let item: SidebarItem

    var body: some View {
        switch item {
        case .folder(let name, let relativePath, let children):
            SidebarFolderRow(name: name, relativePath: relativePath, children: children)
        case .file(let file):
            SidebarFileRow(
                file: file,
                isSelected: appState.sidebar.selectedFile?.id == file.id,
                isRenaming: appState.sidebar.renamingFileID == file.id
            )
            .padding(.leading, chevronIndent)
            .onTapGesture {
                guard appState.sidebar.renamingFileID != file.id else { return }
                appState.selectFile(file)
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("sidebar-row-\(file.id)")
            .contextMenu {
                let parentFolder = file.id.contains("/") ? String(file.id[..<file.id.lastIndex(of: "/")!]) : nil
                Button("New File") { appState.createNewFile(inFolder: parentFolder) }
                Button("New Folder") { appState.createNewFolder(inFolder: parentFolder) }
                Divider()
                Button("Reveal in Finder") { appState.revealInFinder(file) }
                Button("Open in Obsidian") { appState.openInObsidian(file) }
                Divider()
                Button("Rename") { appState.startRename(file) }
                Divider()
                Button("Move to Trash", role: .destructive) { appState.trashFile(file) }
            }
        }
    }
}

// MARK: - SidebarFolderRow

struct SidebarFolderRow: View {
    @Environment(AppState.self) var appState
    let name: String
    let relativePath: String
    let children: [SidebarItem]

    private var isExpanded: Bool {
        appState.sidebar.expandedFolders.contains(relativePath)
    }

    private var isRenaming: Bool {
        appState.sidebar.renamingFolderPath == relativePath
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.tertiary)
                    .frame(width: chevronIndent - 6, alignment: .trailing)
                if isRenaming {
                    RenameField(
                        initialText: appState.sidebar.renameText,
                        accentColor: appState.settings.accentColor.nsColor,
                        fontSize: appState.settings.typography.sidebarSize,
                        onCommit: { text in
                            appState.sidebar.renameText = text
                            appState.commitFolderRename()
                        },
                        onCancel: {
                            appState.cancelRename()
                        }
                    )
                    .id(appState.sidebar.renameSessionID)
                } else {
                    Text(name)
                        .font(.system(size: appState.settings.typography.sidebarSize))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
            .onTapGesture {
                guard !isRenaming else { return }
                withAnimation(.easeInOut(duration: 0.15)) {
                    appState.sidebar.toggleFolder(relativePath)
                }
            }
            .accessibilityIdentifier("sidebar-folder-\(relativePath)")
            .contextMenu {
                Button("New File") { appState.createNewFile(inFolder: relativePath) }
                Button("New Folder") { appState.createNewFolder(inFolder: relativePath) }
                Divider()
                Button("Reveal in Finder") {
                    appState.revealFolderInFinder(relativePath: relativePath)
                }
                Divider()
                Button("Rename") { appState.startFolderRename(relativePath) }
                Divider()
                Button("Move to Trash", role: .destructive) {
                    appState.trashFolder(relativePath: relativePath)
                }
            }

            if isExpanded {
                ForEach(children) { child in
                    SidebarItemView(item: child)
                        .padding(.leading, chevronIndent)
                }
            }
        }
    }
}

/// A single file row — plain text normally, inline NSTextField when renaming.
struct SidebarFileRow: View {
    @Environment(AppState.self) var appState
    let file: NoteFile
    let isSelected: Bool
    let isRenaming: Bool

    var body: some View {
        Group {
            if isRenaming {
                RenameField(
                    initialText: appState.sidebar.renameText,
                    accentColor: appState.settings.accentColor.nsColor,
                    fontSize: appState.settings.typography.sidebarSize,
                    onCommit: { text in
                        appState.sidebar.renameText = text
                        appState.commitRename()
                    },
                    onCancel: {
                        appState.cancelRename()
                    }
                )
                // Force a fresh NSTextField per rename session so the coordinator
                // (finished flag, click-outside monitor) always starts clean.
                .id(appState.sidebar.renameSessionID)
            } else {
                Text(file.name)
                    .font(.system(size: appState.settings.typography.sidebarSize))
                    .foregroundStyle(isSelected ? .primary : .secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? appState.settings.accent.opacity(0.2) : Color.clear)
        )
        .contentShape(Rectangle())
    }
}

// MARK: - RenameField (NSViewRepresentable)
//
// Design: ONE dismiss path. Every exit (Enter, Escape, click-outside, Tab)
// funnels through `finish()`. The click-outside monitor just resigns first
// responder -> controlTextDidEndEditing -> finish(). No racing dismiss paths.

struct RenameField: NSViewRepresentable {
    let initialText: String
    let accentColor: NSColor
    let fontSize: CGFloat
    let onCommit: (String) -> Void
    let onCancel: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onCommit: onCommit, onCancel: onCancel)
    }

    func makeNSView(context: Context) -> NSTextField {
        let field = NSTextField()
        field.font = .systemFont(ofSize: fontSize)
        field.stringValue = initialText
        field.delegate = context.coordinator
        field.isBordered = false
        field.focusRingType = .none
        field.drawsBackground = true
        field.backgroundColor = .textBackgroundColor
        field.wantsLayer = true
        field.layer?.cornerRadius = 4
        field.layer?.borderWidth = 1.5
        field.layer?.borderColor = accentColor.cgColor
        field.setAccessibilityIdentifier("rename-field")

        // Delay focus until the field is in the window hierarchy.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak field] in
            guard let field, let window = field.window else { return }
            window.makeKey()
            window.makeFirstResponder(field)
            field.currentEditor()?.selectAll(nil)
            context.coordinator.installClickOutsideMonitor(for: field)
        }
        return field
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {}

    // MARK: - Coordinator

    final class Coordinator: NSObject, NSTextFieldDelegate {
        private let onCommit: (String) -> Void
        private let onCancel: () -> Void
        /// NSEvent monitor handle (not Sendable). Only accessed on @MainActor.
        private nonisolated(unsafe) var monitor: Any?
        private var finished = false

        init(onCommit: @escaping (String) -> Void, onCancel: @escaping () -> Void) {
            self.onCommit = onCommit
            self.onCancel = onCancel
        }

        @MainActor func installClickOutsideMonitor(for field: NSTextField) {
            monitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) {
                [weak self, weak field] event in
                guard let self, let field, !self.finished else { return event }
                if event.window === field.window {
                    let pt = field.convert(event.locationInWindow, from: nil)
                    if !field.bounds.contains(pt) {
                        field.window?.makeFirstResponder(nil)
                    }
                } else {
                    field.window?.makeFirstResponder(nil)
                }
                return event
            }
        }

        // MARK: NSTextFieldDelegate

        /// Intercept Enter and Escape so they don't propagate to the NSPanel.
        func control(_ control: NSControl, textView: NSTextView, doCommandBy sel: Selector) -> Bool {
            if sel == #selector(NSResponder.insertNewline(_:)) {
                finish((control as? NSTextField)?.stringValue ?? "", isCancel: false)
                return true
            }
            if sel == #selector(NSResponder.cancelOperation(_:)) {
                finish("", isCancel: true)
                return true
            }
            return false
        }

        /// Fires when the field loses first responder (click-outside, Tab, etc.).
        func controlTextDidEndEditing(_ obj: Notification) {
            guard let field = obj.object as? NSTextField else { return }
            finish(field.stringValue, isCancel: false)
        }

        // MARK: Single exit point

        private func finish(_ text: String, isCancel: Bool) {
            guard !finished else { return }
            finished = true
            removeMonitor()
            isCancel ? onCancel() : onCommit(text)
        }

        private func removeMonitor() {
            if let monitor { NSEvent.removeMonitor(monitor) }
            monitor = nil
        }

        deinit { removeMonitor() }
    }
}
