//  Copyright © 2019 Zappit. All rights reserved.

import Foundation
@testable import GeoOffersSDK

class MockConfiguration: GeoOffersInternalConfiguration {
    override func refresh() {}

    override var apiURL: String { return "" }
    
    init() {
        super.init(configuration: GeoOffersConfiguration(registrationCode: "123456", authToken: UUID().uuidString, testing: false))
    }
}

let testRegistrationCode = "123456"
let testAuthToken = UUID().uuidString
let testClientID = 100

let defaultAppConfig = GeoOffersConfiguration(registrationCode: testRegistrationCode, authToken: testAuthToken, testing: true)
let defaultTestConfiguration = GeoOffersInternalConfiguration(configuration: defaultAppConfig)
