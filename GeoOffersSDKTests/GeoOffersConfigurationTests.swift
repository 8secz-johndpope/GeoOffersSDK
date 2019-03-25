//  Copyright © 2019 Zappit. All rights reserved.

import CoreLocation
@testable import GeoOffersSDK
import XCTest

class GeoOffersConfigurationTests: XCTestCase {
    private let testRegistrationCode = "123456"
    private let testAuthToken = UUID().uuidString
    private let testClientID = 100

    override func setUp() {
        let configuration = GeoOffersConfiguration(registrationCode: testRegistrationCode, authToken: testAuthToken, testing: true)
        configuration.clientID = nil
    }

    override func tearDown() {
        let configuration = GeoOffersConfiguration(registrationCode: testRegistrationCode, authToken: testAuthToken, testing: true)
        configuration.pushToken = nil
        configuration.pendingPushTokenRegistration = nil
    }

    func test_basic_configuration() {
        let configuration = GeoOffersConfiguration(registrationCode: testRegistrationCode, authToken: testAuthToken, testing: true)
        XCTAssert(configuration.registrationCode == testRegistrationCode, "Invalid registrationCode:\(configuration.registrationCode)")
        XCTAssert(configuration.authToken == testAuthToken, "Invalid authToken:\(configuration.authToken)")
        XCTAssert(!configuration.deviceID.isEmpty, "Invalid deviceID:\(configuration.deviceID)")
        XCTAssert(configuration.apiURL == "https://app-stg.zappitrewards.com/api", "Invalid apiURL:\(configuration.apiURL)")
        print(configuration.timezone == "Europe/London")
    }

    func test_refresh() {
        let configuration = GeoOffersConfiguration(registrationCode: testRegistrationCode, authToken: testAuthToken, testing: true)
        let newToken = UUID().uuidString
        GeoOffersSDKUserDefaults.shared.deviceID = newToken
        configuration.refresh()
        XCTAssertEqual(configuration.deviceID, newToken)
    }

    func test_zeroLocation() {
        GeoOffersSDKUserDefaults.shared.lastRefreshLocation = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        XCTAssertNil(GeoOffersSDKUserDefaults.shared.lastRefreshLocation)
    }

    func test_generate_new_deviceid() {
        let configuration = GeoOffersConfiguration(registrationCode: testRegistrationCode, authToken: testAuthToken, testing: true)
        let deviceID = configuration.deviceID
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "GeoOffers_DeviceID")
        defaults.synchronize()
        let configuration2 = GeoOffersConfiguration(registrationCode: testRegistrationCode, authToken: testAuthToken, testing: true)
        let deviceID2 = configuration2.deviceID
        XCTAssert(deviceID != deviceID2, "Device ID's should be different")
    }

    func test_clientID() {
        let configuration = GeoOffersConfiguration(registrationCode: testRegistrationCode, authToken: testAuthToken, testing: true)
        XCTAssertNil(configuration.clientID)
        configuration.clientID = testClientID
        XCTAssertEqual(configuration.clientID, testClientID)
        configuration.clientID = nil
    }

    func test_pushToken() {
        let configuration = GeoOffersConfiguration(registrationCode: testRegistrationCode, authToken: testAuthToken, testing: true)
        let testPushToken = "Token12345"
        XCTAssertNil(configuration.pushToken)
        configuration.pushToken = testPushToken
        XCTAssertEqual(configuration.pushToken, testPushToken)
    }

    func test_pendingPushToken() {
        let configuration = GeoOffersConfiguration(registrationCode: testRegistrationCode, authToken: testAuthToken, testing: true)
        let testPendingPushTokenRegistration = "Token12345"
        XCTAssertNil(configuration.pendingPushTokenRegistration)
        configuration.pendingPushTokenRegistration = testPendingPushTokenRegistration
        XCTAssertEqual(configuration.pendingPushTokenRegistration, testPendingPushTokenRegistration)
        configuration.pendingPushTokenRegistration = nil
    }

    func test_deviceID_should_persist() {
        let configuration = GeoOffersConfiguration(registrationCode: testRegistrationCode, authToken: testAuthToken, testing: true)
        let configuration2 = GeoOffersConfiguration(registrationCode: testRegistrationCode, authToken: testAuthToken)
        let deviceID = configuration.deviceID
        let deviceID2 = configuration2.deviceID
        XCTAssert(deviceID == deviceID2, "Device ID's should match")
    }

    func test_last_known_location_cache() {
        let defaults = GeoOffersSDKUserDefaults.shared
        let location = CLLocationCoordinate2D(latitude: 52.1, longitude: -0.25)
        defaults.lastKnownLocation = location
        let location2 = defaults.lastKnownLocation
        defaults.lastKnownLocation = nil
        XCTAssert(location.latitude == location2?.latitude, "Latitude should match")
        XCTAssert(location.longitude == location2?.longitude, "Longitude should match")
    }

    func test_location_at_0_0_should_return_nil() {
        let defaults = GeoOffersSDKUserDefaults.shared
        let location = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        defaults.lastKnownLocation = location
        let location2 = defaults.lastKnownLocation
        XCTAssert(location2 == nil, "Invalid location")
    }
}
