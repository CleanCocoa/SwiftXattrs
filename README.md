# SwiftXattrs

![Swift 4.2](https://img.shields.io/badge/Swift-4.2-blue.svg?style=flat)
![Version](https://img.shields.io/github/tag/CleanCocoa/SwiftXattrs.svg?style=flat)
![License](https://img.shields.io/github/license/CleanCocoa/SwiftXattrs.svg?style=flat)
![Platform](https://img.shields.io/badge/platform-macOS-lightgrey.svg?style=flat)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

Micro-Framework to offer a way more convenient way to read and write extended file attributes (xattrs) on files in Swift. 

## Example

For maximum convenience, define regular used extended attributes as extensions to `Xattrs.Attributes`:

```swift
extension Xattrs.Attributes {
    static var authorName: Xattr<String> { return Xattr(name: "authorName") }
}
```

Then use the `Xattrs` subscript accessors to read and write values:

```swift
// Type annotations added to clarify the API
let url: URL = // ... 
let xattrs = Xattrs(url: url)

let originalAuthor: String? = xattrs[.authorName]
print(originalAuthor)

let plagiarizer = "Karl-Theodor zu Guttenberg"
xattrs[.authorName] = plagiarizer
print(xattrs[.authorName]) // "Karl-Theodor zu Guttenberg" 
```

You do not need to keep the lightweight `Xattrs` object around if you quickly need to change or read a value:

```swift
Xattrs(url: url)[.authorName] = "John Doe"
```

### Less Convenient Example

The `Xattrs` subscript will return optional values instead of emitting errors. If you need more control, you can have it!

The underlying accessors are defined as extensions to `URL`:

- `URL.extendedAttribute(forName:) throws -> Data`
- `URL.setExtendedAttribute(data:forName:) throws`
- `URL.removeExtendedAttribute(forName:) throws`

```swift
let url: URL = // ...

do {
    let data = try url.extendedAttribute(forName: "com.apple.TextEncoding")
    // decode data etc.
} catch {
    print(error.localizedDescription)
}
```

## Extending Xattrs to support more types

The `Xattrs` type defines a general-purpose subscript as a wrapper for the aforementioned URL extension:

- `Xattrs.subscript(xattrKey: String) -> Data?`

You can use this as the basis for serializing and deserializing your own types.

`Xattrs` also comes with wrappers for `NSKeyedArchiver`'s object-based encoding and decoding. It's super simple to utilize that part of the API for arbirtrary objects:

```swift
extension Xattrs {
    public subscript(xattr: Xattr<Banana>) -> Banana? {
        get { return decode(xattrKey: xattr.name) }
        set { storeEncoded(xattrKey: xattr.name, value: newValue) }
    }
}
```

Until Swift supports generic subscripts like `subscript<T>(xattr: Xattr<T>) -> T?`, we have to define all supported types using extensions.


## Attributions

The base of all this are the extensions on `URL`, written by [Martin R](https://stackoverflow.com/users/1187415/martin-r) in an [answer on StackOverflow](https://stackoverflow.com/a/38343753/1460929).


## Code License

Copyright (c) 2017 Christian Tietze. Distributed under the MIT License.
