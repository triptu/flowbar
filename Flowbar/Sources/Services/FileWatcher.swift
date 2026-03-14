import Foundation
import Combine

final class FileWatcher: ObservableObject {
    private var source: DispatchSourceFileSystemObject?
    private var fileDescriptor: Int32 = -1
    private let onChange: () -> Void

    init(url: URL, onChange: @escaping () -> Void) {
        self.onChange = onChange
        startWatching(url: url)
    }

    deinit {
        stopWatching()
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
