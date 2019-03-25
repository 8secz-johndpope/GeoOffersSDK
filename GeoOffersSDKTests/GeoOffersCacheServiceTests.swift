//  Copyright © 2019 Zappit. All rights reserved.

@testable import GeoOffersSDK
import CoreLocation
import XCTest

class GeoOffersCacheServiceTests: XCTestCase {
    private let parser = GeoOffersDataParser()
    let apiService = MockGeoOffersAPIService()
    var cache: TestCacheHelper!

    var regions: [GeoOffersGeoFence] = []
    var schedules: [GeoOffersSchedule] = []
    var fenceData: GeoOffersListing!

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        regions = FileLoader.loadTestRegions()
        schedules = regions.map { GeoOffersSchedule(scheduleID: $0.scheduleID, campaignID: 1234, startDate: Date(), endDate: Date().addingTimeInterval(3600), repeatingSchedule: nil) }
        let data = FileLoader.loadTestData(filename: "example-nearby-geofences")!
        fenceData = parser.parseNearbyFences(jsonData: data)!
        cache = TestCacheHelper(apiService: apiService)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        cache.listingCache.clearCache()
    }

    func testLoadingTestRegions() {
        XCTAssert(regions.count > 0)
    }

    func test_encodeFunction() {
        let configuration = GeoOffersConfiguration(registrationCode: "", authToken: "", testing: true)
        let timezone = configuration.timezone
        let encodedTimezone = timezone.urlEncode()
        XCTAssertNotNil(encodedTimezone)
        XCTAssertNotEqual(timezone, encodedTimezone)
    }

    func test_cache_refresh_loading_data() {
        cache.listingCache.replaceCache(fenceData)
        let firstRegion = regions.first!
        let nearbyFences = cache.fencesCache.fencesNear(latitude: firstRegion.latitude, longitude: firstRegion.longitude)
        XCTAssertEqual(13, nearbyFences.count)
    }

    func test_nearby_regions_max_to_return_greater_than_number_of_regions() {
        cache.listingCache.replaceCache(fenceData)
        let firstRegion = regions.first!
        let expectedRegionCount = fenceData.regions.reduce([]) { result, keyValuePair in
            result + keyValuePair.value
        }.count
        let nearbyFences = cache.fencesCache.fencesNear(latitude: firstRegion.latitude, longitude: firstRegion.longitude)
        XCTAssert(expectedRegionCount == nearbyFences.count, "Expected:\(expectedRegionCount), got:\(nearbyFences.count)")
    }

    func test_cache_clean_up_removed_schedules() {
        cache.listingCache.replaceCache(fenceData)
        var data = fenceData!
        data.regions = [:]
        data.schedules = []
        data.deliveredSchedules = []
        cache.listingCache.replaceCache(data)

        let firstRegion = regions.first!
        let nearbyFences = cache.fencesCache.fencesNear(latitude: firstRegion.latitude, longitude: firstRegion.longitude)
        XCTAssert(nearbyFences.isEmpty, "Expected no regions, got:\(nearbyFences.count)")
    }

    func test_refresh_with_valid_schedules_does_not_remove_existing_regions() {
        cache.listingCache.replaceCache(fenceData)
        var data = fenceData!
        data.regions = [:]
        data.schedules = schedules
        data.deliveredSchedules = []
        cache.listingCache.replaceCache(data)
        let firstRegion = regions.first!
        let nearbyFences = cache.fencesCache.fencesNear(latitude: firstRegion.latitude, longitude: firstRegion.longitude)
        XCTAssert(nearbyFences.isEmpty, "Expected: no regions got:\(nearbyFences.count)")
        XCTAssertEqual(schedules.count, cache.listingCache.schedules().count)
    }

    func test_retrieving_schedules_from_cache() {
        var data = fenceData!
        data.schedules = schedules
        cache.listingCache.replaceCache(data)

        let retrievedSchedules = cache.listingCache.schedules(for: 5129, scheduleDeviceID: "Testing")
        XCTAssert(retrievedSchedules.count == schedules.count, "Expected: \(schedules.count), got: \(retrievedSchedules.count)")
    }

    func test_repeating_schedule_from_cache() {
        let filename = "example-nearby-geofences-with-repeating-schedule"
        guard let jsonData = FileLoader.loadTestData(filename: filename) else {
            XCTFail("Could not load test data")
            return
        }
        guard let data = parser.parseNearbyFences(jsonData: jsonData) else {
            XCTFail("Could not parse test data")
            return
        }
        cache.listingCache.replaceCache(data)
        let expectedRegionCount = data.regions.reduce([]) { result, keyValuePair in
            result + keyValuePair.value
        }.count

        let firstRegion = regions.first!
        let nearbyFences = cache.fencesCache.fencesNear(latitude: firstRegion.latitude, longitude: firstRegion.longitude)
        XCTAssert(expectedRegionCount == nearbyFences.count, "Expected:\(expectedRegionCount), got:\(nearbyFences.count)")

        let schedules = cache.listingCache.schedules(for: 5129, scheduleDeviceID: "Testing")
        XCTAssert(schedules.count == 1, "Wrong number of schedules")
        let schedule = schedules.first!.repeatingSchedule!

        XCTAssertEqual(schedule.type, .daily)
        XCTAssertNil(schedule.start.dayOfWeek)
        XCTAssertNil(schedule.start.dayOfMonth)
        XCTAssertNil(schedule.start.month)
        XCTAssertEqual(schedule.start.hours, 9)
        XCTAssertEqual(schedule.start.minutes, 0)
        XCTAssertNil(schedule.end.dayOfWeek)
        XCTAssertNil(schedule.end.dayOfMonth)
        XCTAssertNil(schedule.end.month)
        XCTAssertEqual(schedule.end.hours, 17)
        XCTAssertEqual(schedule.end.minutes, 0)
    }

    func test_checking_for_delivered_schedule_in_cache_not_found() {
        let scheduleID = 5129
        let scheduleDeviceID = "5c0f9a4443e23"
        var data = fenceData!
        data.regions = [String(scheduleID): regions]
        data.schedules = schedules
        data.deliveredSchedules = []
        cache.listingCache.replaceCache(data)
        XCTAssertFalse(cache.listingCache.deliveredSchedule(for: scheduleID, scheduleDeviceID: scheduleDeviceID))
    }

    func test_checking_for_delivered_schedule_in_cache_found() {
        let scheduleID = 5129
        let scheduleDeviceID = "5c0f9a4443e23"
        let deliveredSchedule = GeoOffersDeliveredSchedule(scheduleID: scheduleID, scheduleDeviceID: scheduleDeviceID)
        var data = fenceData!
        data.deliveredSchedules = [deliveredSchedule]
        cache.listingCache.replaceCache(data)
        XCTAssertTrue(cache.listingCache.deliveredSchedule(for: scheduleID, scheduleDeviceID: scheduleDeviceID))
    }

    func test_retrieve_schedule_where_not_delivered() {
        let scheduleID = 5129
        let scheduleDeviceID = "5c06804564e26"
        cache.listingCache.replaceCache(fenceData)
        let validSchedules = cache.listingCache.schedules(for: scheduleID, scheduleDeviceID: scheduleDeviceID)
        XCTAssertTrue(!validSchedules.isEmpty)
    }

    func test_retrieve_schedule_where_delivered() {
        let scheduleID = 5129
        let scheduleDeviceID = "5c06804564e26"
        let deliveredSchedule = GeoOffersDeliveredSchedule(scheduleID: scheduleID, scheduleDeviceID: scheduleDeviceID)
        var data = fenceData!
        data.deliveredSchedules = [deliveredSchedule]
        cache.listingCache.replaceCache(data)
        let validSchedules = cache.listingCache.schedules(for: scheduleID, scheduleDeviceID: scheduleDeviceID)
        XCTAssertTrue(validSchedules.isEmpty)
    }

    func test_retrieve_schedule_where_not_exist() {
        let scheduleID = 1000
        let scheduleDeviceID = "5c06804564e26"
        let deliveredSchedule = GeoOffersDeliveredSchedule(scheduleID: scheduleID, scheduleDeviceID: scheduleDeviceID)
        var data = fenceData!
        data.deliveredSchedules = [deliveredSchedule]
        cache.listingCache.replaceCache(data)
        let validSchedules = cache.listingCache.schedules(for: scheduleID, scheduleDeviceID: scheduleDeviceID)
        XCTAssertTrue(validSchedules.isEmpty)
    }

