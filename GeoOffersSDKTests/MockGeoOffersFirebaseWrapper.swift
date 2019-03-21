//  Copyright © 2019 Zappit. All rights reserved.

import Foundation
@testable import GeoOffersSDK

class MockGeoOffersFirebaseWrapper: GeoOffersFirebaseWrapperProtocol {
    weak var delegate: GeoOffersFirebaseWrapperDelegate?
    private(set) var applicationDidFinishLaunchingCalled = false
    private(set) var didRegisterForPushNotificationsCalled = false
    private(set) var appDidReceiveMessageCalled = false

    func applicationDidFinishLaunching() {
        applicationDidFinishLaunchingCalled = true
    }

    func didRegisterForPushNotifications(deviceToken _: Data) {
        didRegisterForPushNotificationsCalled = true
    }

    func appDidReceiveMessage(userInfo _: [AnyHashable: Any]) {
        appDidReceiveMessageCalled = true
    }
}
