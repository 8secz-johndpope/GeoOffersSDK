//  Copyright © 2019 Zappit. All rights reserved.

import CoreLocation

enum GeoOffersTrackingEventType: String, Codable {
    case geoFenceEntry = "GeofenceEntry"
    case geoFenceExit = "GeofenceExit"
    case offerDelivered = "Delivered"
    case regionDwellTime = "GeofenceDwell"
    case polledForNearbyOffers = "PolledForNearbyOffers"
    case couponOpened = "CouponOpened"

    var shouldSendToServer: Bool {
        switch self {
        case .geoFenceEntry, .offerDelivered, .couponOpened: return true
        default: return false
        }
    }
}

struct GeoOffersTrackingEvent: Codable {
    let type: GeoOffersTrackingEventType
    let timestamp: Double
    let scheduleDeviceID: String
    let scheduleID: ScheduleID
    let latitude: Double
    let longitude: Double
    let clientCouponHash: String?

    enum CodingKeys: String, CodingKey {
        case type
        case timestamp = "timestampMs"
        case scheduleDeviceID = "deviceUid"
        case scheduleID = "rewardScheduleId"
        case latitude = "userLatitude"
        case longitude = "userLongitude"
        case clientCouponHash = "clientCouponHashIfApplicable"
    }
}

extension GeoOffersTrackingEvent {
    static func event(with type: GeoOffersTrackingEventType, region: GeoOffersGeoFence, location: CLLocationCoordinate2D?) -> GeoOffersTrackingEvent {
        return event(with: type, scheduleID: region.scheduleID, scheduleDeviceID: region.scheduleDeviceID, latitude: location?.latitude ?? region.latitude, longitude: location?.longitude ?? region.longitude)
    }

    static func event(with type: GeoOffersTrackingEventType, scheduleID: ScheduleID, scheduleDeviceID: String, latitude: Double, longitude: Double) -> GeoOffersTrackingEvent {
        let event = GeoOffersTrackingEvent(type: type, timestamp: Date().unixTimeIntervalSince1970, scheduleDeviceID: scheduleDeviceID, scheduleID: scheduleID, latitude: latitude, longitude: longitude, clientCouponHash: nil)
        return event
    }
}

struct GeoOffersTrackingWrapper: Codable {
    let deviceID: String
    let timezone: String
    let events: [GeoOffersTrackingEvent]

    enum CodingKeys: String, CodingKey {
        case deviceID = "endUserUid"
        case timezone = "endUserTimezone"
        case events
    }
}
