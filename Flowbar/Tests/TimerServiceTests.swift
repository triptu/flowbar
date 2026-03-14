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
        XCTAssertEqual(TimerService.formatTime(3599), "59:59")
    }

    func testFormatTimeExactlyOneHour() {
        XCTAssertEqual(TimerService.formatTime(3600), "1:00:00")
    }

    func testFormatTimeHoursAndMinutesAndSeconds() {
        XCTAssertEqual(TimerService.formatTime(3661), "1:01:01")
        XCTAssertEqual(TimerService.formatTime(7200), "2:00:00")
        XCTAssertEqual(TimerService.formatTime(7325), "2:02:05")
        XCTAssertEqual(TimerService.formatTime(36000), "10:00:00")
    }

    func testFormatTimeFractionalSeconds() {
        XCTAssertEqual(TimerService.formatTime(5.7), "00:05")
        XCTAssertEqual(TimerService.formatTime(59.9), "00:59")
        XCTAssertEqual(TimerService.formatTime(3600.9), "1:00:00")
    }
}
