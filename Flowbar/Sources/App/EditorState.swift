import SwiftUI
import Observation

/// Manages the active file's text content, debounced saving, and file watchers.
///
/// Watches the currently-open file for external edits (e.g. from Obsidian).
/// An `isWriting` flag prevents the watcher from reloading content we just saved.
/// Also owns the directory watcher that refreshes the file list when files change on disk.
@Observable
@MainActor
final class EditorState {
    var editorContent: String = ""

    @ObservationIgnored private var saveTask: DispatchWorkItem?
    @ObservationIgnored private var isWriting = false
    @ObservationIgnored private var dirWatcher: FileWatcher?
    @ObservationIgnored private var dirWatcherURL: URL?
    /// When > 0, directory watcher events are suppressed to avoid double-reload after explicit mutations.
    @ObservationIgnored private var dirWatcherSuppressCount = 0
    @ObservationIgnored private var fileWatcher: FileWatcher?
    /// Stored so saveFileContent can re-arm the watcher with the same callback
    @ObservationIgnored private var externalChangeHandler: (() -> Void)?

    func loadFileContent(_ file: NoteFile) {
        saveTask?.cancel()
        saveTask = nil
        isWriting = false

        if let content = try? String(contentsOf: file.url, encoding: .utf8) {
            editorContent = content
        }
    }

    func saveFileContent(for file: NoteFile?) {
        guard let file else { return }
        saveTask?.cancel()
        isWriting = true
        let contentToSave = editorContent
        let task = DispatchWorkItem { [weak self] in
            guard let self else { return }
            // Write on a background queue to avoid blocking the main thread
            DispatchQueue.global(qos: .utility).async { [weak self] in
                try? contentToSave.write(to: file.url, atomically: true, encoding: .utf8)
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    // Atomic write creates a new inode — re-establish watcher, preserving the handler
                    self.rearmFileWatcher(file)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                        self?.isWriting = false
                    }
                }
            }
        }
        saveTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: task)
    }

    /// Watch the currently-selected file for external changes.
    func watchFile(_ file: NoteFile, onExternalChange: @escaping () -> Void) {
        externalChangeHandler = onExternalChange
        rearmFileWatcher(file)
    }

    private func rearmFileWatcher(_ file: NoteFile) {
        let handler = externalChangeHandler
        fileWatcher = FileWatcher(url: file.url) { [weak self] in
            Task { @MainActor in
                guard let self, !self.isWriting else { return }
                handler?()
            }
        }
    }

    /// Suppress the next N directory watcher events to avoid double-reload
    /// after an explicit mutation (create, rename, trash) followed by loadFiles().
    func suppressNextDirectoryEvent() {
        dirWatcherSuppressCount += 1
    }

    /// Watch the notes folder for file additions/removals.
    /// Re-creates the watcher if the URL changes.
    func watchDirectory(at url: URL, onDirectoryChange: @escaping () -> Void) {
        guard dirWatcherURL != url else { return }
        dirWatcherURL = url
        dirWatcher = FileWatcher(url: url) { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                if self.dirWatcherSuppressCount > 0 {
                    self.dirWatcherSuppressCount -= 1
                    return
                }
                onDirectoryChange()
            }
        }
    }
}
