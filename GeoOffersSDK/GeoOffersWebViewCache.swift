//  Copyright © 2019 Zappit. All rights reserved.

import Foundation

class GeoOffersWebViewCache {
    private var cache: GeoOffersCache
    private var listingCache: GeoOffersListingCache
    
    init(cache: GeoOffersCache, listingCache: GeoOffersListingCache) {
        self.cache = cache
        self.listingCache = listingCache
    }
    
    func buildCouponRequestJson(scheduleID: Int) -> String {
        guard let listing = cache.cacheData.listing else { return "{}" }
        var possibleOffer: GeoOffersOffer?
        for campaign in listing.campaigns.values {
            if campaign.offer.scheduleId == scheduleID {
                possibleOffer = campaign.offer
                break
            }
        }
        guard let offer = possibleOffer else { return "{}" }
        do {
            let encoder = JSONEncoder()
            let jsonData = try encoder.encode(offer)
            let json = String(data: jsonData, encoding: .utf8)
            return json ?? "{}"
        } catch {
            geoOffersLog("\(error)")
            return "{}"
        }
    }
    
    private func updateCampaignTimestamps(timestamp: Double) -> GeoOffersListing? {
        guard var listing = cache.cacheData.listing else { return nil }
        var hashes = [String]()
        let campaigns = listing.campaigns
        for campaign in campaigns.values {
            if campaign.offer.countdownToExpiryStartedTimestampMsOrNull == nil {
                var updatableCampaign = campaign
                updatableCampaign.offer.countdownToExpiryStartedTimestampMsOrNull = timestamp
                listing.campaigns[String(updatableCampaign.campaignId)] = updatableCampaign
                if let hash = updatableCampaign.offer.clientCouponHash {
                    hashes.append(hash)
                }
            }
        }
        
        if hashes.count > 0 {
            cache.cacheData.listing = listing
            cache.cacheUpdated()
        }
        return listing
    }
    
    func buildListingRequestJson() -> String {
        let timestamp = Date().timeIntervalSince1970 * 1000
        guard let listing = updateCampaignTimestamps(timestamp: timestamp) else { return "{}" }
        
        do {
            let encoder = JSONEncoder()
            let jsonData = try encoder.encode(listing)
            let json = String(data: jsonData, encoding: .utf8)
            return json ?? "{}"
        } catch {
            geoOffersLog("\(error)")
            return "{}"
        }
    }
    
    func buildAlreadyDeliveredOfferJson() -> String {
        let schedules = listingCache.deliveredSchedules()
        var items = [String]()
        for schedule in schedules {
            items.append("\"\(schedule.scheduleID)\":true")
        }
        let itemsString = items.joined(separator: ", ")
        return itemsString
    }
}
