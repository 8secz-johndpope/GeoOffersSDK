//  Copyright © 2019 Zappit. All rights reserved.

import CoreLocation
@testable import GeoOffersSDK
import UIKit
import UserNotifications
import XCTest

class GeoOffersPushDataTests: XCTestCase {
    private let parser = GeoOffersDataParser()
    private let locationManager = MockLocationManager()
    private let testLocation = CLLocationCoordinate2D(latitude: 52.4, longitude: -0.25)
    private let testRadius: Double = 1000
    private let testIdentifier = "Test region 1"
    private let testPushToken = "a4ae72cf7f10b4819b1d0a2196ae4013ff55bd7f95b323c6986e1c1523905b17"
    private var tokenData: Data? {
        return FileLoader.loadTestData(filename: "PushToken", withExtension: "data")
    }

    private var notificationCenter = MockUNUserNotificationCenter()

    private var configuration: GeoOffersSDKConfiguration!
    private var notificationService: MockGeoOffersNotificationService!
    private var locationService: GeoOffersLocationService!
    private var apiService: GeoOffersAPIService!
    private var mockAPIService = MockGeoOffersAPIService()
    private var presentationService: GeoOffersPresenter!
    private var session = MockURLSession()
    private var cache: TestCacheHelper!

    private var service: GeoOffersSDKService!
    private var firebaseWrapper = MockGeoOffersFirebaseWrapper()
    private var dataProcessor: GeoOffersDataProcessor!

    fileprivate var delegateHasAvailableOffersCalled = false

    override func setUp() {
        configuration = GeoOffersConfigurationDefault(registrationCode: "TestID", authToken: UUID().uuidString, testing: true)

        locationManager.canMonitorForRegions = true
        locationManager.hasLocationPermission = true
        locationService = GeoOffersLocationService(latestLocation: nil, locationManager: locationManager)

        notificationService = MockGeoOffersNotificationService(notificationCenter: notificationCenter)

        apiService = GeoOffersAPIServiceDefault(configuration: configuration, session: session)
        cache = TestCacheHelper(apiService: mockAPIService)
        session.testDelegate = apiService as? URLSessionDelegate
        let dataParser = GeoOffersDataParser()
        presentationService = GeoOffersPresenterDefault(
            configuration: configuration,
            locationService: locationService,
            cacheService: cache.webViewCache,
            dataParser: dataParser)
        
        dataProcessor = GeoOffersDataProcessor(
            offersCache: cache.offersCache,
            listingCache: cache.listingCache,
            notificationService: notificationService,
            apiService: apiService)

        service = GeoOffersSDKServiceDefault(
            configuration: configuration,
            notificationService: notificationService,
            locationService: locationService,
            apiService: apiService,
            presentationService: presentationService,
            dataParser: dataParser,
            firebaseWrapper: firebaseWrapper,
            fencesCache: cache.fencesCache,
            offersCache: cache.offersCache,
            notificationCache: cache.notificationCache,
            listingCache: cache.listingCache,
            dataProcessor: dataProcessor
        )

        service.delegate = self
    }

    override func tearDown() {
        configuration.pushToken = nil
        configuration.pendingPushTokenRegistration = nil
    }

