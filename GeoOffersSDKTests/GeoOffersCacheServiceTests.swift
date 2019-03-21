//  Copyright © 2019 Zappit. All rights reserved.

@testable import GeoOffersSDK
import XCTest

class GeoOffersCacheServiceTests: XCTestCase {
    private let parser = GeoOffersDataParser()
    let apiService = MockGeoOffersAPIService()
    lazy var cache: GeoOffersCacheServiceDefault = {
        GeoOffersCacheServiceDefault(apiService: apiService)
    }()

    var regions: [GeoOffersGeoFence] = []
    var schedules: [GeoOffersSchedule] = []
    var fenceData: GeoOffersListing!

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        regions = FileLoader.loadTestRegions()
        schedules = regions.map { GeoOffersSchedule(scheduleID: $0.scheduleID, campaignID: 1234, startDate: Date(), endDate: Date().addingTimeInterval(3600), repeatingSchedule: nil) }
        let data = FileLoader.loadTestData(filename: "example-nearby-geofences")!
        fenceData = parser.parseNearbyFences(jsonData: data)!
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        cache.clearCache()
    }

    func testLoadingTestRegions() {
        XCTAssert(regions.count > 0)
    }

    func test_encodeFunction() {
        let configuration = GeoOffersConfigurationDefault(registrationCode: "", authToken: "", testing: true)
        let timezone = configuration.timezone
        let encodedTimezone = timezone.urlEncode()
        XCTAssertNotNil(encodedTimezone)
        XCTAssertNotEqual(timezone, encodedTimezone)
    }

    func test_cache_refresh_loading_data() {
        let numberOfRegionsNearBy = 5
        XCTAssert(regions.count > numberOfRegionsNearBy)
        cache.replaceCache(fenceData)
        let firstRegion = regions.first!
        let expectation = self.expectation(description: "Wait for response")
        cache.fencesNear(latitude: firstRegion.latitude, longitude: firstRegion.longitude, maximumNumberOfRegionsToReturn: numberOfRegionsNearBy) { nearbyFences in
            expectation.fulfill()
            XCTAssert(numberOfRegionsNearBy == nearbyFences.count, "Expected:\(self.regions.count), got:\(nearbyFences.count)")
        }
        waitForExpectations(timeout: 1) { error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }
    }

    func test_nearby_regions_max_to_return_greater_than_number_of_regions() {
        let numberOfRegionsNearBy = 100
        cache.replaceCache(fenceData)
        let firstRegion = regions.first!
        let expectation = self.expectation(description: "Wait for response")
        let expectedRegionCount = fenceData.regions.reduce([]) { result, keyValuePair in
            result + keyValuePair.value
        }.count
        cache.fencesNear(latitude: firstRegion.latitude, longitude: firstRegion.longitude, maximumNumberOfRegionsToReturn: numberOfRegionsNearBy) { nearbyFences in
            expectation.fulfill()
            XCTAssert(expectedRegionCount == nearbyFences.count, "Expected:\(expectedRegionCount), got:\(nearbyFences.count)")
        }
        waitForExpectations(timeout: 1) { error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }
    }

    func test_cache_clean_up_removed_schedules() {
        let numberOfRegionsNearBy = 100
        cache.replaceCache(fenceData)
        var data = fenceData!
        data.regions = [:]
        data.schedules = []
        data.deliveredSchedules = []
        cache.replaceCache(data)

        let firstRegion = regions.first!
        let expectation = self.expectation(description: "Wait for response")
        cache.fencesNear(latitude: firstRegion.latitude, longitude: firstRegion.longitude, maximumNumberOfRegionsToReturn: numberOfRegionsNearBy) { nearbyFences in
            expectation.fulfill()
            XCTAssert(nearbyFences.isEmpty, "Expected no regions, got:\(nearbyFences.count)")
        }
        waitForExpectations(timeout: 1) { error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }
    }

    func test_refresh_with_valid_schedules_does_not_remove_existing_regions() {
        let numberOfRegionsNearBy = 100
        cache.replaceCache(fenceData)
        var data = fenceData!
        data.regions = [:]
        data.schedules = schedules
        data.deliveredSchedules = []
        cache.replaceCache(data)
        let firstRegion = regions.first!
        let expectation = self.expectation(description: "Wait for response")
        cache.fencesNear(latitude: firstRegion.latitude, longitude: firstRegion.longitude, maximumNumberOfRegionsToReturn: numberOfRegionsNearBy) { nearbyFences in
            expectation.fulfill()
            XCTAssert(nearbyFences.isEmpty, "Expected: no regions got:\(nearbyFences.count)")
        }
        XCTAssertEqual(schedules.count, cache.schedules().count)
        waitForExpectations(timeout: 1) { error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }
    }

    func test_cache_reloading() {
        let numberOfRegionsNearBy = 100
        var data = fenceData!
        data.deliveredSchedules = []
        cache.replaceCache(data)
        cache.save()
        let apiService = MockGeoOffersAPIService()
        let newCache = GeoOffersCacheServiceDefault(apiService: apiService)
        let firstRegion = regions.first!
        let expectation = self.expectation(description: "Wait for response")
        let expectedRegionCount = data.regions.reduce([]) { result, keyValuePair in
            result + keyValuePair.value
        }.count
        newCache.fencesNear(latitude: firstRegion.latitude, longitude: firstRegion.longitude, maximumNumberOfRegionsToReturn: numberOfRegionsNearBy) { nearbyFences in
            expectation.fulfill()
            XCTAssert(expectedRegionCount == nearbyFences.count, "Expected:\(expectedRegionCount), got:\(nearbyFences.count)")
        }
        waitForExpectations(timeout: 1) { error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }
    }

    func test_retrieving_schedules_from_cache() {
        var data = fenceData!
        data.schedules = schedules
        cache.replaceCache(data)

        let retrievedSchedules = cache.schedules(for: 5129, scheduleDeviceID: "Testing")
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
        cache.replaceCache(data)
        let expectedRegionCount = data.regions.reduce([]) { result, keyValuePair in
            result + keyValuePair.value
        }.count

        let firstRegion = regions.first!
        let numberOfRegionsNearBy = 100
        let expectation = self.expectation(description: "Wait for response")
        cache.fencesNear(latitude: firstRegion.latitude, longitude: firstRegion.longitude, maximumNumberOfRegionsToReturn: numberOfRegionsNearBy) { nearbyFences in
            expectation.fulfill()
            XCTAssert(expectedRegionCount == nearbyFences.count, "Expected:\(expectedRegionCount), got:\(nearbyFences.count)")
        }

        let schedules = cache.schedules(for: 5129, scheduleDeviceID: "Testing")
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
        waitForExpectations(timeout: 1) { error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }
    }

    func test_checking_for_delivered_schedule_in_cache_not_found() {
        let scheduleID = 5129
        let scheduleDeviceID = "5c0f9a4443e23"
        var data = fenceData!
        data.regions = [String(scheduleID): regions]
        data.schedules = schedules
        data.deliveredSchedules = []
        cache.replaceCache(data)
        XCTAssertFalse(cache.deliveredSchedule(for: scheduleID, scheduleDeviceID: scheduleDeviceID))
    }

    func test_checking_for_delivered_schedule_in_cache_found() {
        let scheduleID = 5129
        let scheduleDeviceID = "5c0f9a4443e23"
        let deliveredSchedule = GeoOffersDeliveredSchedule(scheduleID: scheduleID, scheduleDeviceID: scheduleDeviceID)
        var data = fenceData!
        data.deliveredSchedules = [deliveredSchedule]
        cache.replaceCache(data)
        XCTAssertTrue(cache.deliveredSchedule(for: scheduleID, scheduleDeviceID: scheduleDeviceID))
    }

    func test_retrieve_schedule_where_not_delivered() {
        let scheduleID = 5129
        let scheduleDeviceID = "5c06804564e26"
        cache.replaceCache(fenceData)
        let validSchedules = cache.schedules(for: scheduleID, scheduleDeviceID: scheduleDeviceID)
        XCTAssertTrue(!validSchedules.isEmpty)
    }

    func test_retrieve_schedule_where_delivered() {
        let scheduleID = 5129
        let scheduleDeviceID = "5c06804564e26"
        let deliveredSchedule = GeoOffersDeliveredSchedule(scheduleID: scheduleID, scheduleDeviceID: scheduleDeviceID)
        var data = fenceData!
        data.deliveredSchedules = [deliveredSchedule]
        cache.replaceCache(data)
        let validSchedules = cache.schedules(for: scheduleID, scheduleDeviceID: scheduleDeviceID)
        XCTAssertTrue(validSchedules.isEmpty)
    }

    func test_retrieve_schedule_where_not_exist() {
        let scheduleID = 1000
        let scheduleDeviceID = "5c06804564e26"
        let deliveredSchedule = GeoOffersDeliveredSchedule(scheduleID: scheduleID, scheduleDeviceID: scheduleDeviceID)
        var data = fenceData!
        data.deliveredSchedules = [deliveredSchedule]
        cache.replaceCache(data)
        let validSchedules = cache.schedules(for: scheduleID, scheduleDeviceID: scheduleDeviceID)
        XCTAssertTrue(validSchedules.isEmpty)
    }

    func test_loading_cache_with_file_deletion() {
        let numberOfRegionsNearBy = 5
        XCTAssert(regions.count > numberOfRegionsNearBy)
        var data = fenceData!
        data.deliveredSchedules = []
        cache.replaceCache(data)
        let firstRegion = regions.first!
        let expectation = self.expectation(description: "Wait for response")
        cache.fencesNear(latitude: firstRegion.latitude, longitude: firstRegion.longitude, maximumNumberOfRegionsToReturn: numberOfRegionsNearBy) { nearbyFences in
            expectation.fulfill()
            XCTAssert(numberOfRegionsNearBy == nearbyFences.count, "Expected:\(self.regions.count), got:\(nearbyFences.count)")
        }
        waitForExpectations(timeout: 1) { error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }

        deleteDocumentsFolder()
        let apiService = MockGeoOffersAPIService()
        let newCache = GeoOffersCacheServiceDefault(apiService: apiService)
        let expectation2 = self.expectation(description: "Wait for response")
        newCache.fencesNear(latitude: firstRegion.latitude, longitude: firstRegion.longitude, maximumNumberOfRegionsToReturn: numberOfRegionsNearBy) { nearbyFences in
            expectation2.fulfill()
            XCTAssert(nearbyFences.isEmpty, "Expected no regions, got:\(nearbyFences.count)")
        }
        waitForExpectations(timeout: 1) { error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }
    }

    func test_adding_pending_offer_to_cache() {
        let scheduleID = 1234
        let scheduleDeviceID = "5c06804564e26"
        cache.addPendingOffer(scheduleID: scheduleID, scheduleDeviceID: scheduleDeviceID, notificationDwellDelayMs: 0)
        cache.refreshPendingOffers()
        XCTAssertFalse(cache.hasPendingOffers())
        XCTAssertTrue(cache.hasOffers())
    }

    func test_adding_pending_offer_to_cache_where_not_enough_dwell_time() {
        let scheduleID = 1234
        let scheduleDeviceID = "5c06804564e26"
        cache.addPendingOffer(scheduleID: scheduleID, scheduleDeviceID: scheduleDeviceID, notificationDwellDelayMs: 10000)
        cache.refreshPendingOffers()
        XCTAssertTrue(cache.hasPendingOffers())
        XCTAssertFalse(cache.hasOffers())
    }

    func test_adding_pending_offer_to_cache_with_dwell_time() {
        let scheduleID = 1234
        let scheduleDeviceID = "5c06804564e26"
        cache.replaceCache(fenceData)
        cache.addPendingOffer(scheduleID: scheduleID, scheduleDeviceID: scheduleDeviceID, notificationDwellDelayMs: 1)
        Thread.sleep(forTimeInterval: 0.4)
        cache.refreshPendingOffers()
        XCTAssertFalse(cache.hasPendingOffers())
    }

    func test_adding_pending_offer_clear_cache() {
        let scheduleID = 1234
        let scheduleDeviceID = "5c06804564e26"
        cache.addPendingOffer(scheduleID: scheduleID, scheduleDeviceID: scheduleDeviceID, notificationDwellDelayMs: 0)
        cache.refreshPendingOffers()
        XCTAssertFalse(cache.hasPendingOffers())
        XCTAssertTrue(cache.hasOffers())

        cache.clearPendingOffers()
        XCTAssertFalse(cache.hasPendingOffers())
    }

    func test_removing_pending_offer_from_cache() {
        let scheduleID = 1234
        let scheduleDeviceID = "5c06804564e26"
        let identifier = GeoOffersPendingOffer.generateKey(scheduleID: scheduleID, scheduleDeviceID: scheduleDeviceID)
        cache.addPendingOffer(scheduleID: scheduleID, scheduleDeviceID: scheduleDeviceID, notificationDwellDelayMs: 10000)
        cache.removePendingOffer(identifier: identifier)
        cache.refreshPendingOffers()
        XCTAssertFalse(cache.hasPendingOffers())
    }

    func test_adding_push_message() {
        let message = GeoOffersPushData(message: "Hello world", totalParts: 1, scheduleID: 1234, messageIndex: 0, messageID: "messageId1", timestamp: Date().timeIntervalSinceReferenceDate * 1000)
        cache.add(message)

        XCTAssertEqual(cache.count(message.messageID), 1)
        cache.remove(message.messageID)
        XCTAssertEqual(cache.count(message.messageID), 0)
    }

    func test_counting_push_messages() {
        let message = GeoOffersPushData(message: "Hello world", totalParts: 1, scheduleID: 1234, messageIndex: 0, messageID: "messageId1", timestamp: Date().timeIntervalSinceReferenceDate * 1000)
        cache.add(message)

        XCTAssertEqual(cache.count(message.messageID), 1)
        cache.removeAllPushMessages()
        XCTAssertEqual(cache.count(message.messageID), 0)
    }

    func test_retrieving_push_messages() {
        let message1 = GeoOffersPushData(message: "Hello world", totalParts: 3, scheduleID: 1234, messageIndex: 0, messageID: "messageId1", timestamp: Date().timeIntervalSinceReferenceDate * 1000)
        cache.add(message1)
        let message2 = GeoOffersPushData(message: "Hello world", totalParts: 3, scheduleID: 1234, messageIndex: 1, messageID: "messageId1", timestamp: Date().timeIntervalSinceReferenceDate * 1000)
        cache.add(message2)
        let message3 = GeoOffersPushData(message: "Hello world", totalParts: 3, scheduleID: 1234, messageIndex: 2, messageID: "messageId1", timestamp: Date().timeIntervalSinceReferenceDate * 1000)
        cache.add(message3)

        XCTAssertEqual(cache.count(message1.messageID), 3)
        cache.removeAllPushMessages()
        XCTAssertEqual(cache.count(message1.messageID), 0)
    }

    func test_removing_push_messages() {
        let message = GeoOffersPushData(message: "Hello world", totalParts: 1, scheduleID: 1234, messageIndex: 0, messageID: "messageId1", timestamp: Date().timeIntervalSinceReferenceDate * 1000)
        cache.add(message)

        XCTAssertEqual(cache.count(message.messageID), 1)
        cache.removeAllPushMessages()
        XCTAssertEqual(cache.count(message.messageID), 0)
    }

    func test_removeAllPushMessages() {
        let message = GeoOffersPushData(message: "Hello world", totalParts: 1, scheduleID: 1234, messageIndex: 0, messageID: "messageId1", timestamp: Date().timeIntervalSinceReferenceDate * 1000)
        cache.add(message)

        XCTAssertEqual(cache.count(message.messageID), 1)
        cache.removeAllPushMessages()
        XCTAssertEqual(cache.count(message.messageID), 0)
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
        cache.clearCache()
        let json = cache.buildCouponRequestJson(scheduleID: 5139)
        XCTAssertEqual("{}", json)
    }

    func test_cache_deinit() {
        var cache: GeoOffersCacheService? = GeoOffersCacheServiceDefault(apiService: apiService, skipLoad: true)
        XCTAssertNotNil(cache)
        cache = nil
        XCTAssertNil(cache)
    }

    func test_applicationDidEnterBackgroundNotification() {
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
    }

    func test_saveSchedule_no_pending_changes() {
        var cache: GeoOffersCacheService? = GeoOffersCacheServiceDefault(apiService: apiService, savePeriodSeconds: 1)
        XCTAssertNotNil(cache)
        cache = nil
        XCTAssertNil(cache)
    }

    func test_saveSchedule_with_pending_changes() {
        var cache: GeoOffersCacheServiceDefault? = GeoOffersCacheServiceDefault(apiService: apiService, savePeriodSeconds: 1)
        cache?.forcePendingChanges()
        XCTAssertNotNil(cache)
        cache = nil
        XCTAssertNil(cache)
    }

    func test_buildAlreadyDeliveredOfferJson() {
        guard let data = FileLoader.loadTestData(filename: "example-nearby-geofences") else {
            XCTFail("Where's my test data?")
            return
        }

        guard let fenceData = parser.parseNearbyFences(jsonData: data) else {
            XCTFail("Where's my test data?")
            return
        }

        let apiService = MockGeoOffersAPIService()
        let cacheService = GeoOffersCacheServiceDefault(apiService: apiService)
        cacheService.replaceCache(fenceData)

        let json = cacheService.buildAlreadyDeliveredOfferJson()
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

        let apiService = MockGeoOffersAPIService()
        let cacheService = GeoOffersCacheServiceDefault(apiService: apiService)
        cacheService.replaceCache(fenceData)

        let json = cacheService.buildCouponRequestJson(scheduleID: 5139)
        let headline = "Sainsbury's sale"
        let scheduleEndDateString = "22nd February 2019 @ 23:55"

        XCTAssert(json.contains(headline))
        XCTAssert(json.contains(scheduleEndDateString))
    }

    func test_buildListingRequestJson_no_listing() {
        let json = cache.buildListingRequestJson()
        XCTAssertEqual("{}", json)
    }

    func test_getListing() {
        let cache = GeoOffersCacheServiceDefault(apiService: apiService, skipLoad: true)
        let items = cache.listing()
        XCTAssertNil(items)
    }

    func test_schedules_empty() {
        let cache = GeoOffersCacheServiceDefault(apiService: apiService, skipLoad: true)
        let items = cache.schedules()
        XCTAssertTrue(items.isEmpty)
    }

    func test_deliveredSchedules_empty() {
        let cache = GeoOffersCacheServiceDefault(apiService: apiService, skipLoad: true)
        let items = cache.deliveredSchedules()
        XCTAssertTrue(items.isEmpty)
    }

    func test_schedulesFor_empty() {
        let cache = GeoOffersCacheServiceDefault(apiService: apiService, skipLoad: true)
        let items = cache.schedules(for: 1, scheduleDeviceID: "test")
        XCTAssertTrue(items.isEmpty)
    }

    func test_deliveredSchedulesFor_empty() {
        let cache = GeoOffersCacheServiceDefault(apiService: apiService, skipLoad: true)
        let result = cache.deliveredSchedule(for: 1, scheduleDeviceID: "test")
        XCTAssertFalse(result)
    }

    func test_pendingOffer_no_offer() {
        let cache = GeoOffersCacheServiceDefault(apiService: apiService, skipLoad: true)
        let result = cache.pendingOffer("test")
        XCTAssertNil(result)
    }

    func test_pendingOffer_offer() {
        let scheduleID = 1234
        let scheduleDeviceID = "5c06804564e26"
        let key = "\(scheduleID)_\(scheduleDeviceID)"

        cache.addPendingOffer(scheduleID: scheduleID, scheduleDeviceID: scheduleDeviceID, notificationDwellDelayMs: 50000)
        cache.refreshPendingOffers()
        XCTAssertTrue(cache.hasPendingOffers())
        XCTAssertFalse(cache.hasOffers())

        let result = cache.pendingOffer(key)
        XCTAssertNotNil(result)
    }

    func test_offers() {
        let scheduleID = 1234
        let scheduleDeviceID = "5c06804564e26"
        cache.addPendingOffer(scheduleID: scheduleID, scheduleDeviceID: scheduleDeviceID, notificationDwellDelayMs: 0)
        cache.refreshPendingOffers()
        XCTAssertFalse(cache.hasPendingOffers())
        XCTAssertTrue(cache.hasOffers())

        let offers = cache.offers()
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

        let apiService = MockGeoOffersAPIService()
        let cacheService = GeoOffersCacheServiceDefault(apiService: apiService)
        cacheService.replaceCache(fenceData)

        let json = cacheService.buildListingRequestJson()
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
        let apiService = MockGeoOffersAPIService()
        let cacheService = MockGeoOffersCacheServiceDefault(apiService: apiService)
        cacheService.replaceCache(fenceData)

        var offers = [GeoOffersPendingOffer]()
        for schedule in fenceData.deliveredSchedules {
            let offer = GeoOffersPendingOffer(scheduleID: schedule.scheduleID, scheduleDeviceID: schedule.scheduleDeviceID, notificationDwellDelay: 0, createdDate: Date())
            offers.append(offer)
        }
        cacheService.replaceOffers(offers: offers)

        let json = cacheService.buildListingRequestJson()
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
        let apiService = MockGeoOffersAPIService()
        let cacheService = GeoOffersCacheServiceDefault(apiService: apiService)
        cacheService.replaceCache(fenceData)

        let json = cacheService.buildListingRequestJson()
        XCTAssert(!json.contains(authToken))
        XCTAssert(!json.contains(registrationCode))
    }

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
