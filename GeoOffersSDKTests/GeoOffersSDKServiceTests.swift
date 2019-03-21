//  Copyright © 2019 Zappit. All rights reserved.

import CoreLocation
@testable import GeoOffersSDK
import UIKit
import UserNotifications
import XCTest

class MockGeoOffersNotificationService: GeoOffersNotificationServiceDefault {
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

class MockGeoOffersAPIService: GeoOffersAPIService {
    var backgroundSessionCompletionHandler: (() -> Void)?
    private(set) var pollForNearbyOffersCalled: Bool = false
    private(set) var registerCalled: Bool = false
    private(set) var updateCalled: Bool = false
    private(set) var deleteCalled: Bool = false
    private(set) var trackCalled: Bool = false
    private(set) var trackEventsCalled: Bool = false
    private(set) var countdownsStarted: Bool = false

    var nearbyData: Data?
    var responseError: Error?

    func countdownsStarted(hashes _: [String], completionHandler: GeoOffersNetworkResponse?) {
        countdownsStarted = true
    }

    func pollForNearbyOffers(latitude _: Double, longitude _: Double, completionHandler: @escaping GeoOffersNetworkResponse) {
        pollForNearbyOffersCalled = true
        if let error = responseError {
            completionHandler(.failure(error))
        } else {
            completionHandler(.dataTask(nearbyData))
        }
    }

    func register(pushToken _: String, latitude _: Double, longitude _: Double, clientID: Int, completionHandler: GeoOffersNetworkResponse?) {
        registerCalled = true
        if let error = responseError {
            completionHandler?(.failure(error))
        } else {
            completionHandler?(.success)
        }
    }

    func update(pushToken _: String, with _: String, completionHandler: GeoOffersNetworkResponse?) {
        updateCalled = true
        if let error = responseError {
            completionHandler?(.failure(error))
        } else {
            completionHandler?(.success)
        }
    }

    func delete(scheduleID _: Int) {
        deleteCalled = true
    }

    func track(event _: GeoOffersTrackingEvent) {
        trackCalled = true
    }

    func track(events _: [GeoOffersTrackingEvent]) {
        trackEventsCalled = true
    }
}

class GeoOffersSDKServiceTests: XCTestCase {
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
    private lazy var cacheService: GeoOffersCacheServiceDefault = {
        GeoOffersCacheServiceDefault(apiService: mockAPIService)
    }()

    private lazy var mockCacheService: MockGeoOffersCacheServiceDefault = {
        MockGeoOffersCacheServiceDefault(apiService: mockAPIService)
    }()

    private var service: GeoOffersSDKService!
    private var serviceWithMockAPI: GeoOffersSDKService!
    private var firebaseWrapper = MockGeoOffersFirebaseWrapper()

    fileprivate var delegateHasAvailableOffersCalled = false

    override func setUp() {
        configuration = GeoOffersConfigurationDefault(registrationCode: "TestID", authToken: UUID().uuidString, testing: true, minimumRefreshWaitTime: 0, minimumDistance: 0)

        locationManager.canMonitorForRegions = true
        locationManager.hasLocationPermission = true
        locationService = GeoOffersLocationService(latestLocation: nil, locationManager: locationManager)

        notificationService = MockGeoOffersNotificationService(notificationCenter: notificationCenter)

        apiService = GeoOffersAPIServiceDefault(configuration: configuration, session: session)
        session.testDelegate = apiService as? URLSessionDelegate
        let dataParser = GeoOffersDataParser()
        presentationService = GeoOffersPresenterDefault(configuration: configuration, locationService: locationService, cacheService: cacheService, dataParser: dataParser)

        service = GeoOffersSDKServiceDefault(
            configuration: configuration,
            notificationService: notificationService,
            locationService: locationService,
            apiService: apiService,
            presentationService: presentationService,
            dataParser: dataParser,
            cacheService: cacheService,
            firebaseWrapper: firebaseWrapper
        )

        serviceWithMockAPI = GeoOffersSDKServiceDefault(
            configuration: configuration,
            notificationService: notificationService,
            locationService: locationService,
            apiService: mockAPIService,
            presentationService: presentationService,
            dataParser: dataParser,
            cacheService: mockCacheService,
            firebaseWrapper: firebaseWrapper
        )

        service.delegate = self
        serviceWithMockAPI.delegate = self
    }

