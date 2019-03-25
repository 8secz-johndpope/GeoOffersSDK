//  Copyright © 2019 Zappit. All rights reserved.

import Foundation
@testable import GeoOffersSDK

class MockGeoOffersAPIService: GeoOffersAPIServiceProtocol {
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
