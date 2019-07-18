//  Copyright © 2019 Zappit. All rights reserved.

import CoreLocation
@testable import GeoOffersSDK
import UIKit
import UserNotifications
import XCTest

class GeoOffersSDKServiceTests: XCTestCase {
    private let locationManager = MockLocationManager()
    private let testLocation = CLLocationCoordinate2D(latitude: 51.506012, longitude: -0.463213)
    private let testRadius: Double = 1000
    private let testIdentifier = "Test region 1"
    private let testPushToken = "a4ae72cf7f10b4819b1d0a2196ae4013ff55bd7f95b323c6986e1c1523905b17"
    private var tokenData: Data? {
        return FileLoader.loadTestData(filename: "PushToken", withExtension: "data")
    }

    private var notificationCenter = MockUNUserNotificationCenter()

    private var configuration: GeoOffersInternalConfiguration!
    private var notificationService: MockGeoOffersNotificationService!
    private var locationService: GeoOffersLocationService!
    private var apiService: GeoOffersAPIServiceProtocol!
    private var mockAPIService = MockGeoOffersAPIService()
    private var presentationService: GeoOffersPresenterProtocol!
    private var session = MockURLSession()
    private var cache: TestCacheHelper!
    private var dataProcessor: GeoOffersDataProcessor!
    private var appConfig: GeoOffersConfiguration!

    private var service: GeoOffersSDKServiceProtocol!
    private var serviceWithMockAPI: GeoOffersSDKServiceProtocol!
    private var firebaseWrapper = MockGeoOffersFirebaseWrapper()

    fileprivate var delegateHasAvailableOffersCalled = false

    override func setUp() {
        appConfig = GeoOffersConfiguration(registrationCode: "TestID", authToken: UUID().uuidString, testing: true, minimumRefreshWaitTime: 0, minimumDistance: 0)
        configuration = GeoOffersInternalConfiguration(configuration: appConfig)

        locationManager.canMonitorForRegions = true
        locationManager.hasLocationPermission = true
        locationService = GeoOffersLocationService(latestLocation: nil, locationManager: locationManager, configuration: configuration)

        notificationService = MockGeoOffersNotificationService(notificationCenter: notificationCenter)
        cache = TestCacheHelper()
        apiService = GeoOffersAPIService(configuration: configuration, session: session, trackingCache: cache.trackingCache)
        session.testDelegate = apiService as? URLSessionDelegate
        let dataParser = GeoOffersPushNotificationProcessor(notificationCache: cache.notificationCache, listingCache: cache.listingCache)
        presentationService = GeoOffersPresenter(configuration: configuration, locationService: locationService, cacheService: cache.webViewCache, trackingCache: cache.trackingCache, apiService: mockAPIService)

        dataProcessor = GeoOffersDataProcessor(
            offersCache: cache.offersCache,
            listingCache: cache.listingCache,
            sendNotificationCache: cache.sendNotificationCache,
            enteredRegionCache: cache.enteredRegionCache,
            notificationService: notificationService,
            apiService: mockAPIService,
            trackingCache: cache.trackingCache
        )

        service = GeoOffersSDKService(
            configuration: appConfig,
            notificationService: notificationService,
            locationService: locationService,
            apiService: apiService,
            presentationService: presentationService,
            dataParser: dataParser,
            firebaseWrapper: firebaseWrapper,
            offersCache: cache.offersCache,
            notificationCache: cache.notificationCache,
            listingCache: cache.listingCache,
            dataProcessor: dataProcessor
        )

        serviceWithMockAPI = GeoOffersSDKService(
            configuration: appConfig,
            notificationService: notificationService,
            locationService: locationService,
            apiService: mockAPIService,
            presentationService: presentationService,
            dataParser: dataParser,
            firebaseWrapper: firebaseWrapper,
            offersCache: cache.offersCache,
            notificationCache: cache.notificationCache,
            listingCache: cache.listingCache,
            dataProcessor: dataProcessor
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
        let service = GeoOffersSDKService(configuration: appConfig, userNotificationCenter: notificationCenter)
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
        XCTAssert(notificationCenter.removeAllDeliveredNotificationsCalled, "Didn't call method")
    }

    func test_retrieveNearbyGeoFences_with_network_error() {
        initialiseLastLocation()
        locationService.delegate?.userDidMoveSignificantDistance()
        session.responseError = TestErrors.retrieveNearbyFencesFailed

        service.applicationDidBecomeActive(UIApplication.shared)
        XCTAssert(notificationCenter.removeAllDeliveredNotificationsCalled, "Didn't call method")
    }

    func test_retrieveNearbyGeoFences_with_network_error_request_cancelled() {
        initialiseLastLocation()
        locationService.delegate?.userDidMoveSignificantDistance()
        session.responseError = NSError(domain: "com.geoofferssdk", code: -999, userInfo: nil)

        service.applicationDidBecomeActive(UIApplication.shared)
        XCTAssert(notificationCenter.removeAllDeliveredNotificationsCalled, "Didn't call method")
    }

    func test_retrieveNearbyGeoFences_with_invalid_data() {
        initialiseLastLocation()
        locationService.delegate?.userDidMoveSignificantDistance()
        session.responseData = Data()

        service.applicationDidBecomeActive(UIApplication.shared)
        XCTAssert(notificationCenter.removeAllDeliveredNotificationsCalled, "Didn't call method")
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

    func test_locationDelegate_didEnterRegion() {
        initialiseLastLocation()
        locationService.delegate?.didEnterRegion(testIdentifier)
        XCTAssertTrue(mockAPIService.pollForNearbyOffersCalled)

        XCTAssertFalse(notificationService.sendNotificationCalled)
        XCTAssertFalse(mockAPIService.trackCalled)
    }

    func test_findValidRegion_with_region_no_valid_schedule() {
        initialiseLastLocation()
        locationService.delegate?.didEnterRegion(testIdentifier)
        XCTAssertTrue(mockAPIService.pollForNearbyOffersCalled)

        XCTAssertFalse(notificationService.sendNotificationCalled)
        XCTAssertFalse(mockAPIService.trackCalled)
    }

    private func loadNearbyRegionsIntoMockCacheService() {
        guard let data = FileLoader.loadTestData(filename: "example-nearby-geofences-multi-delivered") else {
            XCTFail("Where's my test data?")
            return
        }

        let parser = GeoOffersPushNotificationProcessor(notificationCache: cache.notificationCache, listingCache: cache.listingCache)
        guard parser.parseNearbyFences(jsonData: data) != nil else {
            XCTFail("Where's my test data?")
            return
        }
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
