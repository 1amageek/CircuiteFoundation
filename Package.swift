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
  targets: [
    .target(name: "CircuiteFoundation"),
    .testTarget(
      name: "CircuiteFoundationTests",
      dependencies: ["CircuiteFoundation"],
      resources: [.copy("Fixtures")]
    ),
  ]
)
