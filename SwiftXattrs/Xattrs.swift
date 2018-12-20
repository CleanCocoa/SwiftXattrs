//  Copyright © 2017 Christian Tietze. All rights reserved. Distributed under the MIT License.

import Foundation

extension URL {

    /// Wrap the xattr functions's POSIX error codes in `NSError` instances.
    ///
    /// - note: Originally written by Martin R on StackOverflow: <https://stackoverflow.com/a/38343753/1460929>
    /// - parameter err: POSIX error code.
    /// - returns: NSError in the `NSPOSIXErrorDomain` with the code `err` and `userInfo` with a default localized description for the error code.
    private static func posixError(_ err: Int32) -> NSError {
        return NSError(domain: NSPOSIXErrorDomain, code: Int(err),
                       userInfo: [NSLocalizedDescriptionKey: String(cString: strerror(err))])
    }

    /// Extended attribute data.
    ///
    /// - note: Originally written by Martin R on StackOverflow: <https://stackoverflow.com/a/38343753/1460929>
    /// - parameter name: Attribute name
    /// - throws: `NSError` in the `NSPOSIXErrorDomain` when no attribute of `name` was found.
    /// - returns: Data representation of the attribute's value.
    public func extendedAttribute(forName name: String) throws -> Data  {

        let data = try self.withUnsafeFileSystemRepresentation { fileSystemPath -> Data in

            // Determine attribute size:
            let length = getxattr(fileSystemPath, name, nil, 0, 0, 0)
            guard length != -1 else { throw URL.posixError(errno) }
            guard let buffer = malloc(length) else { throw URL.posixError(errno) }

            defer { free(buffer) }
            let result = getxattr(fileSystemPath, name, buffer, length, 0, 0)

            guard result != -1 else { throw URL.posixError(errno) }
            return Data(bytes: buffer, count: length)
        }
        return data
    }

    /// Set or overwrite an extended attribute.
    ///
    /// - note: Originally written by Martin R on StackOverflow: <https://stackoverflow.com/a/38343753/1460929>
    /// - parameter data: Data representation of any value to be stored in the xattrs.
    /// - parameter name: Attribute name
    /// - throws: `NSError` in the `NSPOSIXErrorDomain` when writing the attribute failed.
    public func setExtendedAttribute(data: Data, forName name: String) throws {

        try self.withUnsafeFileSystemRepresentation { fileSystemPath in
            let result = data.withUnsafeBytes {
                setxattr(fileSystemPath, name, $0, data.count, 0, 0)
            }
            guard result >= 0 else { throw URL.posixError(errno) }
        }
    }

    /// Removed the extended attribute of `name`.
    ///
    /// - note: Originally written by Martin R on StackOverflow: <https://stackoverflow.com/a/38343753/1460929>
    /// - parameter name: Attribute name to remove.
    /// - throws: `NSError` in the `NSPOSIXErrorDomain`.
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

    /// Attempt to decode an attribute as object, if it exists, and cast it to `T`.
    ///
    /// - parameter xattrKey: The extended attribute's name.
    /// - returns: Decoded object or `nil` if the attribute was not found or its type does not match.
    public func decode<T>(xattrKey: String) -> T? {
        guard let data = self[xattrKey: xattrKey] else { return nil }
        return NSKeyedUnarchiver.unarchiveObject(with: data) as? T
    }

    /// Encode the object as `Data` using `NSKeyedArchiver` or
    /// remove existing values.
    ///
    /// - parameter xattrKey: The extended attribute's name.
    /// - parameter value: Object to encode. Pass `nil` to remove the attribute.
    public func storeEncoded(xattrKey: String, value: Any?) {

        guard let newValue = value else {
            self[xattrKey: xattrKey] = nil
            return
        }

        self[xattrKey: xattrKey] = NSKeyedArchiver.archivedData(withRootObject: newValue)
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
