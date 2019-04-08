//  Copyright © 2019 Zappit. All rights reserved.

import CoreLocation
@testable import GeoOffersSDK

class MockLocationManager: GeoOffersLocationManager {
    var location: CLLocation?
    var activityType: CLActivityType = .fitness
    var allowsBackgroundLocationUpdates: Bool = false
    var desiredAccuracy: CLLocationAccuracy = kCLLocationAccuracyBest
    var distanceFilter: CLLocationDistance = 500
    private(set) var requestAlwaysAuthorizationCalled = false
    private(set) var startMonitoringSignificantLocationChangesCalled = false
    private(set) var startMonitoringCalled = false
    private(set) var stopMonitoringCalled = false
    private(set) var startUpdatingLocationCalled = false
    private(set) var allowDeferredLocationUpdatesCalled = false

    weak var delegate: CLLocationManagerDelegate?
    var monitoredRegions: Set<CLRegion> = []
    var maximumRegionMonitoringDistance: CLLocationDistance {
        return 100
    }

    var hasLocationPermission = false
    var canMonitorForRegions = false
    var canDeferLocationUpdates = false

    func allowDeferredLocationUpdates(untilTraveled _: CLLocationDistance, timeout _: TimeInterval) {
        allowDeferredLocationUpdatesCalled = true
    }

    func startUpdatingLocation() {
        startUpdatingLocationCalled = true
    }

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
