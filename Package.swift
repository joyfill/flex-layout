// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FlexLayout",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .tvOS(.v16),
        .watchOS(.v9),
    ],
    products: [
        // Public products — consumers add these as dependencies.
        .library(
            name: "FlexLayout",
            targets: ["FlexLayout"]
        ),
        .library(
            name: "JoyDOM",
            targets: ["JoyDOM"]
        ),
    ],
    targets: [
        // ── Library ────────────────────────────────────────────────────────────
        .target(
            name: "FlexLayout",
            path: "Sources/FlexLayout",
            swiftSettings: [
                // Treat all warnings as errors in release builds to keep the
                // public API surface clean.
                .unsafeFlags(["-warnings-as-errors"], .when(configuration: .release)),
            ]
        ),

        // ── JoyDOM — joyfill/.joy DOM spec → FlexLayout renderer ──────────────
        .target(
            name: "JoyDOM",
            dependencies: ["FlexLayout"],
            path: "Sources/JoyDOM",
            swiftSettings: [
                .unsafeFlags(["-warnings-as-errors"], .when(configuration: .release)),
            ]
        ),

        // ── Demo app (not a library product; local development only) ───────────
        .executableTarget(
            name: "FlexDemoApp",
            dependencies: ["FlexLayout", "JoyDOM"],
            path: "FlexDemoApp"
        ),

        // ── Tests ──────────────────────────────────────────────────────────────
        .testTarget(
            name: "FlexLayoutTests",
            dependencies: ["FlexLayout"],
            path: "Tests/FlexLayoutTests"
        ),
        .testTarget(
            name: "JoyDOMTests",
            dependencies: ["JoyDOM", "FlexLayout"],
            path: "Tests/JoyDOMTests"
        ),
    ]
)
