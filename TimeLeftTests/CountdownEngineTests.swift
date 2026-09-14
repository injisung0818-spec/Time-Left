import XCTest

final class CountdownEngineTests: XCTestCase {
    private func calendar(timeZoneID: String = "Asia/Seoul") -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "ko_KR")
        calendar.timeZone = TimeZone(identifier: timeZoneID)!
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int,
                      _ second: Int = 0, calendar: Calendar) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day,
                                           hour: hour, minute: minute, second: second))!
    }

    func testSchoolCycleChangesFromFridayToSundayAndBack() {
        let calendar = calendar()
        let school = CountdownSchedule.school()

        let beforeFriday = date(2026, 9, 4, 14, 19, calendar: calendar)
        XCTAssertEqual(CountdownEngine.targetDate(schedule: school, now: beforeFriday, calendar: calendar),
                       date(2026, 9, 4, 14, 20, calendar: calendar))
        XCTAssertEqual(CountdownEngine.displayName(schedule: school,
                                                   target: CountdownEngine.targetDate(schedule: school, now: beforeFriday, calendar: calendar),
                                                   calendar: calendar), "하교")

        let afterFriday = date(2026, 9, 4, 14, 20, 1, calendar: calendar)
        XCTAssertEqual(CountdownEngine.targetDate(schedule: school, now: afterFriday, calendar: calendar),
                       date(2026, 9, 6, 21, 0, calendar: calendar))
        XCTAssertEqual(CountdownEngine.displayName(schedule: school,
                                                   target: CountdownEngine.targetDate(schedule: school, now: afterFriday, calendar: calendar),
                                                   calendar: calendar), "등교")

        let afterSunday = date(2026, 9, 6, 21, 0, calendar: calendar)
        XCTAssertEqual(CountdownEngine.targetDate(schedule: school, now: afterSunday, calendar: calendar),
                       date(2026, 9, 11, 14, 20, calendar: calendar))
    }

    func testWeeklyScheduleRollsToFollowingWeekAfterTargetTime() {
        let calendar = calendar()
        var schedule = CountdownSchedule.new()
        schedule.kind = .weekdayTime
        schedule.weekday = 6 // Friday
        schedule.timeOfDay = date(2001, 1, 1, 14, 20, calendar: calendar)
        schedule.repeatWeekly = true

        XCTAssertEqual(CountdownEngine.targetDate(schedule: schedule,
                                                   now: date(2026, 9, 4, 13, 0, calendar: calendar),
                                                   calendar: calendar),
                       date(2026, 9, 4, 14, 20, calendar: calendar))
        XCTAssertEqual(CountdownEngine.targetDate(schedule: schedule,
                                                   now: date(2026, 9, 4, 15, 0, calendar: calendar),
                                                   calendar: calendar),
                       date(2026, 9, 11, 14, 20, calendar: calendar))
    }

    func testExpiredOneTimeScheduleIsExcluded() {
        let calendar = calendar()
        var schedule = CountdownSchedule.new()
        schedule.kind = .specificDate
        schedule.selectedDate = date(2026, 9, 5, 10, 0, calendar: calendar)

        XCTAssertFalse(CountdownEngine.isExpiredOneTimeSchedule(schedule,
                                                                 now: date(2026, 9, 5, 9, 59, calendar: calendar),
                                                                 calendar: calendar))
        XCTAssertTrue(CountdownEngine.isExpiredOneTimeSchedule(schedule,
                                                                now: date(2026, 9, 5, 10, 0, calendar: calendar),
                                                                calendar: calendar))
    }

    func testYearEndTargetsNextJanuaryFirst() {
        let calendar = calendar()
        var schedule = CountdownSchedule.new()
        schedule.kind = .yearEnd

        XCTAssertEqual(CountdownEngine.targetDate(schedule: schedule,
                                                   now: date(2026, 12, 31, 23, 59, 59, calendar: calendar),
                                                   calendar: calendar),
                       date(2027, 1, 1, 0, 0, calendar: calendar))
        XCTAssertEqual(CountdownEngine.targetDate(schedule: schedule,
                                                   now: date(2027, 1, 1, 0, 0, calendar: calendar),
                                                   calendar: calendar),
                       date(2028, 1, 1, 0, 0, calendar: calendar))
    }

    func testWeeklyTargetKeepsLocalTimeAcrossDaylightSavingTime() {
        let calendar = calendar(timeZoneID: "America/Los_Angeles")
        var schedule = CountdownSchedule.new()
        schedule.kind = .weekdayTime
        schedule.weekday = 1 // Sunday
        schedule.timeOfDay = date(2001, 1, 1, 9, 0, calendar: calendar)
        schedule.repeatWeekly = true

        let target = CountdownEngine.targetDate(schedule: schedule,
                                                now: date(2026, 3, 7, 12, 0, calendar: calendar),
                                                calendar: calendar)
        XCTAssertEqual(target, date(2026, 3, 8, 9, 0, calendar: calendar))
    }
}
