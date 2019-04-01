//  Copyright © 2019 Zappit. All rights reserved.

import Foundation

public protocol GeoOffersOffersCacheDelegate: class {
    func offersUpdated()
}

class GeoOffersOffersCache {
    private var cache: GeoOffersCache

    weak var delegate: GeoOffersOffersCacheDelegate?

    init(cache: GeoOffersCache) {
        self.cache = cache
    }
    
    func appendDeliveredSchedules(_ deliveredSchedules: [GeoOffersDeliveredSchedule]) {
        deliveredSchedules.forEach {
            cache.cacheData.pendingOffers.removeValue(forKey: $0.scheduleID)
            cache.cacheData.offers[$0.scheduleID] = $0.scheduleID
        }
        cache.cacheUpdated()
        delegate?.offersUpdated()
    }
    
    func pendingOffers() -> [GeoOffersCacheItem] {
        return cache.cacheData.pendingOffers.reduce([]) { $0 + [$1.value] }
    }
    
    func hasOfferAlready(_ scheduleID: ScheduleID) -> Bool {
        return cache.cacheData.offers[scheduleID] != nil
    }
    
    func addPendingOffer(_ region: GeoOffersGeoFence) {
        guard !hasOfferAlready(region.scheduleID) else { return }
        cache.cacheData.pendingOffers[region.scheduleID] = GeoOffersCacheItem(region: region)
        cache.cacheUpdated()
    }
    
    func addOffer(_ scheduleID: ScheduleID) {
        cache.cacheData.pendingOffers.removeValue(forKey: scheduleID)
        cache.cacheData.offers[scheduleID] = scheduleID
        cache.cacheUpdated()
        delegate?.offersUpdated()
    }
    
    func offers() -> [ScheduleID] {
        return cache.cacheData.offers.reduce([]) { $0 + [$1.key] }
    }
}
