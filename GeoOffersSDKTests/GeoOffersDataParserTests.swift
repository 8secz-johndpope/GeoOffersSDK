//  Copyright © 2019 Zappit. All rights reserved.

import CoreLocation
@testable import GeoOffersSDK
import XCTest

class GeoOffersDataParserTests: XCTestCase {
    private var parser: GeoOffersPresenter!
    private var pushNotificationProcessor: GeoOffersPushNotificationProcessor!
    private var locationService: GeoOffersLocationService!
    private let locationManager: GeoOffersLocationManager = MockLocationManager()
    private let testLocation = CLLocationCoordinate2D(latitude: 52.4, longitude: -0.25)
    private let testRegistrationCode = "123456"
    private let testAuthToken = UUID().uuidString
    private let testClientID = 100
    private var configuration: GeoOffersConfiguration!
    private var cache = TestCacheHelper()

    override func setUp() {
        let configuration = GeoOffersConfiguration(registrationCode: testRegistrationCode, authToken: testAuthToken, testing: true)
        configuration.clientID = nil
        self.configuration = configuration
        locationService = GeoOffersLocationService(latestLocation: nil, locationManager: locationManager, configuration: configuration)
        parser = GeoOffersPresenter(configuration: configuration, locationService: locationService, cacheService: cache.webViewCache)
        pushNotificationProcessor = GeoOffersPushNotificationProcessor(notificationCache: cache.notificationCache, listingCache: cache.listingCache)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_schedule_isValid() {
        guard let data = FileLoader.loadTestData(filename: "example-nearby-geofences") else {
            XCTFail("Where's my test data?")
            return
        }

        guard let fenceData = pushNotificationProcessor.parseNearbyFences(jsonData: data) else {
            XCTFail("Where's my test data?")
            return
        }

        guard let schedule = fenceData.schedules.first else {
            XCTFail("Where's my schedule data?")
            return
        }

        let date = geoOffersScheduleDateFormatter.date(from: "2019-02-20 09:00:00")!
        let isValid = schedule.isValid(for: date)
        XCTAssertTrue(isValid)
    }

    func test_repeatingschedule_isValid() {
        guard let data = FileLoader.loadTestData(filename: "example-nearby-geofences-with-repeating-schedule") else {
            XCTFail("Where's my test data?")
            return
        }

        guard let fenceData = pushNotificationProcessor.parseNearbyFences(jsonData: data) else {
            XCTFail("Where's my test data?")
            return
        }

        guard let schedule = fenceData.schedules.first else {
            XCTFail("Where's my schedule data?")
            return
        }

        let date = geoOffersScheduleDateFormatter.date(from: "2019-02-20 09:00:00")!
        let isValid = schedule.isValid(for: date)
        XCTAssertTrue(isValid)
    }

    func test_parseNearbyFences() {
        guard let data = FileLoader.loadTestData(filename: "example-nearby-geofences") else {
            XCTFail("Where's my test data?")
            return
        }

        guard let fenceData = pushNotificationProcessor.parseNearbyFences(jsonData: data) else {
            XCTFail("Where's my test data?")
            return
        }
        XCTAssert(fenceData.scheduleDeviceIDs.count == 10, "Wrong number of scheduleDeviceID's:\(fenceData.scheduleDeviceIDs.count)")
        XCTAssert(fenceData.clientID == 40, "Wrong clientID:\(fenceData.clientID)")
        XCTAssert(fenceData.campaignID == 4354, "Wrong campaignID:\(fenceData.campaignID)")
        XCTAssert(fenceData.schedules.count == 4, "Wrong number of schedules:\(fenceData.schedules.count)")
        XCTAssert(fenceData.deliveredSchedules.count == 8, "Wrong number of deliveredSchedules:\(fenceData.deliveredSchedules.count)")
        XCTAssert(fenceData.regions.count == 4, "Wrong number of regions:\(fenceData.regions.count)")

        guard let region1 = fenceData.regions["5139"]?.first else {
            XCTFail("Should be at least 1 region")
            return
        }
        XCTAssert(region1.scheduleID == 5139, "Wrong scheduleID in first region:\(region1.scheduleID)")
        XCTAssert(region1.scheduleDeviceID == "5c0f9a4443e23", "Wrong scheduleDeviceID in first region:\(region1.scheduleDeviceID)")
        XCTAssert(region1.logoImageUrl == "https://s3rewards-staging-ppe.s3.amazonaws.com/offers_img_small/14391.jpeg", "Wrong logoImageUrl in first region:\(region1.logoImageUrl)")
        XCTAssert(region1.latitude == 51.506012, "Wrong latitude in first region:\(region1.latitude)")
        XCTAssert(region1.longitude == -0.463213, "Wrong longitude in first region:\(region1.longitude)")
        XCTAssert(region1.radiusMeters == 100, "Wrong radiusKm in first region:\(region1.radiusMeters)")
        XCTAssert(region1.notificationTitle == "Sainsbury's sale", "Wrong notificationTitle in first region:\(region1.notificationTitle)")
        XCTAssert(region1.notificationMessage == "Sainsbury's sale", "Wrong notificationMessage in first region:\(region1.notificationMessage)")
        XCTAssert(region1.notificationDeliveryDelayMs == 0, "Wrong notificationDeliveryDelayMs in first region:\(region1.notificationDeliveryDelayMs)")
        XCTAssert(region1.doesNotNotify == false, "Wrong doesNotNotifyscheduleID in first region:\(region1.doesNotNotify)")
        XCTAssert(region1.notifiesSilently == false, "Wrong notifiesSilentlyscheduleID in first region:\(region1.notifiesSilently)")
    }

    func test_parseNearbyFences_with_empty_data() {
        guard let data = FileLoader.loadTestData(filename: "example-nearby-geofences-empty") else {
            XCTFail("Where's my test data?")
            return
        }

        guard let fenceData = pushNotificationProcessor.parseNearbyFences(jsonData: data) else {
            XCTFail("Where's my test data?")
            return
        }

        XCTAssert(fenceData.clientID == 40, "Wrong clientID:\(fenceData.clientID)")
        XCTAssert(fenceData.campaignID == 4354, "Wrong campaignID:\(fenceData.campaignID)")
        XCTAssert(fenceData.scheduleDeviceIDs.isEmpty, "Wrong number of scheduleDeviceID's:\(fenceData.scheduleDeviceIDs.count)")
    }

    func test_parseNearbyFences_with_invalidData() {
        let data = Data()
        let fenceData = pushNotificationProcessor.parseNearbyFences(jsonData: data)
        XCTAssertNil(fenceData)
    }

    func test_buildOfferListQuerystring_no_location() {
        let value = parser.buildOfferListQuerystring(configuration: configuration, locationService: locationService)
        XCTAssertTrue(value.hasPrefix("#\(configuration.registrationCode),,"), "\(value)")
    }

    func test_buildOfferListQuerystring_with_location() {
        locationManager.delegate?.locationManager?(CLLocationManager(), didUpdateLocations: [CLLocation(latitude: testLocation.latitude, longitude: testLocation.longitude)])
        let value = parser.buildOfferListQuerystring(configuration: configuration, locationService: locationService)
        XCTAssertTrue(value.hasPrefix("#\(configuration.registrationCode),\(testLocation.latitude),\(testLocation.longitude)"), "\(value)")
    }

    func test_buildCouponQuerystring_no_location() {
        let value = parser.buildCouponQuerystring(configuration: configuration, locationService: locationService)
        XCTAssertTrue(value.hasPrefix("#,,"), "\(value)")
    }

    func test_buildCouponQuerystring_with_location() {
        locationManager.delegate?.locationManager?(CLLocationManager(), didUpdateLocations: [CLLocation(latitude: testLocation.latitude, longitude: testLocation.longitude)])
        let value = parser.buildCouponQuerystring(configuration: configuration, locationService: locationService)
        XCTAssertTrue(value.hasPrefix("#\(testLocation.latitude),\(testLocation.longitude)"), "\(value)")
    }

    func test_buildJavascriptForWebView() {
        let value = parser.buildJavascriptForWebView(listingData: "<listingData_test>", couponData: "<couponData_test>", authToken: "<authToken_test>", tabBackgroundColor: "<tabBackgroundColor_test>", alreadyDeliveredOfferData: "<AlreadyDeliveredOfferData_test>", deliveredIdsAndTimestamps: "<deliveredIdsAndTimestamps_test>")

        XCTAssertTrue(value.contains("<listingData_test>"))
        XCTAssertTrue(value.contains("<couponData_test>"))
        XCTAssertTrue(value.contains("<authToken_test>"))
        XCTAssertTrue(value.contains("<tabBackgroundColor_test>"))
        XCTAssertTrue(value.contains("<AlreadyDeliveredOfferData_test>"))
        XCTAssertTrue(value.contains("<deliveredIdsAndTimestamps_test>"))
        XCTAssertFalse(value.contains("<listingData>"))
        XCTAssertFalse(value.contains("<couponData>"))
        XCTAssertFalse(value.contains("<authToken>"))
        XCTAssertFalse(value.contains("<tabBackgroundColor>"))
        XCTAssertFalse(value.contains("<AlreadyDeliveredOfferData>"))
        XCTAssertFalse(value.contains("<deliveredIdsAndTimestamps>"))
    }

    func test_loadNearbyDataWithMissingProperties() {
        let data = FileLoader.loadTestData(filename: "example-nearby-geofences-missing-data")!
        let fenceData = pushNotificationProcessor.parseNearbyFences(jsonData: data)!
        XCTAssertEqual(fenceData.clientID, 40)
        XCTAssertEqual(fenceData.campaignID, 4354)
        XCTAssertEqual(fenceData.catchmentRadius, 1)
        XCTAssertEqual(fenceData.campaigns.count, 4)
        XCTAssertEqual(fenceData.regions.count, 0)
        XCTAssertEqual(fenceData.schedules.count, 0)
        XCTAssertEqual(fenceData.scheduleDeviceIDs.count, 0)
        XCTAssertEqual(fenceData.deliveredSchedules.count, 0)
        XCTAssertEqual(fenceData.timezone, TimeZone.current.identifier)
    }
}
