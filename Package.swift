// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "JobTracker",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "JobTracker", targets: ["JobTracker"]),
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "6.29.0"),
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.19"),
    ],
    targets: [
        .executableTarget(
            name: "JobTracker",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift"),
                "ZIPFoundation",
            ],
            path: "Sources/JobTracker"
        ),
    ]
) 