    override func tearDown() {
        configuration.pushToken = nil
        configuration.pendingPushTokenRegistration = nil
    }

    func test_load_test_push_token() {
        guard let deviceToken = tokenData else {
            XCTFail("Could not load file")
            return
        }
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        XCTAssert(!token.isEmpty, "Invalid token")
        XCTAssertEqual(token, testPushToken)
    }

    func test_default_initialiser() {
        let notificationCenter = MockUNUserNotificationCenter()
        let service = GeoOffersSDKServiceDefault(configuration: configuration, userNotificationCenter: notificationCenter)
        XCTAssertNotNil(service)
    }

    func test_requestPushNotificationPermissions() {
        service.requestPushNotificationPermissions()
        XCTAssert(notificationCenter.requestAuthorizationCalled, "Didn't call method")
    }

    func test_requestLocationPermissions() {
        service.requestLocationPermissions()
        XCTAssert(locationManager.requestAlwaysAuthorizationCalled, "Didn't call method")
    }

    func test_applicationDidBecomeActive() {
        initialiseLastLocation()
        locationService.delegate?.userDidMoveSignificantDistance()

        service.applicationDidBecomeActive(UIApplication.shared)
        XCTAssert(notificationCenter.removeAllPendingNotificationRequestsCalled, "Didn't call method")
        XCTAssert(notificationCenter.removeAllDeliveredNotificationsCalled, "Didn't call method")
    }

    func test_retrieveNearbyGeoFences_with_network_error() {
        initialiseLastLocation()
        locationService.delegate?.userDidMoveSignificantDistance()
        session.responseError = TestErrors.retrieveNearbyFencesFailed

        service.applicationDidBecomeActive(UIApplication.shared)
        XCTAssert(notificationCenter.removeAllPendingNotificationRequestsCalled, "Didn't call method")
        XCTAssert(notificationCenter.removeAllDeliveredNotificationsCalled, "Didn't call method")
    }

    func test_retrieveNearbyGeoFences_with_network_error_request_cancelled() {
        initialiseLastLocation()
        locationService.delegate?.userDidMoveSignificantDistance()
        session.responseError = NSError(domain: "com.geoofferssdk", code: -999, userInfo: nil)

        service.applicationDidBecomeActive(UIApplication.shared)
        XCTAssert(notificationCenter.removeAllPendingNotificationRequestsCalled, "Didn't call method")
        XCTAssert(notificationCenter.removeAllDeliveredNotificationsCalled, "Didn't call method")
    }

    func test_retrieveNearbyGeoFences_with_invalid_data() {
        initialiseLastLocation()
        locationService.delegate?.userDidMoveSignificantDistance()
        session.responseData = Data()

        service.applicationDidBecomeActive(UIApplication.shared)
        XCTAssert(notificationCenter.removeAllPendingNotificationRequestsCalled, "Didn't call method")
        XCTAssert(notificationCenter.removeAllDeliveredNotificationsCalled, "Didn't call method")
    }

    func test_retrieveNearbyGeoFences_with_valid_data() {
        initialiseLastLocation()
        locationService.delegate?.userDidMoveSignificantDistance()
        session.responseData = FileLoader.loadTestData(filename: "example-nearby-geofences")

        service.applicationDidBecomeActive(UIApplication.shared)
        XCTAssert(notificationCenter.removeAllPendingNotificationRequestsCalled, "Didn't call method")
        XCTAssert(notificationCenter.removeAllDeliveredNotificationsCalled, "Didn't call method")

        let schedules = cacheService.schedules(for: 5129, scheduleDeviceID: "Testing")
        XCTAssertEqual(schedules.count, 1)
    }

