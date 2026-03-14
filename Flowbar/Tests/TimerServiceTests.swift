import XCTest
@testable import Flowbar

@MainActor
final class TimerFormatTests: XCTestCase {

    func testFormatTimeZero() {
        XCTAssertEqual(TimerService.formatTime(0), "00:00")
    }

    func testFormatTimeSeconds() {
        XCTAssertEqual(TimerService.formatTime(5), "00:05")
        XCTAssertEqual(TimerService.formatTime(59), "00:59")
    }

    func testFormatTimeMinutes() {
        XCTAssertEqual(TimerService.formatTime(60), "01:00")
        XCTAssertEqual(TimerService.formatTime(90), "01:30")
        XCTAssertEqual(TimerService.formatTime(600), "10:00")
    }

    func testFormatTimeLargeValues() {
        XCTAssertEqual(TimerService.formatTime(3600), "60:00")
        XCTAssertEqual(TimerService.formatTime(3661), "61:01")
    }

    func testFormatTimeFractionalSeconds() {
        XCTAssertEqual(TimerService.formatTime(5.7), "00:05")
        XCTAssertEqual(TimerService.formatTime(59.9), "00:59")
    }
}
