//  Copyright © 2019 Zappit. All rights reserved.

import CoreLocation
@testable import GeoOffersSDK
import XCTest

class MockLocationManager: GeoOffersLocationManager {
    var allowsBackgroundLocationUpdates: Bool = false

    private(set) var requestAlwaysAuthorizationCalled = false
    private(set) var startMonitoringSignificantLocationChangesCalled = false
    private(set) var startMonitoringCalled = false
    private(set) var stopMonitoringCalled = false

    weak var delegate: CLLocationManagerDelegate?
    var monitoredRegions: Set<CLRegion> = []
    var maximumRegionMonitoringDistance: CLLocationDistance {
        return 100
    }

    var hasLocationPermission = false
    var canMonitorForRegions = false

    func requestAlwaysAuthorization() {
        requestAlwaysAuthorizationCalled = true
    }

    func startMonitoringSignificantLocationChanges() {
        startMonitoringSignificantLocationChangesCalled = true
    }

    func startMonitoring(for _: CLRegion) {
        startMonitoringCalled = true
    }

    func stopMonitoring(for region: CLRegion) {
        stopMonitoringCalled = true
        monitoredRegions.remove(region)
    }
}

enum TestingErrors: Error {
    case monitoringDidFailFor
    case didFailWithError
}

class GeoOffersLocationServiceTests: XCTestCase {
    private var service: GeoOffersLocationService!
    private let locationManager = MockLocationManager()
    private let testLocation = CLLocationCoordinate2D(latitude: 52.4, longitude: -0.25)
    private let testRadius: Double = 1000
    private let testIdentifier = "Test region 1"

    fileprivate var delegateUserDidMoveSignificantDistanceCalled = false
    fileprivate var delegateDidEnterRegionCalled = false
    fileprivate var delegateDidExitRegionCalled = false

    override func setUp() {
        service = GeoOffersLocationService(latestLocation: nil, locationManager: locationManager)
    }

    override func tearDown() {
        service.delegate = nil
    }

    private func configureServiceWithValidLocationPermissions() {
        locationManager.canMonitorForRegions = true
        locationManager.hasLocationPermission = true
        service = GeoOffersLocationService(latestLocation: nil, locationManager: locationManager)
    }

