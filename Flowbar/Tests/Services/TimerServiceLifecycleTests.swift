import Testing
@testable import Flowbar
import Foundation

@Suite("TimerService lifecycle")
@MainActor
struct TimerServiceLifecycleTests {

    private var timer: TimerService

    init() {
        timer = TimerService()
        // Clean up any leftover active session from a previous test run
        if timer.hasActiveSession { timer.clear() }
    }

    @Test("start sets running state and tracks todo")
    func start() {
        timer.start(todoText: "Write tests", sourceFile: "tasks.md")

        #expect(timer.isRunning)
        #expect(!timer.isPaused)
        #expect(timer.hasActiveSession)
        #expect(timer.currentTodoText == "Write tests")
        #expect(timer.currentSourceFile == "tasks.md")

        timer.clear()
    }

    @Test("pause freezes the timer")
    func pause() {
        timer.start(todoText: "Pause test", sourceFile: "tasks.md")
        timer.pause()

        #expect(!timer.isRunning)
        #expect(timer.isPaused)
        #expect(timer.hasActiveSession)

        timer.clear()
    }

    @Test("resume after pause restarts the timer")
    func resume() {
        timer.start(todoText: "Resume test", sourceFile: "tasks.md")
        timer.pause()
        timer.resume()

        #expect(timer.isRunning)
        #expect(!timer.isPaused)
        #expect(timer.hasActiveSession)

        timer.clear()
    }

    @Test("togglePlayPause flips between running and paused")
    func togglePlayPause() {
        timer.start(todoText: "Toggle test", sourceFile: "tasks.md")

        timer.togglePlayPause()
        #expect(timer.isPaused)

        timer.togglePlayPause()
        #expect(timer.isRunning)

        timer.clear()
    }

    @Test("clear clears all state and sets screen to todos")
    func stop() {
        timer.start(todoText: "Stop test", sourceFile: "tasks.md")
        timer.clear()

        #expect(!timer.isRunning)
        #expect(!timer.isPaused)
        #expect(!timer.hasActiveSession)
        #expect(timer.currentTodoText == "")
        #expect(timer.currentSourceFile == "")
        #expect(timer.elapsed == 0)
        #expect(timer.screen == .todos)
    }

    @Test("complete returns todo info and clears state")
    func complete() {
        timer.start(todoText: "Complete test", sourceFile: "tasks.md")
        let result = timer.complete()

        #expect(result?.todoText == "Complete test")
        #expect(result?.sourceFile == "tasks.md")
        #expect(!timer.hasActiveSession)
    }

    @Test("complete with no active session returns nil")
    func completeNoSession() {
        #expect(timer.complete() == nil)
    }

    @Test("starting a new timer stops the previous one")
    func startReplacesPrevious() {
        timer.start(todoText: "First", sourceFile: "a.md")
        timer.start(todoText: "Second", sourceFile: "b.md")

        #expect(timer.currentTodoText == "Second")
        #expect(timer.currentSourceFile == "b.md")

        timer.clear()
    }

    @Test("isTracking matches current todo")
    func isTracking() {
        timer.start(todoText: "Track me", sourceFile: "tasks.md")

        #expect(timer.isTracking(todoText: "Track me", sourceFile: "tasks.md"))
        #expect(!timer.isTracking(todoText: "Track me", sourceFile: "other.md"))
        #expect(!timer.isTracking(todoText: "Not me", sourceFile: "tasks.md"))

        timer.pause()
        #expect(timer.isTracking(todoText: "Track me", sourceFile: "tasks.md"))

        timer.clear()
        #expect(!timer.isTracking(todoText: "Track me", sourceFile: "tasks.md"))
    }

    @Test("pause and resume are no-ops in wrong states")
    func noOpGuards() {
        // pause when not running
        timer.pause()
        #expect(!timer.isPaused)

        // resume when not paused
        timer.resume()
        #expect(!timer.isRunning)

        // togglePlayPause with no session
        timer.togglePlayPause()
        #expect(!timer.hasActiveSession)
    }
}
