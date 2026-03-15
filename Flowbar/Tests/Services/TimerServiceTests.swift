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
}