    func test_decoding_push_notification() {
        guard let data = FileLoader.loadTestData(filename: "part_1_of_split_message") else {
            XCTFail("Where is the test data")
            return
        }

        let decoder = JSONDecoder()
        do {
            let pushData = try decoder.decode(GeoOffersPushData.self, from: data)
            XCTAssertEqual(pushData.messageID, "5c4b5a4b12316")
            XCTAssertEqual(pushData.scheduleID, 5203)
            XCTAssertEqual(pushData.totalParts, 2)
            XCTAssertEqual(pushData.messageIndex, 0)
            XCTAssertEqual(pushData.timestamp, 1_548_442_187_074)
            XCTAssertEqual(pushData.message, "{\"type\":\"REWARD_REMOVED_ADDED_OR_EDITED\",\"scheduleId\":5203,\"geofences\":[{\"lat\":51.69404744,\"lng\":-0.17806409,\"radiusKm\":0.1,\"deviceUid\":\"5c1b8c9b1533b\",\"scheduleId\":5203,\"loiteringDelayMs\":null,\"deliveryDelayMs\":null,\"doesNotNotify\":true,\"notifiesSilently\":false,\"logoImageUrl\":\"\",\"customEntryNotificationTitle\":null,\"customEntryNotificationMessage\":null},{\"lat\":51.69788192,\"lng\":-0.192471679,\"radiusKm\":0.1,\"deviceUid\":\"5c1b8d962068e\",\"scheduleId\":5203,\"loiteringDelayMs\":null,\"deliveryDelayMs\":null,\"doesNotNotify\":true,\"notifiesSilently\":false,\"logoImageUrl\":\"\",\"customEntryNotificationTitle\":null,\"customEntryNotificationMessage\":null},{\"lat\":51.69393897,\"lng\":-0.18139943,\"radiusKm\":0.1,\"deviceUid\":\"5c1b8ee9d49cc\",\"scheduleId\":5203,\"loiteringDelayMs\":null,\"deliveryDelayMs\":null,\"doesNotNotify\":true,\"notifiesSilently\":false,\"logoImageUrl\":\"\",\"customEntryNotificationTitle\":null,\"customEntryNotificationMessage\":null},{\"lat\":51.7034864,\"lng\":-0.19154809999998,\"radiusKm\":0.1,\"deviceUid\":\"ClientCode-535987-OffersAppGooglePlaceIdChIJQTC2xEo9dkgRHf5kgZdl9lc\",\"scheduleId\":5203,\"loiteringDelayMs\":null,\"deliveryDelayMs\":null,\"doesNotNotify\":true,\"notifiesSilently\":false,\"logoImageUrl\":\"\",\"customEntryNotificationTitle\":null,\"customEntryNotificationMessage\":null},{\"lat\":51.6972904,\"lng\":-0.19229129999997,\"radiusKm\":0.1,\"deviceUid\":\"ClientCode-535987-OffersAppGooglePlaceIdChIJ_1tSV0w9dkgRfA4FGrUvg1w\",\"scheduleId\":5203,\"loiteringDelayMs\":null,\"deliveryDelayMs\":null,\"doesNotNotify\":true,\"notifiesSilently\":false,\"logoImageUrl\":\"\",\"customEntryNotificationTitle\":null,\"customEntryNotificationMessage\":null},{\"lat\":51.7024081,\"lng\":-0.19033760000002,\"radiusKm\":0.1,\"deviceUid\":\"OffersAppGooglePlaceIdChIJ4Z0220o9dkgRUGCDnJM7OPA\",\"scheduleId\":5203,\"loiteringDelayMs\":null,\"deliveryDelayMs\":null,\"doesNotNotify\":true,\"notifiesSilently\":false,\"logoImageUrl\":\"\",\"customEntryNotificationTitle\":null,\"customEntryNotificationMessage\":null},{\"lat\":51.6939179,\"lng\":-0.18135410000002,\"radiusKm\":0.1,\"device")
        } catch {
            XCTFail("\(error)")
        }
    }

    func test_applicationDidFinishLaunchingWithOptions_no_data() {
        service.application(UIApplication.shared, didFinishLaunchingWithOptions: nil)
    }

    func test_applicationDidFinishLaunchingWithOptions_invalid_data() {
        service.application(UIApplication.shared, didFinishLaunchingWithOptions: [:])
    }

    func test_applicationDidFinishLaunchingWithOptions_update_message_data() {
        guard let data = FileLoader.loadTestData(filename: "single_message") else {
            XCTFail("Where is the test data")
            return
        }

        var json: [UIApplication.LaunchOptionsKey: Any] = [:]
        do {
            let pushData = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: AnyObject]
            json = [UIApplication.LaunchOptionsKey.remoteNotification: pushData]
        } catch {
            XCTFail("\(error)")
        }

