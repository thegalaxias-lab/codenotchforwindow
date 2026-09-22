// swift-tools-version: 5.9
// A local SwiftPM manifest so the module builds and tests without XcodeGen
// (`swift build` / `swift test` with just the Command Line Tools). The
// shipping app is still produced by `make build`; this file only mirrors it:
// same deployment target, same dependencies, same sources.
import PackageDescription

let package = Package(
    name: "Codenotch",
    platforms: [.macOS("15.0")],
    products: [
        .executable(name: "Codenotch", targets: ["Codenotch"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio", from: "2.102.0"),
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.6.0"),
    ],
    targets: [
        // The C decoder Xcode compiles through the bridging header; SwiftPM
        // needs it as its own target. Swift reaches it through the conditional
        // import at the top of ClaudeDesktopUsageCache.swift, which the Xcode
        // path does not see.
        .target(
            name: "CodenotchZstd",
            path: "Sources/Vendor/zstd",
            exclude: ["README.md", "LICENSE"],
            publicHeadersPath: "."
        ),
        .executableTarget(
            name: "Codenotch",
            dependencies: [
                .product(name: "Sparkle", package: "Sparkle"),
                .product(name: "NIOHTTP1", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
                .target(name: "CodenotchZstd"),
            ],
            path: "Sources",
            exclude: [
                "Vendor",
                "Codenotch-Bridging-Header.h",
                "Info.plist",
                // Xcode-only resources: compiling these needs actool /
                // xcstringstool, which the Command Line Tools do not ship.
                // They are absent from this build only; `make build` includes
                // them as always.
                "Assets.xcassets",
                "Localizable.xcstrings",
            ],
            resources: [
                // Declared so SwiftPM stops warning; carried verbatim.
                .copy("Resources")
            ]
        ),
        .testTarget(
            name: "CodenotchTests",
            dependencies: ["Codenotch"],
            path: "Tests"
        ),
    ]
)
