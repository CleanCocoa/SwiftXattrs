// swift-tools-version: 5.5

import PackageDescription

let package = Package(
  name: "SwiftXattrs",
  platforms: [
    .macOS("10.13"),
  ],
  products: [
    .library(
      name: "SwiftXattrs",
      targets: ["SwiftXattrs"]),
  ],
  targets: [
    .target(
      name: "SwiftXattrs",
      dependencies: []),
    .testTarget(
      name: "SwiftXattrsTests",
      dependencies: ["SwiftXattrs"]),
  ]
)
