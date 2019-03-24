//  Copyright © 2019 Zappit. All rights reserved.

import Foundation
@testable import GeoOffersSDK

class MockConfiguration: GeoOffersSDKConfiguration {
    func refresh() {}
    
    var mainAppUsesFirebase: Bool = false
    let registrationCode: String = "123456"
    let authToken: String = UUID().uuidString
    let deviceID: String = GeoOffersSDKUserDefaults.shared.deviceID
    var selectedCategoryTabBackgroundColor: String = "FF0000"
    var timezone: String = TimeZone.current.identifier
    var apiURL: String = ""
    var offerDetailsURL: String = "https://localhost"
    var clientID: Int?
    var pushToken: String?
    var pendingPushTokenRegistration: String?
    public let minimumRefreshWaitTime: Double = 0
    public let minimumRefreshDistance: Double = 0
}
