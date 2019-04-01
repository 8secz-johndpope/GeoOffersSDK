//  Copyright © 2019 Zappit. All rights reserved.

import Foundation
@testable import GeoOffersSDK

class MockGeoOffersNotificationService: GeoOffersNotificationService {
    private(set) var sendNotificationCalled = false

    override func sendNotification(title: String, subtitle: String, delaySeconds: Double, identifier: String, isSilent: Bool) {
        sendNotificationCalled = true
        super.sendNotification(title: title, subtitle: subtitle, delaySeconds: delaySeconds, identifier: identifier, isSilent: isSilent)
    }
}
