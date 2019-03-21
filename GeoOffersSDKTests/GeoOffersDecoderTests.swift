//  Copyright © 2019 Zappit. All rights reserved.

@testable import GeoOffersSDK
import XCTest

struct Person: Codable {
    let name: String
    let likes: [String]
    let hobbies: [String: [String]]

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        name = try values.decode(String.self, forKey: .name)
        likes = values.geoDecode([String].self, forKey: .likes) ?? []
        hobbies = values.geoDecode([String: [String]].self, forKey: .hobbies) ?? [:]
    }
}

class GeoOffersDecoderTests: XCTestCase {
    override func setUp() {}

    override func tearDown() {}

    private func parse<T>(_ jsonData: Data) -> T? where T: Decodable {
        let decoder = JSONDecoder()
        var data: T?
        do {
            data = try decoder.decode(T.self, from: jsonData)
        } catch {
            geoOffersLog("\(error)")
        }
        return data
    }

    func test_decodeArrayAsDictionary() {
        guard let jsonData = FileLoader.loadTestData(filename: "person1"),
            let person: Person = parse(jsonData) else {
            XCTFail("Could not load test data")
            return
        }

        XCTAssertEqual(person.name, "Bob")
        XCTAssertTrue(!person.likes.isEmpty)
        XCTAssertTrue(!person.hobbies.isEmpty)
    }

    func test_decodeDictionaryAsArray() {
        guard let jsonData = FileLoader.loadTestData(filename: "person1"),
            let person: Person = parse(jsonData) else {
            XCTFail("Could not load test data")
            return
        }

        XCTAssertEqual(person.name, "Bob")
        XCTAssertTrue(!person.likes.isEmpty)
        XCTAssertTrue(!person.hobbies.isEmpty)
    }

    func test_decodeArrayAsArray() {
        guard let jsonData = FileLoader.loadTestData(filename: "person2"),
            let person: Person = parse(jsonData) else {
            XCTFail("Could not load test data")
            return
        }

        XCTAssertEqual(person.name, "Bob")
        XCTAssertTrue(!person.likes.isEmpty)
        XCTAssertTrue(person.hobbies.isEmpty)
    }

    func test_decodeDictionaryAsDictionary() {
        guard let jsonData = FileLoader.loadTestData(filename: "person1"),
            let person: Person = parse(jsonData) else {
            XCTFail("Could not load test data")
            return
        }

        XCTAssertEqual(person.name, "Bob")
        XCTAssertTrue(!person.likes.isEmpty)
        XCTAssertTrue(!person.hobbies.isEmpty)
    }

    func test_decodeArrayAsNull() {
        guard let jsonData = FileLoader.loadTestData(filename: "person1"),
            let person: Person = parse(jsonData) else {
            XCTFail("Could not load test data")
            return
        }

        XCTAssertEqual(person.name, "Bob")
        XCTAssertTrue(!person.likes.isEmpty)
        XCTAssertTrue(!person.hobbies.isEmpty)
    }

    func test_decodeDictionaryAsNull() {
        guard let jsonData = FileLoader.loadTestData(filename: "person1"),
            let person: Person = parse(jsonData) else {
            XCTFail("Could not load test data")
            return
        }

        XCTAssertEqual(person.name, "Bob")
        XCTAssertTrue(!person.likes.isEmpty)
        XCTAssertTrue(!person.hobbies.isEmpty)
    }
}
