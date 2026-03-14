import Foundation

/// Watches a single file or directory for filesystem changes using GCD dispatch sources.
///
/// Used by AppState to watch the notes directory (for new/deleted files) and the
/// currently selected file (for external edits, e.g. from Obsidian). Each watcher
/// opens a file descriptor and fires the onChange callback on the main queue.
/// Automatically cleans up the descriptor on deinit.
@MainActor
final class FileWatcher {
    private var source: DispatchSourceFileSystemObject?
    private var fileDescriptor: Int32 = -1
    private let onChange: @MainActor () -> Void

    init(url: URL, onChange: @escaping @MainActor () -> Void) {
        self.onChange = onChange
        startWatching(url: url)
    }

    deinit {
        source?.cancel()
    }

    func startWatching(url: URL) {
        stopWatching()
        fileDescriptor = open(url.path, O_EVTONLY)
        guard fileDescriptor >= 0 else { return }

        source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .rename, .delete, .attrib],
            queue: .main
        )
        source?.setEventHandler { [weak self] in
            self?.onChange()
        }
        source?.setCancelHandler { [weak self] in
            if let fd = self?.fileDescriptor, fd >= 0 {
                close(fd)
            }
        }
        source?.resume()
    }

    func stopWatching() {
        source?.cancel()
        source = nil
        fileDescriptor = -1
    }
}
