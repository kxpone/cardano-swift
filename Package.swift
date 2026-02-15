// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Cardano",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "Cardano",
            targets: ["Cardano"]),
    ],
    dependencies: [
        .package(url: "https://github.com/tesseract-one/Bip39.swift.git", from: "0.2.0"),
    ],
    targets: [
        .target(
            name: "CCardano",
            path: "Sources/CCardano"
        ),
        .target(
            name: "Cardano",
            dependencies: [
                .product(name: "Bip39", package: "Bip39.swift"),
                "CCardano"
            ],
            linkerSettings: [
                .linkedLibrary("react_native_haskell_shelley"),
                .unsafeFlags(["-L", "Sources/CCardano/linux"], .when(platforms: [.linux])),
                .unsafeFlags(["-L", "Sources/CCardano/darwin"], .when(platforms: [.macOS, .iOS, .watchOS, .tvOS])),
                .linkedLibrary("dl", .when(platforms: [.linux])),
                .linkedLibrary("pthread", .when(platforms: [.linux])),
                .linkedLibrary("m", .when(platforms: [.linux]))
            ]),
        .testTarget(
            name: "CardanoTests",
            dependencies: ["Cardano"]),
    ]
)

// Check if native bridge exists, otherwise prompt user (SPM doesn't support prepare_command)
import Foundation
let bridgePath = URL(fileURLWithPath: #file).deletingLastPathComponent().appendingPathComponent("Sources/CCardano/include/react_native_haskell_shelley.h").path
if !FileManager.default.fileExists(atPath: bridgePath) {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/bin/bash")
    process.currentDirectoryURL = URL(fileURLWithPath: URL(fileURLWithPath: #file).deletingLastPathComponent().path)
    process.arguments = ["scripts/init.sh"]
    try? process.run()
    process.waitUntilExit()
}
