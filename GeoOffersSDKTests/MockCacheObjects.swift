//  Copyright © 2019 Zappit. All rights reserved.

import Foundation
@testable import GeoOffersSDK

class TestCacheHelper {
    let cache: GeoOffersCache
    let offersCache: GeoOffersOffersCache
    let enteredRegionCache: GeoOffersEnteredRegionCache
    let sendNotificationCache: GeoOffersSendNotificationCache
    let notificationCache: GeoOffersPushNotificationCache
    let listingCache: GeoOffersListingCache
    let webViewCache: GeoOffersWebViewCache
    let trackingCache: GeoOffersTrackingCache

    init() {
        cache = GeoOffersCache(storage: GeoOffersCacheStorage())
        trackingCache = GeoOffersTrackingCache(cache: cache)
        enteredRegionCache = GeoOffersEnteredRegionCache(cache: cache)
        offersCache = GeoOffersOffersCache(cache: cache)
        sendNotificationCache = GeoOffersSendNotificationCache(cache: cache)
        notificationCache = GeoOffersPushNotificationCache(cache: cache)
        listingCache = MockGeoOffersListingCache(cache: cache, offersCache: offersCache)
        webViewCache = GeoOffersWebViewCache(cache: cache, listingCache: listingCache, offersCache: offersCache)
    }
}

class MockGeoOffersListingCache: GeoOffersListingCache {
    override var minimumMovementDistance: Double {
        return 0
    }
}
