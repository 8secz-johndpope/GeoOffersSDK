//  Copyright © 2019 Zappit. All rights reserved.

import CoreLocation
@testable import GeoOffersSDK

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