    func test_extension_defaults() {
        let locationManager = CLLocationManager()
        XCTAssertEqual(locationManager.hasLocationPermission, CLLocationManager.authorizationStatus() == .authorizedAlways)
        XCTAssertEqual(locationManager.canMonitorForRegions, CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self))
    }

    func test_initialisation() {
        XCTAssertNotNil(service)
        XCTAssertNil(service.latestLocation)
        XCTAssertNil(service.delegate)
        XCTAssert(locationManager.startMonitoringSignificantLocationChangesCalled == false, "Didn't call method")
    }

    func test_initialisation_when_tracking_active() {
        configureServiceWithValidLocationPermissions()
        XCTAssertNil(service.latestLocation)
        XCTAssertNil(service.delegate)
        XCTAssert(locationManager.startMonitoringSignificantLocationChangesCalled, "Didn't call method")
    }

    func test_requestPermissions() {
        service.requestPermissions()
        XCTAssert(locationManager.requestAlwaysAuthorizationCalled, "Didn't call method")
    }

    func test_stopMonitoringAllRegions_with_no_regions() {
        service.stopMonitoringAllRegions()
        XCTAssert(locationManager.monitoredRegions.isEmpty, "Should be no regions being monitored")
        XCTAssert(locationManager.stopMonitoringCalled == false, "Didn't call method")
    }

    func test_stopMonitoringAllRegions_with_regions() {
        let testRegion = CLCircularRegion(center: testLocation, radius: testRadius, identifier: testIdentifier)
        locationManager.monitoredRegions.insert(testRegion)
        service.stopMonitoringAllRegions()
        XCTAssert(locationManager.monitoredRegions.isEmpty, "Should be no regions being monitored")
        XCTAssert(locationManager.stopMonitoringCalled, "Didn't call method")
    }

    func test_startMonitoringSignificantLocationChanges_with_no_permission() {
        service.startMonitoringSignificantLocationChanges()
        XCTAssert(locationManager.startMonitoringSignificantLocationChangesCalled == false, "Didn't call method")
    }

    func test_startMonitoringSignificantLocationChanges_with_permission() {
        configureServiceWithValidLocationPermissions()
        service.startMonitoringSignificantLocationChanges()
        XCTAssert(locationManager.startMonitoringSignificantLocationChangesCalled, "Didn't call method")
    }

    func test_monitor_without_location_permissions() {
        service.monitor(center: testLocation, radiusMeters: testRadius, identifier: testIdentifier, ignoreIfInside: false)
        XCTAssert(locationManager.startMonitoringCalled == false, "Didn't call method")
    }

    func test_monitor_with_location_permissions() {
        configureServiceWithValidLocationPermissions()
        service.monitor(center: testLocation, radiusMeters: testRadius, identifier: testIdentifier, ignoreIfInside: false)
        XCTAssert(locationManager.startMonitoringCalled, "Didn't call method")
    }

    func test_stopMonitoringRegion() {
        let testRegion = CLCircularRegion(center: testLocation, radius: testRadius, identifier: testIdentifier)
        locationManager.monitoredRegions.insert(testRegion)
        XCTAssert(locationManager.monitoredRegions.count == 1, "Need some regions to monitor")
        service.stopMonitoringRegion(with: testRegion.identifier + "invalid")
        XCTAssert(locationManager.monitoredRegions.count == 1, "Need some regions to monitor")
        service.stopMonitoringRegion(with: testRegion.identifier)
        XCTAssert(locationManager.monitoredRegions.isEmpty, "Should be no regions")
        XCTAssert(locationManager.stopMonitoringCalled, "Didn't call method")
    }

    func test_locationManager_delegate_didChangeAuthorization_false() {
        locationManager.delegate?.locationManager?(CLLocationManager(), didChangeAuthorization: .denied)
        XCTAssert(locationManager.startMonitoringSignificantLocationChangesCalled == false, "Didn't call method")
    }

    func test_locationManager_delegate_didChangeAuthorization_true() {
        configureServiceWithValidLocationPermissions()
        locationManager.delegate?.locationManager?(CLLocationManager(), didChangeAuthorization: .authorizedAlways)
        XCTAssert(locationManager.startMonitoringSignificantLocationChangesCalled, "Didn't call method")
    }

    func test_locationManager_delegate_didUpdateLocations_without_a_location() {
        service.delegate = self
        locationManager.delegate?.locationManager?(CLLocationManager(), didUpdateLocations: [])
        XCTAssert(delegateUserDidMoveSignificantDistanceCalled == false, "Should not call method")
    }

    func test_locationManager_delegate_didUpdateLocations_with_a_location() {
        service.delegate = self
        let location = CLLocation(latitude: testLocation.latitude, longitude: testLocation.longitude)
        locationManager.delegate?.locationManager?(CLLocationManager(), didUpdateLocations: [location])
        XCTAssert(delegateUserDidMoveSignificantDistanceCalled, "Should call method")
        XCTAssert(service.latestLocation?.latitude == location.coordinate.latitude && service.latestLocation?.longitude == location.coordinate.longitude, "Not the correct location")
    }

    func test_locationManager_delegate_didUpdateLocations_with_multiple_locations() {
        service.delegate = self
        let location = CLLocation(latitude: testLocation.latitude, longitude: testLocation.longitude)
        let location2 = CLLocation(latitude: testLocation.latitude + 5, longitude: testLocation.longitude)
        locationManager.delegate?.locationManager?(CLLocationManager(), didUpdateLocations: [location, location2])
        XCTAssert(delegateUserDidMoveSignificantDistanceCalled, "Should call method")
        XCTAssert(service.latestLocation?.latitude == location.coordinate.latitude && service.latestLocation?.longitude == location.coordinate.longitude, "Not the correct location")
    }

    func test_locationManager_delegate_monitoringDidFailFor() {
        locationManager.delegate?.locationManager?(CLLocationManager(), monitoringDidFailFor: nil, withError: TestingErrors.monitoringDidFailFor)
    }

    func test_locationManager_delegate_didFailWithError() {
        locationManager.delegate?.locationManager?(CLLocationManager(), didFailWithError: TestingErrors.didFailWithError)
    }

    func test_locationManager_delegate_didEnterRegion_not_with_circular_region() {
        service.delegate = self
        locationManager.delegate?.locationManager?(CLLocationManager(), didEnterRegion: CLRegion())
        XCTAssertFalse(delegateDidEnterRegionCalled, "Should not call method")
    }

    func test_locationManager_delegate_didEnterRegion_called_when_monitoring_region_already_in() {
        service.delegate = self
        locationManager.hasLocationPermission = true
        locationManager.canMonitorForRegions = true
        locationManager.delegate?.locationManager?(CLLocationManager(), didUpdateLocations: [CLLocation(latitude: testLocation.latitude, longitude: testLocation.longitude)])
        service.monitor(center: testLocation, radiusMeters: testRadius, identifier: testIdentifier, ignoreIfInside: false)
        XCTAssertTrue(delegateDidEnterRegionCalled, "Should call method")
    }

    func test_locationManager_delegate_didEnterRegion_with_circular_region() {
        service.delegate = self
        locationManager.delegate?.locationManager?(CLLocationManager(), didEnterRegion: CLCircularRegion(center: testLocation, radius: testRadius, identifier: testIdentifier))
        XCTAssert(delegateDidEnterRegionCalled, "Should call method")
    }

    func test_locationManager_delegate_didExitRegion_with_circular_region() {
        service.delegate = self
        locationManager.delegate?.locationManager?(CLLocationManager(), didExitRegion: CLCircularRegion(center: testLocation, radius: testRadius, identifier: testIdentifier))
        XCTAssert(delegateDidExitRegionCalled, "Should call method")
    }
}

extension GeoOffersLocationServiceTests: GeoOffersLocationServiceDelegate {
    func userDidMoveSignificantDistance() {
        delegateUserDidMoveSignificantDistanceCalled = true
    }

    func didEnterRegion(_: String) {
        delegateDidEnterRegionCalled = true
    }

    func didExitRegion(_: String) {
        delegateDidExitRegionCalled = true
    }
}
