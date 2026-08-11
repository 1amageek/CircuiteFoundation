// swift-tools-version: 6.4
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
    ),
    .library(
      name: "CircuiteFoundationFoundation",
      targets: ["CircuiteFoundationFoundation"]
    ),
    .library(
      name: "CircuiteFoundationCrypto",
      targets: ["CircuiteFoundationCrypto"]
    ),
    .library(
      name: "CircuiteFoundationFileSystem",
      targets: ["CircuiteFoundationFileSystem"]
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
      name: "CircuiteFoundation"
    ),
    .target(
      name: "CircuiteFoundationSerialization",
      dependencies: ["CircuiteFoundation"]
    ),
    .target(
      name: "CircuiteFoundationFoundation",
      dependencies: [
        "CircuiteFoundation",
        "CircuiteFoundationSerialization",
      ]
    ),
    .target(
      name: "CircuiteFoundationCrypto",
      dependencies: [
        "CircuiteFoundation",
        .product(
          name: "Crypto",
          package: "swift-crypto",
          condition: .when(platforms: [.macOS, .linux])
        )
      ],
      swiftSettings: [
        .define(
          "CIRCUITE_FOUNDATION_NO_CRYPTO_BACKEND",
          .when(platforms: [.wasi])
        )
      ]
    ),
    .target(
      name: "CircuiteFoundationFileSystem",
      dependencies: [
        "CircuiteFoundation",
        "CircuiteFoundationFoundation",
        "CircuiteFoundationCrypto",
      ]
    ),
    .target(
      name: "CircuiteFoundationPortabilityProbeSupport",
      dependencies: ["CircuiteFoundation"]
    ),
    .executableTarget(
      name: "CircuiteFoundationPortabilityProbe",
      dependencies: ["CircuiteFoundationPortabilityProbeSupport"]
    ),
    .executableTarget(
      name: "CircuiteFoundationEmbeddedPortabilityProbe",
      dependencies: ["CircuiteFoundationPortabilityProbeSupport"],
      linkerSettings: [
        .linkedLibrary("swiftUnicodeDataTables", .when(platforms: [.wasi]))
      ]
    ),
    .target(
      name: "CircuiteFoundationSerializationPortabilityProbeSupport",
      dependencies: [
        "CircuiteFoundation",
        "CircuiteFoundationFoundation",
      ]
    ),
    .executableTarget(
      name: "CircuiteFoundationSerializationPortabilityProbe",
      dependencies: ["CircuiteFoundationSerializationPortabilityProbeSupport"]
    ),
    .target(
      name: "CircuiteFoundationCryptoPortabilityProbeSupport",
      dependencies: [
        "CircuiteFoundation",
        "CircuiteFoundationCrypto",
      ]
    ),
    .executableTarget(
      name: "CircuiteFoundationCryptoPortabilityProbe",
      dependencies: ["CircuiteFoundationCryptoPortabilityProbeSupport"]
    ),
    .executableTarget(
      name: "CircuiteFoundationEmbeddedCryptoPortabilityProbe",
      dependencies: ["CircuiteFoundationCryptoPortabilityProbeSupport"],
      linkerSettings: [
        .linkedLibrary("swiftUnicodeDataTables", .when(platforms: [.wasi]))
      ]
    ),
    .testTarget(
      name: "CircuiteFoundationTests",
      dependencies: [
        "CircuiteFoundation",
        "CircuiteFoundationFoundation",
        "CircuiteFoundationCrypto",
        "CircuiteFoundationFileSystem",
      ],
      resources: [.copy("Fixtures")]
    ),
  ]
)
