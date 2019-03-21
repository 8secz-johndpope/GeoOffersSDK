//  Copyright © 2019 Zappit. All rights reserved.

import Foundation
@testable import GeoOffersSDK

class FileLoader {
    static func loadTestData(filename: String, withExtension: String = "json") -> Data? {
        guard let url = Bundle(for: FileLoader.self).url(forResource: filename, withExtension: withExtension) else {
            fatalError("Missing file: \(filename).\(withExtension)")
        }
        do {
            let jsonData = try Data(contentsOf: url)
            return jsonData
        } catch {
            fatalError("Failed to load file: \(filename).\(withExtension)")
        }

        return nil
    }

    static func loadTestRegions(filename: String = "example-geofences") -> [GeoOffersGeoFence] {
        guard let url = Bundle(for: FileLoader.self).url(forResource: filename, withExtension: "json") else {
            fatalError("Missing file: \(filename).json")
        }
        do {
            let jsonData = try Data(contentsOf: url)
            let jsonDecoder = JSONDecoder()
            let regions = try jsonDecoder.decode([GeoOffersGeoFence].self, from: jsonData)
            return regions
        } catch {
            fatalError("Failed to load file: \(filename).json")
        }

        return []
    }
}
