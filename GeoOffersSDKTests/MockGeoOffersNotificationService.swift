//  Copyright © 2019 Zappit. All rights reserved.

import Foundation
@testable import GeoOffersSDK

class MockGeoOffersNotificationService: GeoOffersNotificationService {
    private(set) var removeNotificationCalled = false
    private(set) var sendNotificationCalled = false
    
    override func removeNotification(with identifier: String) {
        removeNotificationCalled = true
        super.removeNotification(with: identifier)
    }
    
    override func sendNotification(title: String, subtitle: String, delayMs: Double, identifier: String, isSilent: Bool) {
        sendNotificationCalled = true
        super.sendNotification(title: title, subtitle: subtitle, delayMs: delayMs, identifier: identifier, isSilent: isSilent)
    }
}
