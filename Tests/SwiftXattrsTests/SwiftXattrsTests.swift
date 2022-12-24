//  Copyright © 2017 Christian Tietze. All rights reserved. Distributed under the MIT License.

import XCTest
@testable import SwiftXattrs

extension Xattrs.Attributes {
    static var testString: Xattr<String> { return Xattr(name: "teststring") }
    static var testInteger: Xattr<Int> { return Xattr(name: "testinteger") }
    static var testDictionary: Xattr<[String: Any]> { return Xattr(name: "testdict") }
}

class SwiftXattrsTests: XCTestCase {

    func testStringXattr() throws {

        let url = generatedTempFileURL()
        touch(url: url)
        let xattrs = Xattrs(url: url)

        // Precondition

        try XCTAssertThrowsError(url.extendedAttribute(forName: Xattrs.Attributes.testString.name)) { error in
            let error = error as NSError
            XCTAssertEqual(error.domain, NSPOSIXErrorDomain)
            XCTAssertEqual(error.code, 93)
            XCTAssert(error.description.lowercased().contains("not found"))
        }

        XCTAssertNil(xattrs[.testString])

        // Writing

        xattrs[.testString] = "Foo"

        let initialData = try url.extendedAttribute(forName: Xattrs.Attributes.testString.name)
        XCTAssertEqual(String(data: initialData, encoding: .utf8), "Foo")

        // Reading

        XCTAssertEqual(xattrs[.testString], "Foo")
    }

    func testIntegerXattr() throws {

        let url = generatedTempFileURL()
        touch(url: url)
        let xattrs = Xattrs(url: url)

        // Precondition

        try XCTAssertThrowsError(url.extendedAttribute(forName: Xattrs.Attributes.testInteger.name)) { error in
            let error = error as NSError
            XCTAssertEqual(error.domain, NSPOSIXErrorDomain)
            XCTAssertEqual(error.code, 93)
            XCTAssert(error.description.lowercased().contains("not found"))
        }

        XCTAssertNil(xattrs[.testInteger])

        // Writing

        xattrs[.testInteger] = 1337

        let initialData = try url.extendedAttribute(forName: Xattrs.Attributes.testInteger.name)
        let number = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSNumber.self, from: initialData)
        let intValue = try XCTUnwrap(number as? Int)
        XCTAssertEqual(intValue, 1337)

        // Reading

        XCTAssertEqual(xattrs[.testInteger], 1337)
    }

    func testDictionaryXattr() throws {

        let url = generatedTempFileURL()
        touch(url: url)
        let xattrs = Xattrs(url: url)

        // Precondition

        try XCTAssertThrowsError(url.extendedAttribute(forName: Xattrs.Attributes.testDictionary.name)) { error in
            let error = error as NSError
            XCTAssertEqual(error.domain, NSPOSIXErrorDomain)
            XCTAssertEqual(error.code, 93)
            XCTAssert(error.description.lowercased().contains("not found"))
        }

        XCTAssertNil(xattrs[.testDictionary])

        // Writing

        let value: [String: Any] = ["power" : 100]
        xattrs[.testDictionary] = value

        let initialData = try url.extendedAttribute(forName: Xattrs.Attributes.testDictionary.name)
        let nsDictionary = try XCTUnwrap(NSKeyedUnarchiver.unarchivedObject(ofClass: NSDictionary.self, from: initialData))
        // Bridging the NSDictionary  to Swift manually:
        let dictionary: [String: Any] = try {
            var result: [String: Any] = [:]
            for key in nsDictionary.allKeys {
                let key = try XCTUnwrap(key as? String)
                result[key] = nsDictionary.value(forKey: key)
            }
            return result
        }()
        XCTAssertEqual(Array(dictionary.keys), ["power"])
        XCTAssertEqual(dictionary["power"] as? Int, 100)

        // Reading

        let testDictionary = try XCTUnwrap(xattrs[.testDictionary], "Expected encoded dictionary")
        XCTAssertEqual(Array(testDictionary.keys), ["power"])
        XCTAssertEqual(testDictionary["power"] as? Int, 100)
    }
}
