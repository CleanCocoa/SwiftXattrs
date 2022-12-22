//  Copyright © 2017 Christian Tietze. All rights reserved. Distributed under the MIT License.

import Foundation

func generatedTempFileURL(ext: String? = nil) -> URL {

    let fileName = generatedFileName(ext: ext)
    let fileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)

    return fileURL
}

func generatedFileName(ext: String? = nil) -> String {

    let fileExtension: String
    if let ext = ext {
        fileExtension = ".\(ext)"
    } else {
        fileExtension = ""
    }

    return "swiftxattrs.\(UUID().uuidString)\(fileExtension)"
}

func touch(url: URL) {
    try! "".write(to: url, atomically: false, encoding: .utf8)
}
