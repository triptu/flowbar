import Testing
import Foundation
@testable import Flowbar

@Suite("TimerService")
struct TimerServiceTests {

    @Test("formatTime", arguments: [
        (0.0, "00:00"),
        (5.0, "00:05"),
        (59.0, "00:59"),
        (60.0, "01:00"),
        (90.0, "01:30"),
        (600.0, "10:00"),
        (3599.0, "59:59"),
        (3600.0, "1:00:00"),
        (3661.0, "1:01:01"),
        (7200.0, "2:00:00"),
        (7325.0, "2:02:05"),
        (36000.0, "10:00:00"),
        (5.7, "00:05"),
        (59.9, "00:59"),
        (3600.9, "1:00:00"),
    ] as [(TimeInterval, String)])
    func formatTime(input: TimeInterval, expected: String) {
        #expect(TimerService.formatTime(input) == expected)
    }

    // MARK: - mergeTimeline

    private typealias Entry = (todoText: String, sourceFile: String, startedAt: Date, endedAt: Date)

    private static func d(_ minute: Int, _ second: Int = 0) -> Date {
        DateComponents(calendar: .current, year: 2026, month: 3, day: 17, hour: 3, minute: minute, second: second).date!
    }

    @Test("mergeTimeline empty input returns empty")
    func mergeEmpty() {
        let result = TimerService.mergeTimeline([])
        #expect(result.isEmpty)
    }

    @Test("mergeTimeline single entry unchanged")
    func mergeSingle() {
        let raw: [Entry] = [("A", "f", Self.d(10), Self.d(10, 30))]
        let result = TimerService.mergeTimeline(raw)
        #expect(result.count == 1)
        #expect(result[0].todoText == "A")
        #expect(result[0].duration == 30)
    }

    @Test("mergeTimeline consecutive same-name entries merge")
    func mergeConsecutiveSame() {
        // DESC order: newest first
        let raw: [Entry] = [
            ("A", "f", Self.d(5), Self.d(5, 10)),   // 10s
            ("A", "f", Self.d(3), Self.d(3, 20)),   // 20s
            ("A", "f", Self.d(1), Self.d(1, 5)),    // 5s
        ]
        let result = TimerService.mergeTimeline(raw)
        #expect(result.count == 1)
        #expect(result[0].startedAt == Self.d(1))
        #expect(result[0].endedAt == Self.d(5, 10))
        #expect(result[0].duration == 35)
    }

    @Test("mergeTimeline different entries stay separate")
    func mergeDifferentEntries() {
        let raw: [Entry] = [
            ("B", "f", Self.d(10), Self.d(10, 5)),
            ("A", "f", Self.d(5), Self.d(5, 10)),
        ]
        let result = TimerService.mergeTimeline(raw)
        #expect(result.count == 2)
        #expect(result[0].todoText == "B")
        #expect(result[1].todoText == "A")
    }

    @Test("mergeTimeline same name non-consecutive stays separate")
    func mergeSameNonConsecutive() {
        // A, B, A — should NOT merge the two A's
        let raw: [Entry] = [
            ("A", "f", Self.d(10), Self.d(10, 5)),
            ("B", "f", Self.d(7), Self.d(7, 10)),
            ("A", "f", Self.d(3), Self.d(3, 5)),
        ]
        let result = TimerService.mergeTimeline(raw)
        #expect(result.count == 3)
        #expect(result[0].todoText == "A")
        #expect(result[1].todoText == "B")
        #expect(result[2].todoText == "A")
    }
}
