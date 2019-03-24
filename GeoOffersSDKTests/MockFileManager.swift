//  Copyright © 2019 Zappit. All rights reserved.

import Foundation
@testable import GeoOffersSDK

class MockFileManager: FileManager {
    var documentPathURL: URL?
    var fileExistsResponse = false
    var createFileError: Error?
    
    override func urls(for _: FileManager.SearchPathDirectory, in _: FileManager.SearchPathDomainMask) -> [URL] {
        guard let url = documentPathURL else { return [] }
        return [url]
    }
    
    override func fileExists(atPath _: String) -> Bool {
        return fileExistsResponse
    }
    
    override func createDirectory(at _: URL, withIntermediateDirectories _: Bool, attributes _: [FileAttributeKey: Any]? = nil) throws {
        if let error = createFileError {
            throw error
        }
    }
}
