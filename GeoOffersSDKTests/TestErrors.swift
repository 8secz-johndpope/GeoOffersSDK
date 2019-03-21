//  Copyright © 2019 Zappit. All rights reserved.

import Foundation

enum TestErrors: Error {
    case requestAuthorisationFailed
    case sendNotificationFailed
    case registerFailed
    case updatePushFailed
    case deleteOfferFailed
    case trackEventFailed
    case retrieveNearbyFencesFailed
}