    func test_presentOfferScreen() {
        let viewController = service.buildOfferListViewController()
        XCTAssertNotNil(viewController)
    }

    func test_locationDelegate_userDidMoveSignificantDistance() {
        GeoOffersSDKUserDefaults.shared.lastKnownLocation = nil
        initialiseLastLocation()
        locationService.delegate?.userDidMoveSignificantDistance()
        XCTAssert(GeoOffersSDKUserDefaults.shared.lastKnownLocation != nil, "Should have a saved lastKnownLocation")
    }

    func test_locationDelegate_didExitRegion() {
        initialiseLastLocation()
        locationService.delegate?.didExitRegion(testIdentifier)
        XCTAssertTrue(notificationService.removeNotificationCalled)
        XCTAssertTrue(mockCacheService.removePendingOfferCalled)
    }

    func test_locationDelegate_didEnterRegion() {
        initialiseLastLocation()
        locationService.delegate?.didEnterRegion(testIdentifier)
        XCTAssertTrue(mockAPIService.pollForNearbyOffersCalled)
        XCTAssertTrue(notificationService.removeNotificationCalled)
        XCTAssertTrue(mockCacheService.removePendingOfferCalled)
        XCTAssertTrue(mockCacheService.regionWithIdentifierCalled)

        XCTAssertFalse(notificationService.sendNotificationCalled)
        XCTAssertFalse(mockCacheService.addPendingOfferCalled)
        XCTAssertFalse(mockAPIService.trackCalled)
    }

    func test_findValidRegion_with_region_no_valid_schedule() {
        initialiseLastLocation()
        locationService.delegate?.didEnterRegion(testIdentifier)
        XCTAssertTrue(mockAPIService.pollForNearbyOffersCalled)
        XCTAssertTrue(notificationService.removeNotificationCalled)
        XCTAssertTrue(mockCacheService.removePendingOfferCalled)
        XCTAssertTrue(mockCacheService.regionWithIdentifierCalled)

        XCTAssertFalse(notificationService.sendNotificationCalled)
        XCTAssertFalse(mockCacheService.addPendingOfferCalled)
        XCTAssertFalse(mockAPIService.trackCalled)
    }

    private func loadNearbyRegionsIntoMockCacheService() {
        guard let data = FileLoader.loadTestData(filename: "example-nearby-geofences-multi-delivered") else {
            XCTFail("Where's my test data?")
            return
        }

        let parser = GeoOffersDataParser()
        guard let fenceData = parser.parseNearbyFences(jsonData: data) else {
            XCTFail("Where's my test data?")
            return
        }

        mockCacheService.replaceCache(fenceData)
    }

    func test_findValidRegion_with_region_valid_schedule() {
        initialiseLastLocation()
        loadNearbyRegionsIntoMockCacheService()
        locationService.delegate?.didEnterRegion("5c06971bc93f6")
        XCTAssertTrue(mockAPIService.pollForNearbyOffersCalled)
        XCTAssertTrue(notificationService.removeNotificationCalled)
        XCTAssertTrue(mockCacheService.removePendingOfferCalled)
        XCTAssertTrue(mockCacheService.regionWithIdentifierCalled)

        XCTAssertTrue(notificationService.sendNotificationCalled)
        XCTAssertTrue(mockCacheService.addPendingOfferCalled)
        XCTAssertTrue(mockAPIService.trackCalled)
    }

    func test_findValidRegion_with_region_invalid_schedule() {
        initialiseLastLocation()
        loadNearbyRegionsIntoMockCacheService()
        locationService.delegate?.didEnterRegion("5c0f9a4443e23")
        XCTAssertTrue(mockAPIService.pollForNearbyOffersCalled)
        XCTAssertTrue(notificationService.removeNotificationCalled)
        XCTAssertTrue(mockCacheService.removePendingOfferCalled)
        XCTAssertTrue(mockCacheService.regionWithIdentifierCalled)

        XCTAssertFalse(notificationService.sendNotificationCalled)
        XCTAssertFalse(mockCacheService.addPendingOfferCalled)
        XCTAssertFalse(mockAPIService.trackCalled)
    }

