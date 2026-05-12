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
    dependencies: [
        // Test-only: snapshot testing. SwiftUI unit tests against `some View`
        // returns are opaque — they can't catch visual regressions like the
        // ones that surfaced in PRs #20, #21, #26. snapshot-testing renders
        // a view to a bitmap, diffs against a committed baseline, and fails
        // on any pixel-level change.
        .package(
            url: "https://github.com/pointfreeco/swift-snapshot-testing",
            from: "1.17.0"
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

        // ── JoyDOM sample specs — internal target shipping the per-property
        //     sample JSON payloads (one per spec property) plus the Swift API
        //     used by both the demo app and tests. NOT exposed as a library
        //     product so external JoyDOM consumers don't pull the resources.
        .target(
            name: "JoyDOMSampleSpecs",
            dependencies: ["JoyDOM"],
            path: "Sources/JoyDOMSampleSpecs",
            resources: [
                // `.copy` preserves the per-category subdirectory layout in
                // Bundle.module so files with the same basename across
                // categories (e.g. sizing/width.json + breakpoints/width.json)
                // don't collide. The loader uses `subdirectory:` to look them
                // up by category folder.
                .copy("Resources")
            ]
        ),

        // ── Demo app (not a library product; local development only) ───────────
        .executableTarget(
            name: "FlexDemoApp",
            dependencies: ["FlexLayout", "JoyDOM", "JoyDOMSampleSpecs"],
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
            dependencies: [
                "JoyDOM",
                "FlexLayout",
                "JoyDOMSampleSpecs",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
            ],
            path: "Tests/JoyDOMTests"
        ),
    ]
)
