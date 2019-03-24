//  Copyright © 2019 Zappit. All rights reserved.

@testable import GeoOffersSDK
import XCTest

class FileManagerExtensionTests: XCTestCase {
    private let fileManager = MockFileManager()

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_no_documentDirectory_path() {
        fileManager.documentPathURL = nil
        XCTAssertThrowsError(try fileManager.documentPath(for: "Testing.txt")) { error in
            XCTAssertEqual(error as! FileManagerError, FileManagerError.missingDocumentDirectory)
        }
    }

    func test_failedToCreateDirectory() {
        fileManager.fileExistsResponse = false
        fileManager.createFileError = FileManagerError.failedToCreateDirectory
        XCTAssertThrowsError(try fileManager.documentPath(for: "Testing.txt")) { error in
            XCTAssertEqual(error as! FileManagerError, FileManagerError.missingDocumentDirectory)
        }
    }

//    func test_initialise_cache_service_where_create_save_file_fails() {
//        fileManager.documentPathURL = nil
//        let apiService = MockGeoOffersAPIService()
//        let service = GeoOffersCacheServiceDefault(fileManager: fileManager, apiService: apiService)
//        service.remove("")
//    }
}
