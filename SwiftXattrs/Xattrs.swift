//  Copyright © 2017 Christian Tietze. All rights reserved. Distributed under the MIT License.

import Foundation

extension URL {

    /// Helper function to create an NSError from a Unix errno.
    private static func posixError(_ err: Int32) -> NSError {
        return NSError(domain: NSPOSIXErrorDomain, code: Int(err),
                       userInfo: [NSLocalizedDescriptionKey: String(cString: strerror(err))])
    }

    public func extendedAttribute(forName name: String) throws -> Data  {

        let data = try self.withUnsafeFileSystemRepresentation { fileSystemPath -> Data in

            // Determine attribute size:
            let length = getxattr(fileSystemPath, name, nil, 0, 0, 0)
            guard length >= 0 else { throw URL.posixError(errno) }

            // Create buffer with required size:
            var data = Data(count: length)

            // Retrieve attribute:
            let result =  data.withUnsafeMutableBytes {
                getxattr(fileSystemPath, name, $0, data.count, 0, 0)
            }
            guard result >= 0 else { throw URL.posixError(errno) }
            return data
        }
        return data
    }

    public func setExtendedAttribute(data: Data, forName name: String) throws {

        try self.withUnsafeFileSystemRepresentation { fileSystemPath in
            let result = data.withUnsafeBytes {
                setxattr(fileSystemPath, name, $0, data.count, 0, 0)
            }
            guard result >= 0 else { throw URL.posixError(errno) }
        }
    }

    public func removeExtendedAttribute(forName name: String) throws {

        try self.withUnsafeFileSystemRepresentation { fileSystemPath in
            let result = removexattr(fileSystemPath, name, 0)
            guard result >= 0 else { throw URL.posixError(errno) }
        }
    }
}

public class Xattrs {

    public let url: URL

    public init(url: URL) {
        self.url = url
    }

    public subscript(xattrKey name: String) -> Data? {
        get {
            return try? url.extendedAttribute(forName: name)
        }

        set {
            guard let newValue = newValue else {
                try? url.removeExtendedAttribute(forName: name)
                return
            }
            try? url.setExtendedAttribute(data: newValue, forName: name)
        }
    }

    /// Extension point to add `static var`s of type `Xattr` to for subscript
    /// convenience.
    open class Attributes {
        fileprivate init() { }
    }
}

public class Xattr<T>: Xattrs.Attributes {
    public let name: String

    public init(name: String) {
        self.name = name
        super.init()
    }
}

extension Xattrs {
    public subscript(xattr: Xattr<Data>) -> Data? {
        get { return self[xattrKey: xattr.name] }
        set { self[xattrKey: xattr.name] = newValue }
    }

    public subscript(xattr: Xattr<String>) -> String? {
        get { return self[xattrKey: xattr.name].flatMap { String(data: $0, encoding: .utf8) } }
        set { self[xattrKey: xattr.name] = newValue?.data(using: .utf8) }
    }

    public subscript(xattr: Xattr<Int>) -> Int? {
        get { return decode(xattrKey: xattr.name) }
        set { storeEncoded(xattrKey: xattr.name, value: newValue) }
    }

    public subscript(xattr: Xattr<Double>) -> Double? {
        get { return decode(xattrKey: xattr.name) }
        set { storeEncoded(xattrKey: xattr.name, value: newValue) }
    }

    fileprivate func decode<T>(xattrKey: String) -> T? {
        guard let data = self[xattrKey: xattrKey] else { return nil }
        let unarchiver = NSKeyedUnarchiver(forReadingWith: data)
        return unarchiver.decodeObject(forKey: xattrKey) as? T
    }

    fileprivate func storeEncoded(xattrKey: String, value: Any?) {

        guard let newValue = value else {
            self[xattrKey: xattrKey] = nil
            return
        }

        let archiver = NSKeyedArchiver()
        archiver.encode(newValue, forKey: xattrKey)
        self[xattrKey: xattrKey] = archiver.encodedData
    }
}

// MARK: Collections and Dictionaries

extension Xattrs {

    public subscript(xattr: Xattr<[String: Any]>) -> [String: Any]? {
        get { return decode(xattrKey: xattr.name) }
        set { storeEncoded(xattrKey: xattr.name, value: newValue) }
    }

    public subscript(xattr: Xattr<[String]>) -> [String]? {
        get { return decode(xattrKey: xattr.name) }
        set { storeEncoded(xattrKey: xattr.name, value: newValue) }
    }

    public subscript(xattr: Xattr<[Int]>) -> [Int]? {
        get { return decode(xattrKey: xattr.name) }
        set { storeEncoded(xattrKey: xattr.name, value: newValue) }
    }
}
