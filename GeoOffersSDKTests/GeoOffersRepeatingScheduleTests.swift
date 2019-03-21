//  Copyright © 2019 Zappit. All rights reserved.

@testable import GeoOffersSDK
import XCTest

class GeoOffersRepeatingScheduleTests: XCTestCase {
    private let decoder = JSONDecoder()

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_daily_schedule() {
        let filename = "example-repeatingschedule-daily"
        guard let jsonData = FileLoader.loadTestData(filename: filename) else {
            XCTFail("Could not load test data")
            return
        }
        do {
            let schedule = try decoder.decode(GeoOffersRepeatingSchedule.self, from: jsonData)
            XCTAssertEqual(schedule.type, .daily)
            XCTAssertNil(schedule.start.dayOfWeek)
            XCTAssertNil(schedule.start.dayOfMonth)
            XCTAssertNil(schedule.start.month)
            XCTAssertEqual(schedule.start.hours, 9)
            XCTAssertEqual(schedule.start.minutes, 0)
            XCTAssertNil(schedule.end.dayOfWeek)
            XCTAssertNil(schedule.end.dayOfMonth)
            XCTAssertNil(schedule.end.month)
            XCTAssertEqual(schedule.end.hours, 17)
            XCTAssertEqual(schedule.end.minutes, 0)
        } catch {
            XCTFail("\(error)")
        }
    }

    func test_weekly_schedule() {
        let filename = "example-repeatingschedule-weekly"
        guard let jsonData = FileLoader.loadTestData(filename: filename) else {
            XCTFail("Could not load test data")
            return
        }
        do {
            let schedule = try decoder.decode(GeoOffersRepeatingSchedule.self, from: jsonData)
            XCTAssertEqual(schedule.type, .weekly)
            XCTAssertEqual(schedule.start.dayOfWeek, 1)
            XCTAssertNil(schedule.start.dayOfMonth)
            XCTAssertNil(schedule.start.month)
            XCTAssertEqual(schedule.start.hours, 10)
            XCTAssertEqual(schedule.start.minutes, 0)
            XCTAssertEqual(schedule.end.dayOfWeek, 1)
            XCTAssertNil(schedule.end.dayOfMonth)
            XCTAssertNil(schedule.end.month)
            XCTAssertEqual(schedule.end.hours, 14)
            XCTAssertEqual(schedule.end.minutes, 0)
        } catch {
            XCTFail("\(error)")
        }
    }

    func test_weekly_schedule_validation_valid() {
        let filename = "example-repeatingschedule-weekly"
        guard let jsonData = FileLoader.loadTestData(filename: filename) else {
            XCTFail("Could not load test data")
            return
        }
        do {
            let schedule = try decoder.decode(GeoOffersRepeatingSchedule.self, from: jsonData)
            XCTAssertEqual(schedule.type, .weekly)
            XCTAssertEqual(schedule.start.dayOfWeek, 1)
            XCTAssertNil(schedule.start.dayOfMonth)
            XCTAssertNil(schedule.start.month)
            XCTAssertEqual(schedule.start.hours, 10)
            XCTAssertEqual(schedule.start.minutes, 0)
            XCTAssertEqual(schedule.end.dayOfWeek, 1)
            XCTAssertNil(schedule.end.dayOfMonth)
            XCTAssertNil(schedule.end.month)
            XCTAssertEqual(schedule.end.hours, 14)
            XCTAssertEqual(schedule.end.minutes, 0)

            let date = geoOffersScheduleDateFormatter.date(from: "2019-01-21 12:00:00")!
            let isValid = schedule.isValid(for: date)
            XCTAssertTrue(isValid)

        } catch {
            XCTFail("\(error)")
        }
    }

    func test_dayOfWeek() {
        let calendar = Calendar.current
        let monday = geoOffersScheduleDateFormatter.date(from: "2019-01-21 12:00:00")!
        let tuesday = geoOffersScheduleDateFormatter.date(from: "2019-01-22 12:00:00")!
        let wednesday = geoOffersScheduleDateFormatter.date(from: "2019-01-23 12:00:00")!
        let thursday = geoOffersScheduleDateFormatter.date(from: "2019-01-24 12:00:00")!
        let friday = geoOffersScheduleDateFormatter.date(from: "2019-01-25 12:00:00")!
        let saturday = geoOffersScheduleDateFormatter.date(from: "2019-01-26 12:00:00")!
        let sunday = geoOffersScheduleDateFormatter.date(from: "2019-01-27 12:00:00")!

        XCTAssertEqual(calendar.dayOfWeek(monday), 1)
        XCTAssertEqual(calendar.dayOfWeek(tuesday), 2)
        XCTAssertEqual(calendar.dayOfWeek(wednesday), 3)
        XCTAssertEqual(calendar.dayOfWeek(thursday), 4)
        XCTAssertEqual(calendar.dayOfWeek(friday), 5)
        XCTAssertEqual(calendar.dayOfWeek(saturday), 6)
        XCTAssertEqual(calendar.dayOfWeek(sunday), 7)
    }

