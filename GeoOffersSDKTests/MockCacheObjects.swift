//  Copyright © 2019 Zappit. All rights reserved.

import Foundation
@testable import GeoOffersSDK

class TestCacheHelper {
    let cache: GeoOffersCache
    let offersCache: MockGeoOffersOffersCache
    let notificationCache: MockGeoOffersNotificationCache
    let regionCache: MockGeoOffersRegionCache
    let listingCache: MockGeoOffersListingCache
    let webViewCache: MockGeoOffersWebViewCache
    let trackingCache: MockGeoOffersTrackingCache

    init() {
        cache = GeoOffersCache(shouldCacheToDisk: false)
        trackingCache = MockGeoOffersTrackingCache(cache: cache)
        regionCache = MockGeoOffersRegionCache(cache: cache)
        offersCache = MockGeoOffersOffersCache(cache: cache, trackingCache: trackingCache)
        notificationCache = MockGeoOffersNotificationCache(cache: cache)
        listingCache = MockGeoOffersListingCache(cache: cache, offersCache: offersCache)
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

class MockGeoOffersTrackingCache: GeoOffersTrackingCache {
    var addCalled = false
    var hasCachedEventsCalled = false
    var popCachedEventsCalled = false
    
    override func add(_ events: [GeoOffersTrackingEvent]) {
        addCalled = true
        super.add(events)
    }
    
    override func hasCachedEvents() -> Bool {
        hasCachedEventsCalled = true
        return super.hasCachedEvents()
    }
    
    override func popCachedEvents(n: Int = 50) -> [GeoOffersTrackingEvent] {
        popCachedEventsCalled = true
        return super.popCachedEvents(n: n)
    }
}

class MockGeoOffersRegionCache: GeoOffersRegionCache {
    var addCalled = false
    var removeCalled = false
    var existsCalled = false
    var allCalled = false

    override func add(_ region: GeoOffersGeoFence) {
        addCalled = true
        super.add(region)
    }
    
    override func remove(_ region: GeoOffersGeoFence) {
        removeCalled = true
        super.remove(region)
    }
    
    override func exists(_ region: GeoOffersGeoFence) -> GeoOffersRegionCacheItem? {
        existsCalled = true
        return super.exists(region)
    }
    
    override func all() -> [GeoOffersRegionCacheItem] {
        allCalled = true
        return super.all()
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

    override func replaceCache(_ geoFenceData: GeoOffersListing) {
        replaceCacheCalled = true
        super.replaceCache(geoFenceData)
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
}