    func test_didRegisterForRemoteNotificationsWithDeviceToken_for_already_submitted_token() {
        let token = testPushToken
        guard let testData = tokenData else {
            XCTFail("Failed to create test token")
            return
        }

        configuration.pushToken = token
        serviceWithMockAPI.application(UIApplication.shared, didRegisterForRemoteNotificationsWithDeviceToken: testData)
        XCTAssertFalse(mockAPIService.registerCalled)
        XCTAssertFalse(mockAPIService.updateCalled)
    }

    func test_performFetchWithCompletionHandler() {
        locationManager.delegate?.locationManager?(CLLocationManager(), didUpdateLocations: [CLLocation(latitude: testLocation.latitude, longitude: testLocation.longitude)])
        serviceWithMockAPI.application(UIApplication.shared) { _ in
        }
        XCTAssertTrue(mockAPIService.pollForNearbyOffersCalled)
    }

    func test_checkForPendingPushRegistration_with_no_pending_token() {
        serviceWithMockAPI.applicationDidBecomeActive(UIApplication.shared)
        XCTAssertNil(configuration.pushToken)
        XCTAssertNil(configuration.pendingPushTokenRegistration)
    }

    func test_checkForPendingPushRegistration_with_pending_token_no_location() {
        configuration.pendingPushTokenRegistration = testPushToken
        serviceWithMockAPI.applicationDidBecomeActive(UIApplication.shared)
        XCTAssertNil(configuration.pushToken)
        XCTAssertEqual(configuration.pendingPushTokenRegistration, testPushToken)
    }

    func test_checkForPendingPushRegistration_with_pending_token_location() {
        initialiseLastLocation()
        configuration.pendingPushTokenRegistration = testPushToken
        serviceWithMockAPI.applicationDidBecomeActive(UIApplication.shared)
        XCTAssertNotEqual(configuration.pushToken, testPushToken)
        XCTAssertNotNil(configuration.pendingPushTokenRegistration)
    }

    func test_notifyOfPendingOffers_no_pending_offers() {
        serviceWithMockAPI.applicationDidBecomeActive(UIApplication.shared)
        XCTAssertFalse(delegateHasAvailableOffersCalled)
    }

    func test_notifyOfPendingOffers_pending_offers() {
        let mockCache = mockCacheService
        initialiseLastLocation()
        mockAPIService.nearbyData = FileLoader.loadTestData(filename: "example-nearby-geofences")
        serviceWithMockAPI.applicationDidBecomeActive(UIApplication.shared)
        var offers = [GeoOffersPendingOffer]()
        for schedule in mockCache.deliveredSchedules() {
            let offer = GeoOffersPendingOffer(scheduleID: schedule.scheduleID, scheduleDeviceID: schedule.scheduleDeviceID, notificationDwellDelay: 0, createdDate: Date())
            offers.append(offer)
        }
        mockCache.replaceOffers(offers: offers)

        serviceWithMockAPI.applicationDidBecomeActive(UIApplication.shared)
        XCTAssertTrue(delegateHasAvailableOffersCalled)
        XCTAssertEqual(offers.count, mockCache.offers().count)
    }

    private func initialiseLastLocation() {
        let location = CLLocation(latitude: testLocation.latitude, longitude: testLocation.longitude)
        locationManager.delegate?.locationManager?(CLLocationManager(), didUpdateLocations: [location])
    }
}

extension GeoOffersSDKServiceTests: GeoOffersSDKServiceDelegate {
    func hasAvailableOffers() {
        delegateHasAvailableOffersCalled = true
    }
}
