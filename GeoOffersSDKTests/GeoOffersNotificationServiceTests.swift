//  Copyright © 2019 Zappit. All rights reserved.

@testable import GeoOffersSDK
import UserNotifications
import XCTest

class MockUNNotificationSettings: UNNotificationSettings {
    var mockAuthorizationStatus: UNAuthorizationStatus = .notDetermined

    override var authorizationStatus: UNAuthorizationStatus {
        return mockAuthorizationStatus
    }
}

class MockUNUserNotificationCenter: GeoOffersUserNotificationCenter {
    var forcedError: Error?
    private(set) var requestAuthorizationCalled = false
    private(set) var removeAllPendingNotificationRequestsCalled = false
    private(set) var removeAllDeliveredNotificationsCalled = false
    private(set) var addNotificationCalled = false
    private(set) var removePendingNotificationRequestsCalled = false
    private(set) var getNotificationSettingsCalled = false

    func requestAuthorization(options _: UNAuthorizationOptions = [], completionHandler: @escaping (Bool, Error?) -> Void) {
        requestAuthorizationCalled = true
        completionHandler(true, forcedError)
    }

    func removeAllPendingNotificationRequests() {
        removeAllPendingNotificationRequestsCalled = true
    }

    func removeAllDeliveredNotifications() {
        removeAllDeliveredNotificationsCalled = true
    }

    func add(_: UNNotificationRequest, withCompletionHandler completionHandler: ((Error?) -> Void)? = nil) {
        addNotificationCalled = true
        _ = completionHandler?(forcedError)
    }

    func removePendingNotificationRequests(withIdentifiers _: [String]) {
        removePendingNotificationRequestsCalled = true
    }

    func getNotificationSettings(completionHandler: @escaping (UNNotificationSettings) -> Void) {
        getNotificationSettingsCalled = true
        let decoder = NSKeyedUnarchiver(forReadingWith: Data())
        guard let settings = MockUNNotificationSettings(coder: decoder) else {
            XCTFail("Failed to create settings")
            return
        }
        settings.mockAuthorizationStatus = .authorized
        completionHandler(settings)
    }
}

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