//    func test_loading_cache_with_file_deletion() {
//        var data = fenceData!
//        data.deliveredSchedules = []
//        cache.listingCache.replaceCache(data)
//        let firstRegion = regions.first!
//        let nearbyFences = cache.fencesCache.fencesNear(latitude: firstRegion.latitude, longitude: firstRegion.longitude)
//        XCTAssertEqual(13, nearbyFences.count)
//
//        deleteDocumentsFolder()
//        let apiService = MockGeoOffersAPIService()
//        let newCache = GeoOffersCacheServiceDefault(apiService: apiService)
//        let expectation2 = self.expectation(description: "Wait for response")
//        newCache.fences.fencesNear(latitude: firstRegion.latitude, longitude: firstRegion.longitude) { nearbyFences in
//            expectation2.fulfill()
//            XCTAssert(nearbyFences.isEmpty, "Expected no regions, got:\(nearbyFences.count)")
//        }
//        waitForExpectations(timeout: 1) { error in
//            if let error = error {
//                print("Error: \(error.localizedDescription)")
//            }
//        }
//    }

    func test_adding_pending_offer_to_cache() {
        let scheduleID = 1234
        let scheduleDeviceID = "5c06804564e26"
        cache.offersCache.addPendingOffer(scheduleID: scheduleID, scheduleDeviceID: scheduleDeviceID, latitude: 1, longitude: 1, notificationDwellDelayMs: 0)
        cache.offersCache.refreshPendingOffers()
        XCTAssertFalse(cache.offersCache.hasPendingOffers())
        XCTAssertTrue(cache.offersCache.hasOffers())
    }

    func test_adding_pending_offer_to_cache_where_not_enough_dwell_time() {
        let scheduleID = 1234
        let scheduleDeviceID = "5c06804564e26"
        cache.offersCache.addPendingOffer(scheduleID: scheduleID, scheduleDeviceID: scheduleDeviceID, latitude: 1, longitude: 1, notificationDwellDelayMs: 10000)
        cache.offersCache.refreshPendingOffers()
        XCTAssertTrue(cache.offersCache.hasPendingOffers())
        XCTAssertFalse(cache.offersCache.hasOffers())
    }

    func test_adding_pending_offer_to_cache_with_dwell_time() {
        let scheduleID = 1234
        let scheduleDeviceID = "5c06804564e26"
        cache.listingCache.replaceCache(fenceData)
        cache.offersCache.addPendingOffer(scheduleID: scheduleID, scheduleDeviceID: scheduleDeviceID, latitude: 1, longitude: 1, notificationDwellDelayMs: 1)
        Thread.sleep(forTimeInterval: 0.4)
        cache.offersCache.refreshPendingOffers()
        XCTAssertFalse(cache.offersCache.hasPendingOffers())
    }

    func test_adding_pending_offer_clear_cache() {
        let scheduleID = 1234
        let scheduleDeviceID = "5c06804564e26"
        cache.offersCache.addPendingOffer(scheduleID: scheduleID, scheduleDeviceID: scheduleDeviceID, latitude: 1, longitude: 1, notificationDwellDelayMs: 0)
        cache.offersCache.refreshPendingOffers()
        XCTAssertFalse(cache.offersCache.hasPendingOffers())
        XCTAssertTrue(cache.offersCache.hasOffers())

        cache.offersCache.clearPendingOffers()
        XCTAssertFalse(cache.offersCache.hasPendingOffers())
    }

    func test_removing_pending_offer_from_cache() {
        let scheduleID = 1234
        let scheduleDeviceID = "5c06804564e26"
        let identifier = GeoOffersPendingOffer.generateKey(scheduleID: scheduleID, scheduleDeviceID: scheduleDeviceID)
        cache.offersCache.addPendingOffer(scheduleID: scheduleID, scheduleDeviceID: scheduleDeviceID, latitude: 1, longitude: 1, notificationDwellDelayMs: 10000)
        cache.offersCache.removePendingOffer(identifier: identifier)
        cache.offersCache.refreshPendingOffers()
        XCTAssertFalse(cache.offersCache.hasPendingOffers())
    }

    func test_adding_push_message() {
        let message = GeoOffersPushData(message: "Hello world", totalParts: 1, scheduleID: 1234, messageIndex: 0, messageID: "messageId1", timestamp: Date().timeIntervalSince1970 * 1000)
        cache.notificationCache.add(message)

        XCTAssertEqual(cache.notificationCache.count(message.messageID), 1)
        cache.notificationCache.remove(message.messageID)
        XCTAssertEqual(cache.notificationCache.count(message.messageID), 0)
    }

    func test_counting_push_messages() {
        let message = GeoOffersPushData(message: "Hello world", totalParts: 1, scheduleID: 1234, messageIndex: 0, messageID: "messageId1", timestamp: Date().timeIntervalSince1970 * 1000)
        cache.notificationCache.add(message)

        XCTAssertEqual(cache.notificationCache.count(message.messageID), 1)
        cache.notificationCache.removeAllPushMessages()
        XCTAssertEqual(cache.notificationCache.count(message.messageID), 0)
    }

    func test_retrieving_push_messages() {
        let message1 = GeoOffersPushData(message: "Hello world", totalParts: 3, scheduleID: 1234, messageIndex: 0, messageID: "messageId1", timestamp: Date().timeIntervalSince1970 * 1000)
        cache.notificationCache.add(message1)
        let message2 = GeoOffersPushData(message: "Hello world", totalParts: 3, scheduleID: 1234, messageIndex: 1, messageID: "messageId1", timestamp: Date().timeIntervalSince1970 * 1000)
        cache.notificationCache.add(message2)
        let message3 = GeoOffersPushData(message: "Hello world", totalParts: 3, scheduleID: 1234, messageIndex: 2, messageID: "messageId1", timestamp: Date().timeIntervalSince1970 * 1000)
        cache.notificationCache.add(message3)

        XCTAssertEqual(cache.notificationCache.count(message1.messageID), 3)
        cache.notificationCache.removeAllPushMessages()
        XCTAssertEqual(cache.notificationCache.count(message1.messageID), 0)
    }

    func test_removing_push_messages() {
        let message = GeoOffersPushData(message: "Hello world", totalParts: 1, scheduleID: 1234, messageIndex: 0, messageID: "messageId1", timestamp: Date().timeIntervalSince1970 * 1000)
        cache.notificationCache.add(message)

        XCTAssertEqual(cache.notificationCache.count(message.messageID), 1)
        cache.notificationCache.removeAllPushMessages()
        XCTAssertEqual(cache.notificationCache.count(message.messageID), 0)
    }

    func test_removeAllPushMessages() {
        let message = GeoOffersPushData(message: "Hello world", totalParts: 1, scheduleID: 1234, messageIndex: 0, messageID: "messageId1", timestamp: Date().timeIntervalSince1970 * 1000)
        cache.notificationCache.add(message)

        XCTAssertEqual(cache.notificationCache.count(message.messageID), 1)
        cache.notificationCache.removeAllPushMessages()
        XCTAssertEqual(cache.notificationCache.count(message.messageID), 0)
    }

    func test_loadNearbyJson() {
        loadAndTestNearbyJson(filename: "example-nearby-geofences2")
        loadAndTestNearbyJson(filename: "example-nearby-geofences3")
    }

    func loadAndTestNearbyJson(filename: String) {
        guard let data = FileLoader.loadTestData(filename: filename) else {
            XCTFail("Where's my test data? \(filename)")
            return
        }

        guard let fenceData = parser.parseNearbyFences(jsonData: data) else {
            XCTFail("Where's my test data? \(filename)")
            return
        }

        XCTAssertNotNil(fenceData, "\(filename)")
        XCTAssertTrue(!fenceData.campaigns.isEmpty, "\(filename)")
    }

    func test_buildCouponRequestJson_no_listing() {
        cache.listingCache.clearCache()
        let json = cache.webViewCache.buildCouponRequestJson(scheduleID: 5139)
        XCTAssertEqual("{}", json)
    }

    func test_applicationDidEnterBackgroundNotification() {
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
    }

