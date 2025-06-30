// swift-tools-version: 6.2

import PackageDescription

let package = Package(
  name: "Packages",
  defaultLocalization: "en-US",
  platforms: [
    .iOS(.v26),
  ],
  products: [
    .singleTargetLibrary("Models"),
    .singleTargetLibrary("PadiddleCore"),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-algorithms", exact: "1.2.1"),
    .package(url: "https://github.com/pointfreeco/swift-composable-architecture", exact: "1.20.2"),
    .package(url: "https://github.com/pointfreeco/swift-identified-collections", exact: "1.1.1"),
    .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", exact: "1.18.4"),
    .package(url: "https://github.com/pointfreeco/xctest-dynamic-overlay", exact: "1.5.2"),
  ],
  targets: [
    .target(
      name: "Models",
      dependencies: [
        .identifiedCollections,
      ],
      resources: [
        .process("Resources"),
      ],
    ),
    .testTarget(
      name: "ModelsTests",
      dependencies: [
        .models,
        .testHelpers,
      ]
    ),
    .target(
      name: "PadiddleCore",
      dependencies: [
        .algorithms,
        .models,
        .tca,
        .utilities,
      ],
      resources: [
        .process("Resources"),
      ],
    ),
    .testTarget(
      name: "PadiddleCoreTests",
      dependencies: [
        .issueReportingTestSupport,
        "PadiddleCore",
      ]
    ),
    .target(
      name: "TestHelpers",
      dependencies: [
        .snapshotTesting,
      ]
    ),
    .target(
      name: "Utilities",
      dependencies: [
        .tca,
      ]
    ),
  ]
)

extension Product {
  static func singleTargetLibrary(
    _ name: String,
    type: Library.LibraryType? = nil
  ) -> Product {
    .library(name: name, type: type, targets: [name])
  }
}

@MainActor
extension Target.Dependency {
  // Please keep these sections and sub-sections alphabetized!
  // Internal

  static let models: Self = "Models"
  static let testHelpers: Self = "TestHelpers"
  static let utilities: Self = "Utilities"

  // External

  static let algorithms: Self = .product(name: "Algorithms", package: "swift-algorithms")
  static let identifiedCollections: Self = .product(name: "IdentifiedCollections", package: "swift-identified-collections")
  static let issueReportingTestSupport: Self = .product(name: "IssueReportingTestSupport", package: "xctest-dynamic-overlay")
  static let snapshotTesting: Self = .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
  static let tca: Self = .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
}
