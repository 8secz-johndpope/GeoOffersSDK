//  Copyright © 2019 Zappit. All rights reserved.

@testable import GeoOffersSDK
import UserNotifications
import XCTest

class GeoOffersNotificationServiceTests: XCTestCase {
    private var notificationCenter = MockUNUserNotificationCenter()
    private var service: GeoOffersNotificationService!

    override func setUp() {
        service = GeoOffersNotificationServiceDefault(notificationCenter: notificationCenter)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_request_permissions() {
        service.requestNotificationPermissions()
        XCTAssert(notificationCenter.requestAuthorizationCalled, "Didn't call method")
    }

    func test_request_permissions_with_error() {
        notificationCenter.forcedError = TestErrors.requestAuthorisationFailed
        service.requestNotificationPermissions()
        XCTAssert(notificationCenter.requestAuthorizationCalled, "Didn't call method")
    }

    func test_application_did_become_active() {
        service.applicationDidBecomeActive(UIApplication.shared)
        XCTAssert(notificationCenter.removeAllPendingNotificationRequestsCalled, "Didn't call method")
        XCTAssert(notificationCenter.removeAllDeliveredNotificationsCalled, "Didn't call method")
    }

    func test_send_notification() {
        service.sendNotification(title: "This is a great message", subtitle: "A subtitle", delayMs: 0, identifier: "Testing", isSilent: true)
        XCTAssert(notificationCenter.addNotificationCalled, "Didn't call method")
    }

    func test_send_empty_notification() {
        service.sendNotification(title: "", subtitle: "A subtitle", delayMs: 0, identifier: "Testing", isSilent: true)
        XCTAssert(notificationCenter.addNotificationCalled == false, "Didn't call method")
    }

    func test_send_empty_notification_with_error() {
        notificationCenter.forcedError = TestErrors.sendNotificationFailed
        service.sendNotification(title: "This is a great message", subtitle: "A subtitle", delayMs: 0, identifier: "Testing", isSilent: false)
        XCTAssert(notificationCenter.addNotificationCalled, "Didn't call method")
    }

    func test_removeNotification() {
        service.removeNotification(with: "abc")
        XCTAssert(notificationCenter.removePendingNotificationRequestsCalled, "Didn't call method")
    }
}