//    func test_saveSchedule_no_pending_changes() {
//        var cache: GeoOffersCacheService? = GeoOffersCacheServiceDefault(apiService: apiService, savePeriodSeconds: 1)
//        XCTAssertNotNil(cache)
//        cache = nil
//        XCTAssertNil(cache)
//    }

//    func test_saveSchedule_with_pending_changes() {
//        var cache: GeoOffersCacheServiceDefault? = GeoOffersCacheServiceDefault(apiService: apiService, savePeriodSeconds: 1)
//        cache?.forcePendingChanges()
//        XCTAssertNotNil(cache)
//        cache = nil
//        XCTAssertNil(cache)
//    }

    func test_buildAlreadyDeliveredOfferJson() {
        guard let data = FileLoader.loadTestData(filename: "example-nearby-geofences") else {
            XCTFail("Where's my test data?")
            return
        }

        guard let fenceData = parser.parseNearbyFences(jsonData: data) else {
            XCTFail("Where's my test data?")
            return
        }

        cache.listingCache.replaceCache(fenceData)

        let json = cache.webViewCache.buildAlreadyDeliveredOfferJson()
        XCTAssertNotNil(json)
    }

    func test_buildCouponRequestJson() {
        guard let data = FileLoader.loadTestData(filename: "example-nearby-geofences") else {
            XCTFail("Where's my test data?")
            return
        }

        guard let fenceData = parser.parseNearbyFences(jsonData: data) else {
            XCTFail("Where's my test data?")
            return
        }

        cache.listingCache.replaceCache(fenceData)

        let json = cache.webViewCache.buildCouponRequestJson(scheduleID: 5139)
        let headline = "Sainsbury's sale"
        let scheduleEndDateString = "22nd February 2019 @ 23:55"

        XCTAssert(json.contains(headline))
        XCTAssert(json.contains(scheduleEndDateString))
    }

    func test_buildListingRequestJson_no_listing() {
        let json = cache.webViewCache.buildListingRequestJson()
        XCTAssertEqual("{}", json)
    }

    func test_getListing() {
        let items = cache.listingCache.listing()
        XCTAssertNil(items)
    }

    func test_schedules_empty() {
        let items = cache.listingCache.schedules()
        XCTAssertTrue(items.isEmpty)
    }

    func test_deliveredSchedules_empty() {
        let items = cache.listingCache.deliveredSchedules()
        XCTAssertTrue(items.isEmpty)
    }

    func test_schedulesFor_empty() {
        let items = cache.listingCache.schedules(for: 1, scheduleDeviceID: "test")
        XCTAssertTrue(items.isEmpty)
    }

    func test_deliveredSchedulesFor_empty() {
        let result = cache.listingCache.deliveredSchedule(for: 1, scheduleDeviceID: "test")
        XCTAssertFalse(result)
    }

    func test_pendingOffer_no_offer() {
        let result = cache.offersCache.pendingOffer("test")
        XCTAssertNil(result)
    }

    func test_pendingOffer_offer() {
        let scheduleID = 1234
        let scheduleDeviceID = "5c06804564e26"
        let key = "\(scheduleID)_\(scheduleDeviceID)"

        cache.offersCache.addPendingOffer(scheduleID: scheduleID, scheduleDeviceID: scheduleDeviceID, latitude: 1, longitude: 1, notificationDwellDelayMs: 50000)
        cache.offersCache.refreshPendingOffers()
        XCTAssertTrue(cache.offersCache.hasPendingOffers())
        XCTAssertFalse(cache.offersCache.hasOffers())

        let result = cache.offersCache.pendingOffer(key)
        XCTAssertNotNil(result)
    }

    func test_offers() {
        let scheduleID = 1234
        let scheduleDeviceID = "5c06804564e26"
        cache.offersCache.addPendingOffer(scheduleID: scheduleID, scheduleDeviceID: scheduleDeviceID, latitude: 1, longitude: 1, notificationDwellDelayMs: 0)
        cache.offersCache.refreshPendingOffers()
        XCTAssertFalse(cache.offersCache.hasPendingOffers())
        XCTAssertTrue(cache.offersCache.hasOffers())

        let offers = cache.offersCache.offers()
        XCTAssertNotNil(offers)
    }

    func test_buildInitialWebRequestJson() {
        guard let data = FileLoader.loadTestData(filename: "example-nearby-geofences") else {
            XCTFail("Where's my test data?")
            return
        }

        guard let fenceData = parser.parseNearbyFences(jsonData: data) else {
            XCTFail("Where's my test data?")
            return
        }

        cache.listingCache.replaceCache(fenceData)

        let json = cache.webViewCache.buildListingRequestJson()
        let customEntryNotificationTitle = "All locations offer"
        let deviceUid = "5c0f9a4443e23"

        XCTAssert(json.contains(customEntryNotificationTitle))
        XCTAssert(json.contains(deviceUid))
    }

    func test_buildInitialWebRequestJson_multiple_delivered_schedules() {
        guard let data = FileLoader.loadTestData(filename: "example-nearby-geofences-multi-delivered") else {
            XCTFail("Where's my test data?")
            return
        }

        guard let fenceData = parser.parseNearbyFences(jsonData: data) else {
            XCTFail("Where's my test data?")
            return
        }
        let registrationCode = "regcode12345"
        let authToken = "authtoken12345"
        cache.listingCache.replaceCache(fenceData)

        for schedule in fenceData.deliveredSchedules {
            cache.offersCache.addPendingOffer(scheduleID: schedule.scheduleID, scheduleDeviceID: schedule.scheduleDeviceID, latitude: 1, longitude: 1, notificationDwellDelayMs: 0)
        }

        let json = cache.webViewCache.buildListingRequestJson()
        XCTAssert(!json.contains(authToken))
        XCTAssert(!json.contains(registrationCode))
    }

    func test_buildJavascriptForWebView_multiple_delivered_schedules() {
        guard let data = FileLoader.loadTestData(filename: "example-nearby-geofences-multi-delivered") else {
            XCTFail("Where's my test data?")
            return
        }

        guard let fenceData = parser.parseNearbyFences(jsonData: data) else {
            XCTFail("Where's my test data?")
            return
        }
        let registrationCode = "regcode12345"
        let authToken = "authtoken12345"
        cache.listingCache.replaceCache(fenceData)

        let json = cache.webViewCache.buildListingRequestJson()
        XCTAssert(!json.contains(authToken))
        XCTAssert(!json.contains(registrationCode))
    }
    
