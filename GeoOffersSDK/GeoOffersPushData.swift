//  Copyright © 2019 Zappit. All rights reserved.

import Foundation

extension Double {
    static let oneDaySeconds: Double = 60 * 60 * 24
}

struct GeoOffersPushData: Codable {
    let message: String
    let totalParts: Int
    let scheduleID: ScheduleID
    let messageIndex: Int
    let messageID: String
    let timestamp: Double

    init(message: String, totalParts: Int, scheduleID: ScheduleID, messageIndex: Int, messageID: String, timestamp: Double) {
        self.message = message
        self.totalParts = totalParts
        self.scheduleID = scheduleID
        self.messageIndex = messageIndex
        self.messageID = messageID
        self.timestamp = timestamp
    }

    enum CodingKeys: String, CodingKey {
        case message = "geoRewardsPushMessageJson"
        case totalParts = "splitMessageTotalPortionsCount"
        case scheduleID = "offerScheduleId"
        case messageIndex = "splitMessagePortionIndex"
        case messageID = "splitMessageId"
        case timestamp = "splitOrSingleMessageInitiatedTimestampMs"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        message = try values.decode(String.self, forKey: .message)
        scheduleID = try values.geoValueFromString(.scheduleID)
        timestamp = try values.geoValueFromString(.timestamp)
        if let messageID: String = try? values.decode(String.self, forKey: .messageID) {
            self.messageID = messageID
        } else {
            messageID = ""
        }

        if let totalParts: String = try? values.decode(String.self, forKey: .totalParts) {
            self.totalParts = Int(totalParts) ?? 1
        } else {
            totalParts = 1
        }

        if let messageIndex: String = try? values.decode(String.self, forKey: .messageIndex) {
            self.messageIndex = Int(messageIndex) ?? 0
        } else {
            messageIndex = 1
        }
    }

    var isOutOfDate: Bool {
        return abs(Date().unixTimeIntervalSince1970 - timestamp) > Double.oneDaySeconds
    }
}

struct GeoOffersPushNotificationDataUpdate: Codable {
    let type: String
    let scheduleID: ScheduleID
    let campaign: GeoOffersCampaign?
    let regions: [GeoOffersGeoFence]
    let schedule: GeoOffersSchedule

    enum CodingKeys: String, CodingKey {
        case type
        case campaign
        case scheduleID = "scheduleId"
        case regions = "geofences"
        case schedule = "offerRun"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        regions = values.geoDecode([GeoOffersGeoFence].self, forKey: .regions) ?? []
        type = try values.decode(String.self, forKey: .type)
        scheduleID = try values.decode(Int.self, forKey: .scheduleID)
        campaign = try values.decodeIfPresent(GeoOffersCampaign.self, forKey: .campaign)
        schedule = try values.decode(GeoOffersSchedule.self, forKey: .schedule)
    }
}
