//  Copyright © 2017 Christian Tietze. All rights reserved. Distributed under the MIT License.

import XCTest
@testable import SwiftXattrs

extension Xattrs.Attributes {
    static var testString: Xattr<String> { return Xattr(name: "teststring") }
    static var testInteger: Xattr<Int> { return Xattr(name: "testinteger") }
    static var testDictionary: Xattr<[String: Any]> { return Xattr(name: "testdict") }
}

class SwiftXattrsTests: XCTestCase {

    func testStringXattr() {

        let url = generatedTempFileURL()
        touch(url: url)
        let xattrs = Xattrs(url: url)

        // Precondition

        do {
            _ = try url.extendedAttribute(forName: Xattrs.Attributes.testString.name)
        } catch let error as NSError {
            XCTAssertEqual(error.domain, NSPOSIXErrorDomain)
            XCTAssertEqual(error.code, 93)
            XCTAssert(error.description.lowercased().contains("not found"))
        }

        XCTAssertNil(xattrs[.testString])

        // Writing

        xattrs[.testString] = "Foo"

        do {
            let initialData = try url.extendedAttribute(forName: Xattrs.Attributes.testString.name)
            XCTAssertEqual(String(data: initialData, encoding: .utf8), "Foo")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        // Reading

        XCTAssertEqual(xattrs[.testString], "Foo")
    }

    func testIntegerXattr() {

        let url = generatedTempFileURL()
        touch(url: url)
        let xattrs = Xattrs(url: url)

        // Precondition

        do {
            _ = try url.extendedAttribute(forName: Xattrs.Attributes.testInteger.name)
        } catch let error as NSError {
            XCTAssertEqual(error.domain, NSPOSIXErrorDomain)
            XCTAssertEqual(error.code, 93)
            XCTAssert(error.description.lowercased().contains("not found"))
        }

        XCTAssertNil(xattrs[.testInteger])

        // Writing

        xattrs[.testInteger] = 1337

        do {
            let initialData = try url.extendedAttribute(forName: Xattrs.Attributes.testInteger.name)
            XCTAssertEqual(NSKeyedUnarchiver.unarchiveObject(with: initialData) as? Int, 1337)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        // Reading

        XCTAssertEqual(xattrs[.testInteger], 1337)
    }

    func testDictionaryXattr() {

        let url = generatedTempFileURL()
        touch(url: url)
        let xattrs = Xattrs(url: url)

        // Precondition

        do {
            _ = try url.extendedAttribute(forName: Xattrs.Attributes.testDictionary.name)
        } catch let error as NSError {
            XCTAssertEqual(error.domain, NSPOSIXErrorDomain)
            XCTAssertEqual(error.code, 93)
            XCTAssert(error.description.lowercased().contains("not found"))
        }

        XCTAssertNil(xattrs[.testDictionary])

        // Writing

        let value: [String: Any] = ["power" : 100]
        xattrs[.testDictionary] = value

        do {
            let initialData = try url.extendedAttribute(forName: Xattrs.Attributes.testDictionary.name)
            if let dictionary = NSKeyedUnarchiver.unarchiveObject(with: initialData) as? [String: Any] {
                XCTAssertEqual(Array(dictionary.keys), ["power"])
                XCTAssertEqual(dictionary["power"] as? Int, 100)
            } else {
                XCTFail("Expected encoded dictionary")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        // Reading

        if let dictionary = xattrs[.testDictionary] {
            XCTAssertEqual(Array(dictionary.keys), ["power"])
            XCTAssertEqual(dictionary["power"] as? Int, 100)
        } else {
            XCTFail("Expected encoded dictionary")
        }
    }

}
