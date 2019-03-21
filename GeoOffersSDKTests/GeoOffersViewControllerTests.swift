//  Copyright © 2019 Zappit. All rights reserved.

@testable import GeoOffersSDK
import UIKit
import XCTest

class GeoOffersViewControllerTests: XCTestCase {
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_that_the_viewcontroller_loads_successfully() {
        let storyboard = UIStoryboard(name: "GeoOffersSDK", bundle: Bundle(for: GeoOffersViewController.self))
        guard let viewController = storyboard.instantiateInitialViewController() as? GeoOffersViewController else {
            XCTFail("Failed to load offers view controller")
            return
        }

        let url = URL(string: "https://www.apple.com")!
        viewController.loadRequest(url: url, javascript: "", querystring: "")
        _ = viewController.view

        XCTAssertTrue(viewController.pageLoaded)
        XCTAssertNil(viewController.pendingURL)
    }

    func test_loading_request_after_page_load() {
        let storyboard = UIStoryboard(name: "GeoOffersSDK", bundle: Bundle(for: GeoOffersViewController.self))
        guard let viewController = storyboard.instantiateInitialViewController() as? GeoOffersViewController else {
            XCTFail("Failed to load offers view controller")
            return
        }

        let url = URL(string: "https://www.apple.com")!
        XCTAssertFalse(viewController.pageLoaded)
        _ = viewController.view

        XCTAssertTrue(viewController.pageLoaded)
        XCTAssertNil(viewController.pendingURL)

        viewController.loadRequest(url: url, javascript: "", querystring: "")

        XCTAssertNil(viewController.pendingURL)
    }
}