        service.application(UIApplication.shared, didFinishLaunchingWithOptions: json)
    }

    func test_applicationDidFinishLaunchingWithOptions_multiple_messages_data() {
        guard let data = FileLoader.loadTestData(filename: "example-nearby-geofences") else {
            XCTFail("Where's my test data?")
            return
        }

        guard let fenceData = parser.parseNearbyFences(jsonData: data) else {
            XCTFail("Where's my test data?")
            return
        }

        cache.listingCache.replaceCache(fenceData)

        guard
            let data1 = FileLoader.loadTestData(filename: "part_1_of_split_message"),
            let data2 = FileLoader.loadTestData(filename: "part_2_of_split_message")
        else {
            XCTFail("Where is the test data")
            return
        }

        XCTAssertEqual(cache.fencesCache.regions().count, 13)
        XCTAssertEqual(cache.listingCache.schedules().count, 4)

        do {
            let pushData = try JSONSerialization.jsonObject(with: data2, options: .allowFragments) as! [String: AnyObject]
            let json = [UIApplication.LaunchOptionsKey.remoteNotification: pushData]
            service.application(UIApplication.shared, didFinishLaunchingWithOptions: json)

            let pushData2 = try JSONSerialization.jsonObject(with: data1, options: .allowFragments) as! [String: AnyObject]
            let json2 = [UIApplication.LaunchOptionsKey.remoteNotification: pushData2]
            service.application(UIApplication.shared, didFinishLaunchingWithOptions: json2)
        } catch {
            XCTFail("\(error)")
        }

        XCTAssertEqual(cache.fencesCache.regions().count, 14)
        XCTAssertEqual(cache.listingCache.schedules().count, 5)
    }

    func test_decoding_GeoOffersPushNotificationDataUpdate() {
        guard let listingData = FileLoader.loadTestData(filename: "example-nearby-geofences") else {
            XCTFail("Where's my test data?")
            return
        }

        guard let fenceData = parser.parseNearbyFences(jsonData: listingData) else {
            XCTFail("Where's my test data?")
            return
        }

        cache.listingCache.replaceCache(fenceData)

        guard let data = FileLoader.loadTestData(filename: "push_notification_final_message_data") else {
            XCTFail("Where is the test data")
            return
        }

        do {
            let decoder = JSONDecoder()
            let object = try decoder.decode(GeoOffersPushNotificationDataUpdate.self, from: data)
            XCTAssertEqual(object.type, "REWARD_REMOVED_ADDED_OR_EDITED")
            XCTAssertEqual(object.scheduleID, 5203)
            XCTAssertEqual(object.schedule.scheduleID, 5203)
            XCTAssertEqual(object.schedule.campaignID, 4564)
            XCTAssertEqual(object.regions.count, 7)
        } catch {
            XCTFail("\(error)")
        }
    }

    func test_geoOffersPushData_isOutOfDate() {
        let validOffer = GeoOffersPushData(message: "", totalParts: 1, scheduleID: 1234, messageIndex: 0, messageID: "messageid1234", timestamp: Date().timeIntervalSince1970 * 1000)
        let outOfDateOffer = GeoOffersPushData(message: "", totalParts: 1, scheduleID: 1234, messageIndex: 0, messageID: "messageid1234", timestamp: Date().addingTimeInterval(-(Double.oneDaySeconds * 2)).timeIntervalSince1970 * 1000)

        XCTAssertFalse(validOffer.isOutOfDate)
        XCTAssertTrue(outOfDateOffer.isOutOfDate)
    }

    func test_applicationDidReceiveRemoteNotification_no_update_message_data() {
        let json: [String: AnyObject] = [:]

        service.application(UIApplication.shared, didReceiveRemoteNotification: json) { result in
            XCTAssertEqual(result, .failed)
        }
    }

    func test_applicationDidReceiveRemoteNotification_invalid_update_message_data() {
        let json: [AnyHashable: Any] = [["Hello", "world"]: ["foo", "bar"]]

        service.application(UIApplication.shared, didReceiveRemoteNotification: json) { result in
            XCTAssertEqual(result, .failed)
        }
    }

    func test_setting_handleEventsForBackgroundURLSession() {
        var result = false

        service.application(UIApplication.shared, handleEventsForBackgroundURLSession: "test_session_id") {
            result = true
        }
        XCTAssertNotNil(apiService.backgroundSessionCompletionHandler)
        apiService.backgroundSessionCompletionHandler?()
        XCTAssertTrue(result)
    }

    func test_applicationDidReceiveRemoteNotification_update_message_data() {
        guard let data = FileLoader.loadTestData(filename: "single_message") else {
            XCTFail("Where is the test data")
            return
        }

        var json: [String: AnyObject] = [:]
        do {
            json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: AnyObject]
        } catch {
            XCTFail("\(error)")
        }

        service.application(UIApplication.shared, didReceiveRemoteNotification: json) { result in
            XCTAssertEqual(result, .newData)
        }
    }

    func test_applicationDidReceiveRemoteNotification_corrupt_message_data() {
        guard let data = FileLoader.loadTestData(filename: "single_message_corrupt") else {
            XCTFail("Where is the test data")
            return
        }

        var json: [String: AnyObject] = [:]
        do {
            json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: AnyObject]
        } catch {
            XCTFail("\(error)")
        }

        service.application(UIApplication.shared, didReceiveRemoteNotification: json) { result in
            XCTAssertEqual(result, .failed)
        }
    }
}

extension GeoOffersPushDataTests: GeoOffersSDKServiceDelegate {
    func hasAvailableOffers() {
        delegateHasAvailableOffersCalled = true
    }
}