    func test_monthly_schedule() {
        let filename = "example-repeatingschedule-monthly"
        guard let jsonData = FileLoader.loadTestData(filename: filename) else {
            XCTFail("Could not load test data")
            return
        }
        do {
            let schedule = try decoder.decode(GeoOffersRepeatingSchedule.self, from: jsonData)
            XCTAssertEqual(schedule.type, .monthly)
            XCTAssertNil(schedule.start.dayOfWeek)
            XCTAssertEqual(schedule.start.dayOfMonth, 5)
            XCTAssertNil(schedule.start.month)
            XCTAssertEqual(schedule.start.hours, 9)
            XCTAssertEqual(schedule.start.minutes, 0)
            XCTAssertNil(schedule.end.dayOfWeek)
            XCTAssertEqual(schedule.end.dayOfMonth, 5)
            XCTAssertNil(schedule.end.month)
            XCTAssertEqual(schedule.end.hours, 11)
            XCTAssertEqual(schedule.end.minutes, 0)
        } catch {
            XCTFail("\(error)")
        }
    }

    func test_monthly_schedule_validation_valid() {
        let filename = "example-repeatingschedule-monthly"
        guard let jsonData = FileLoader.loadTestData(filename: filename) else {
            XCTFail("Could not load test data")
            return
        }
        do {
            let schedule = try decoder.decode(GeoOffersRepeatingSchedule.self, from: jsonData)
            XCTAssertEqual(schedule.type, .monthly)
            XCTAssertNil(schedule.start.dayOfWeek)
            XCTAssertEqual(schedule.start.dayOfMonth, 5)
            XCTAssertNil(schedule.start.month)
            XCTAssertEqual(schedule.start.hours, 9)
            XCTAssertEqual(schedule.start.minutes, 0)
            XCTAssertNil(schedule.end.dayOfWeek)
            XCTAssertEqual(schedule.end.dayOfMonth, 5)
            XCTAssertNil(schedule.end.month)
            XCTAssertEqual(schedule.end.hours, 11)
            XCTAssertEqual(schedule.end.minutes, 0)

            let date = geoOffersScheduleDateFormatter.date(from: "2019-05-05 09:00:00")!
            let isValid = schedule.isValid(for: date)
            XCTAssertTrue(isValid)
        } catch {
            XCTFail("\(error)")
        }
    }

    func test_yearly_schedule() {
        let filename = "example-repeatingschedule-yearly"
        guard let jsonData = FileLoader.loadTestData(filename: filename) else {
            XCTFail("Could not load test data")
            return
        }
        do {
            let schedule = try decoder.decode(GeoOffersRepeatingSchedule.self, from: jsonData)
            XCTAssertEqual(schedule.type, .yearly)
            XCTAssertNil(schedule.start.dayOfWeek)
            XCTAssertEqual(schedule.start.dayOfMonth, 20)
            XCTAssertEqual(schedule.start.month, 5)
            XCTAssertEqual(schedule.start.hours, 9)
            XCTAssertEqual(schedule.start.minutes, 0)
            XCTAssertNil(schedule.end.dayOfWeek)
            XCTAssertEqual(schedule.end.dayOfMonth, 20)
            XCTAssertEqual(schedule.end.month, 5)
            XCTAssertEqual(schedule.end.hours, 15)
            XCTAssertEqual(schedule.end.minutes, 0)
        } catch {
            XCTFail("\(error)")
        }
    }

    func test_yearly_schedule_validation_valid() {
        let filename = "example-repeatingschedule-yearly"
        guard let jsonData = FileLoader.loadTestData(filename: filename) else {
            XCTFail("Could not load test data")
            return
        }
        do {
            let schedule = try decoder.decode(GeoOffersRepeatingSchedule.self, from: jsonData)
            XCTAssertEqual(schedule.type, .yearly)
            XCTAssertNil(schedule.start.dayOfWeek)
            XCTAssertEqual(schedule.start.dayOfMonth, 20)
            XCTAssertEqual(schedule.start.month, 5)
            XCTAssertEqual(schedule.start.hours, 9)
            XCTAssertEqual(schedule.start.minutes, 0)
            XCTAssertNil(schedule.end.dayOfWeek)
            XCTAssertEqual(schedule.end.dayOfMonth, 20)
            XCTAssertEqual(schedule.end.month, 5)
            XCTAssertEqual(schedule.end.hours, 15)
            XCTAssertEqual(schedule.end.minutes, 0)

            let date = geoOffersScheduleDateFormatter.date(from: "2019-05-20 09:00:00")!
            let isValid = schedule.isValid(for: date)
            XCTAssertTrue(isValid)
        } catch {
            XCTFail("\(error)")
        }
    }
}
