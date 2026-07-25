// swift-tools-version: 6.3
import PackageDescription

let package = Package(
  name: "CircuiteFoundation",
  platforms: [
    .macOS(.v14)
  ],
  products: [
    .library(
      name: "CircuiteFoundation",
      targets: ["CircuiteFoundation"]
    )
  ],
  dependencies: [
    .package(
      url: "https://github.com/apple/swift-crypto.git",
      exact: "4.5.1"
    )
  ],
  targets: [
    .target(
      name: "CircuiteFoundation",
      dependencies: [
        .product(name: "Crypto", package: "swift-crypto")
      ]
    ),
    .testTarget(
      name: "CircuiteFoundationTests",
      dependencies: ["CircuiteFoundation"],
      resources: [.copy("Fixtures")]
    ),
  ]
)
