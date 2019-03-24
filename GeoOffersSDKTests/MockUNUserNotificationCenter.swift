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