//    func test_bigdata() {
//        guard let data = FileLoader.loadTestData(filename: "example-nearby-geofences-large") else {
//            XCTFail("Where's my test data?")
//            return
//        }
//        
//        guard let fenceData = parser.parseNearbyFences(jsonData: data) else {
//            XCTFail("Where's my test data?")
//            return
//        }
//        
//        XCTAssertEqual(10, fenceData.campaigns.count)
//        
//        let regions = fenceData.regions.reduce([]) { $0 + $1.value }
//        XCTAssertEqual(42, regions.count)
//        
//        let currentCoordinates = CLLocationCoordinate2D(latitude: 51.1070157, longitude: -0.181549)
////        let currentLocation = CLLocation(latitude: currentCoordinates.latitude, longitude: currentCoordinates.longitude)
////        let sorted = regions.sorted { (f1, f2) -> Bool in
////            f1.location.distance(from: currentLocation) < f2.location.distance(from: currentLocation)
////        }
//
//        let now = Date()
//        for campaign in fenceData.campaigns {
//            let campaignId = campaign.value.campaignId
//            let scheduleId = campaign.value.offer.scheduleId
//            let deviceUid = campaign.value.offer.deviceUid
//            let scheduleIdstring = scheduleId != nil ? String(scheduleId!) : ""
//            print("Campaign:\(campaignId), \(scheduleId), \(deviceUid)")
//            
//            // Region start
//            var region: GeoOffersGeoFence?
//            for r in fenceData.regions[scheduleIdstring] ?? [] {
//                if r.scheduleDeviceID == deviceUid {
//                    region = r
//                    let circularRegion = CLCircularRegion(center: r.coordinate, radius: r.radiusKm * 1000, identifier: "abc")
//                    let isInRegion = circularRegion.contains(currentCoordinates)
//                    print("  Region:\(r.latitude), \(r.longitude), \(isInRegion ? "In region" : "Outside region")")
//                }
//            }
//            if region == nil {
//                print("  Region not found")
//            }
//            // Region end
//            
//            // Schedule start
//            var schedule: GeoOffersSchedule?
//            for s in fenceData.schedules {
//                if s.scheduleID == scheduleId && s.campaignID == campaignId {
//                    schedule = s
//                    break
//                }
//            }
//            if let schedule = schedule {
//                print("  Schedule:\(schedule.startDate), \(schedule.endDate), \(schedule.isValid(for: now))")
//            } else {
//                print("  Schedule not found")
//            }
//            // Schedule end
//            
//            // Delivered schedule start
//            var deliveredSchedule: GeoOffersDeliveredSchedule?
//            for d in fenceData.deliveredSchedules {
//                if d.scheduleID == scheduleId && d.scheduleDeviceID == deviceUid {
//                    deliveredSchedule = d
//                    break
//                }
//            }
//            if deliveredSchedule != nil {
//                print("  Delivered schedule found")
//            } else {
//                print("  Delivered schedule not found")
//            }
//            // Delivered schedule end
//            
//            print("\n\n")
//        }
//
//        /*
//         Campaigns
//         • Campaign.campaignId
//         • Campaign.offer.scheduleId
//         • Campaign.offer.deviceUid
//         
//         Regions (geofencesByRewardScheduleId)
//         • Region.scheduleId
//         • Region.deviceUid
//         • Region.latitude
//         • Region.longitude
//         
//         Schedules (offerRuns)
//         • Schedule.scheduleId
//         • Schedule.campaignId
//         
//         DeliveredSchedules
//         • DeliveredSchedule.scheduleId
//         • DeliveredSchedule.deviceUid
//         */
//    }

    private func deleteDocumentsFolder() {
        let fileManager = FileManager.default
        guard let path = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("Where is the directory?")
        }

        if fileManager.fileExists(atPath: path.path) {
            do {
                try fileManager.removeItem(at: path)
            } catch {}
        }
    }
}
