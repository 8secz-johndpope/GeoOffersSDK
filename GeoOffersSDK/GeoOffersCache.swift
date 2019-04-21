//  Copyright © 2019 Zappit. All rights reserved.

import Foundation

typealias ScheduleID = Int

class GeoOffersCacheData: Codable {
    var listing: GeoOffersListing?
    var pushNotificationSplitMessages: [GeoOffersPushData] = []
    var trackingEvents: [GeoOffersTrackingEvent] = []
    var pendingOffers: [ScheduleID: GeoOffersCacheItem] = [:]
    var offers: [ScheduleID: GeoOffersCachedOffer] = [:]
    var pendingNotifications: [ScheduleID: GeoOffersCacheItem] = [:]
    var enteredRegions: [ScheduleID: GeoOffersCacheItem] = [:]
}

class GeoOffersCacheStorage: CacheStorage {
    var cacheData: GeoOffersCacheData?
    func save() {}
    func load() -> GeoOffersCacheData? { return nil }
}

class GeoOffersDiskCacheStorage: GeoOffersCacheStorage {
    private var diskCache: DiskCache<GeoOffersCacheData>
    override var cacheData: GeoOffersCacheData? {
        didSet {
            diskCache.cacheData = cacheData
        }
    }
    
    override init() {
        diskCache = DiskCache<GeoOffersCacheData>(filename: "GeoOffersCache.data")
    }
    
    override func save() {
        diskCache.save()
    }
    override func load() -> GeoOffersCacheData? {
        return diskCache.load()
    }
}

class GeoOffersCache: Cache {
    private(set) var cacheData: GeoOffersCacheData
    private let storage: GeoOffersCacheStorage

    init(storage: GeoOffersCacheStorage) {
        self.storage = storage
        cacheData = GeoOffersCacheData()
        guard let loadedData = storage.load() else { return }
        cacheData = loadedData
    }

    func save() {
        storage.save()
    }

    func clearCache() {
        cacheData = GeoOffersCacheData()
        cacheUpdated()
    }

    func cacheUpdated() {
        storage.cacheData = cacheData
        storage.save()
    }
}
