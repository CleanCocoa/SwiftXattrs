//  Copyright © 2017 Christian Tietze. All rights reserved. Distributed under the MIT License.

import Foundation

extension URL {
    public subscript(xattrKey: String) -> Data {
        return Data()
    }
}

/// Extension point to add `static var`s of type `Xattr` to for subscript
/// convenience.
open class Xattrs {
    fileprivate init() { }
}

public class Xattr<T>: Xattrs {
    public let name: String

    public init(name: String) {
        self.name = name
        super.init()
    }
}

extension URL {
    public subscript(xattr: Xattr<Data>) -> Data? {
        return nil
    }

    public subscript(xattr: Xattr<String>) -> String? {
        return nil
    }

    public subscript(xattr: Xattr<Int>) -> Int? {
        return nil
    }

    public subscript(xattr: Xattr<[String: Any]>) -> [String: Any]? {
        return nil
    }
}
