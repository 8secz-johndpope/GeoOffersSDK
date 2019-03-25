//  Copyright © 2019 Zappit. All rights reserved.

import Foundation
@testable import GeoOffersSDK

class TestCacheHelper {
    let cache: GeoOffersCache
    let offersCache: MockGeoOffersOffersCache
    let notificationCache: MockGeoOffersNotificationCache
    let fencesCache: MockGeoOffersGeoFencesCache
    let listingCache: MockGeoOffersListingCache
    let webViewCache: MockGeoOffersWebViewCache
    
    init(apiService: GeoOffersAPIServiceProtocol) {
        cache = GeoOffersCache.init(shouldCacheToDisk: false)
        fencesCache = MockGeoOffersGeoFencesCache(cache: cache)
        offersCache = MockGeoOffersOffersCache(cache: cache, fencesCache: fencesCache, apiService: apiService)
        notificationCache = MockGeoOffersNotificationCache(cache: cache)
        listingCache = MockGeoOffersListingCache(cache: cache)
        webViewCache = MockGeoOffersWebViewCache(cache: cache, listingCache: listingCache, offersCache: offersCache)
    }
}

class MockGeoOffersNotificationCache: GeoOffersNotificationCache {
    var addCalled = false
    var countCalled = false
    var messagesCalled = false
    var removeCalled = false
    var removeAllPushMessagesCalled = false
    var updateCacheCalled = false
    
    override func add(_ message: GeoOffersPushData) {
        addCalled = true
        super.add(message)
    }
    
    override func count(_ messageID: String) -> Int {
        countCalled = true
        return super.count(messageID)
    }
    
    override func messages(_ messageID: String) -> [GeoOffersPushData] {
        messagesCalled = true
        return super.messages(messageID)
    }
    
    override func remove(_ messageID: String) {
        removeCalled = true
        super.remove(messageID)
    }
    
    override func removeAllPushMessages() {
        removeAllPushMessagesCalled = true
        super.removeAllPushMessages()
    }
    
    override func updateCache(pushData: GeoOffersPushNotificationDataUpdate) {
        updateCacheCalled = true
        super.updateCache(pushData: pushData)
    }
}

class MockGeoOffersWebViewCache: GeoOffersWebViewCache {
    var buildCouponRequestJsonCalled = false
    var buildListingRequestJsonCalled = false
    var buildAlreadyDeliveredOfferJsonCalled = false
    
    override func buildCouponRequestJson(scheduleID: Int) -> String {
        buildCouponRequestJsonCalled = true
        return super.buildCouponRequestJson(scheduleID: scheduleID)
    }
    
    override func buildListingRequestJson() -> String {
        buildListingRequestJsonCalled = true
        return super.buildListingRequestJson()
    }
    
    override func buildAlreadyDeliveredOfferJson() -> String {
        buildAlreadyDeliveredOfferJsonCalled = true
        return super.buildAlreadyDeliveredOfferJson()
    }
}

class MockGeoOffersGeoFencesCache: GeoOffersGeoFencesCache {
    var regionsCalled = false
    var regionWithIdentifierCalled = false
    var fencesNearCalled = false
    
    override func regions() -> [GeoOffersGeoFence] {
        regionsCalled = true
        return super.regions()
    }
    
    override func region(with identifier: String) -> [GeoOffersGeoFence] {
        regionWithIdentifierCalled = true
        return super.region(with: identifier)
    }
    
    override func fencesNear(latitude: Double, longitude: Double) -> [GeoOffersGeoFence] {
        fencesNearCalled = true
        return super.fencesNear(latitude: latitude, longitude: longitude)
    }
}

class MockGeoOffersListingCache: GeoOffersListingCache {
    var deliveredSchedulesCalled = false
    var clearCacheCalled = false
    var forcePendingChangesCalled = false
    var listingCalled = false
    var schedulesCalled = false
    var replaceCacheCalled = false
    var schedulesForScheduleIDCalled = false
    var deliveredScheduleForScheduleIDCalled = false
    
    override func deliveredSchedules() -> [GeoOffersDeliveredSchedule] {
        deliveredSchedulesCalled = true
        return super.deliveredSchedules()
    }
    
    override func clearCache() {
        clearCacheCalled = true
        super.clearCache()
    }
    
    override func forcePendingChanges() {
        forcePendingChangesCalled = true
        super.forcePendingChanges()
    }
    
    override func listing() -> GeoOffersListing? {
        listingCalled = true
        return super.listing()
    }
    
    override func schedules() -> [GeoOffersSchedule] {
        schedulesCalled = true
        return super.schedules()
    }
    
    override func replaceCache(_ geoFenceData: GeoOffersListing) {
        replaceCacheCalled = true
        super.replaceCache(geoFenceData)
    }
    
    override func schedules(for scheduleID: Int, scheduleDeviceID: String) -> [GeoOffersSchedule] {
        schedulesForScheduleIDCalled = true
        return super.schedules(for: scheduleID, scheduleDeviceID: scheduleDeviceID)
    }
    
    override func deliveredSchedule(for scheduleID: Int, scheduleDeviceID: String) -> Bool {
        deliveredScheduleForScheduleIDCalled = true
        return super.deliveredSchedule(for: scheduleID, scheduleDeviceID: scheduleDeviceID)
    }
}

class MockGeoOffersOffersCache: GeoOffersOffersCache {
    var offersCalled = false
    var addPendingOfferCalled = false
    var removePendingOfferCalled = false
    var hasPendingOffersCalled = false
    var hasOffersCalled = false
    var pendingOfferCalled = false
    var clearPendingOffersCalled = false
    var refreshPendingOffersCalled = false
    
    override func offers() -> [GeoOffersPendingOffer] {
        offersCalled = true
        return super.offers()
    }
    
    override func addPendingOffer(
        scheduleID: Int,
        scheduleDeviceID: String,
        latitude: Double,
        longitude: Double,
        notificationDwellDelayMs: Double
        ) {
        addPendingOfferCalled = true
        super.addPendingOffer(scheduleID: scheduleID, scheduleDeviceID: scheduleDeviceID, latitude: latitude, longitude: longitude, notificationDwellDelayMs: notificationDwellDelayMs)
    }
    
    override func removePendingOffer(identifier: String) {
        removePendingOfferCalled = true
        super.removePendingOffer(identifier: identifier)
    }
    
    override func hasPendingOffers() -> Bool {
        hasPendingOffersCalled = true
        return super.hasPendingOffers()
    }
    
    override func hasOffers() -> Bool {
        hasOffersCalled = true
        return super.hasOffers()
    }
    
    override func pendingOffer(_ identifier: String) -> GeoOffersPendingOffer? {
        pendingOfferCalled = true
        return super.pendingOffer(identifier)
    }
    
    override func clearPendingOffers() {
        clearPendingOffersCalled = true
        super.clearPendingOffers()
    }
    
    override func refreshPendingOffers() {
        refreshPendingOffersCalled = true
        super.refreshPendingOffers()
    }
}
