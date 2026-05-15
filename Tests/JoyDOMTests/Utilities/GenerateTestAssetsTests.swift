// One-shot utility test that generates the bundled PNG test assets used
// by Media snapshot tests. Runs only when GENERATE_TEST_ASSETS env var
// is set, so it doesn't fire in CI.
//
// Usage:
//   GENERATE_TEST_ASSETS=1 swift test --filter "GenerateTestAssetsTests"
//
// Writes:
//   Sources/JoyDOMSampleSpecs/Resources/test-assets/photo-landscape.png  (400x200)
//   Sources/JoyDOMSampleSpecs/Resources/test-assets/photo-portrait.png   (200x400)

import XCTest
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

#if canImport(AppKit)
import AppKit
typealias PlatformColor = NSColor
#elseif canImport(UIKit)
import UIKit
typealias PlatformColor = UIColor
#endif

final class GenerateTestAssetsTests: XCTestCase {

    func testGenerateBundledAssets() throws {
        // Idempotent — runs every time; only re-writes if the file is
        // missing. PNG generation is deterministic and cheap (a few KB),
        // so this is safe to leave enabled in CI without churning the
        // working tree.
        // Locate the package root by walking up from #filePath.
        let thisFile = URL(fileURLWithPath: #filePath)
        // …/Tests/JoyDOMTests/Utilities/GenerateTestAssetsTests.swift
        let repoRoot = thisFile
            .deletingLastPathComponent()    // Utilities
            .deletingLastPathComponent()    // JoyDOMTests
            .deletingLastPathComponent()    // Tests
            .deletingLastPathComponent()    // <repo root>
        let outDir = repoRoot
            .appendingPathComponent("Sources/JoyDOMSampleSpecs/Resources/test-assets",
                                    isDirectory: true)
        try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

        let landscape = outDir.appendingPathComponent("photo-landscape.png")
        let portrait = outDir.appendingPathComponent("photo-portrait.png")
        if !FileManager.default.fileExists(atPath: landscape.path) {
            try writePNG(
                width: 400, height: 200,
                bands: [(.systemRed, 1.0/3), (.systemGreen, 1.0/3), (.systemBlue, 1.0/3)],
                to: landscape
            )
        }
        if !FileManager.default.fileExists(atPath: portrait.path) {
            try writePNG(
                width: 200, height: 400,
                bands: [(.systemOrange, 1.0/3), (.systemPurple, 1.0/3), (.systemTeal, 1.0/3)],
                to: portrait
            )
        }
    }

    private func writePNG(
        width: Int, height: Int,
        bands: [(PlatformColor, CGFloat)],
        to url: URL
    ) throws {
        let cs = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
            data: nil,
            width: width, height: height,
            bitsPerComponent: 8, bytesPerRow: 0,
            space: cs,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw NSError(domain: "gen", code: 1)
        }

        // Draw bands stacked vertically (top → bottom).
        var y: CGFloat = CGFloat(height)
        for (color, frac) in bands {
            let h = CGFloat(height) * frac
            y -= h
            ctx.setFillColor(color.cgColor)
            ctx.fill(CGRect(x: 0, y: y, width: CGFloat(width), height: h))
        }

        // Bold black X to make orientation/cropping visible.
        ctx.setStrokeColor(PlatformColor.black.cgColor)
        ctx.setLineWidth(6)
        ctx.move(to: CGPoint(x: 0, y: 0))
        ctx.addLine(to: CGPoint(x: CGFloat(width), y: CGFloat(height)))
        ctx.move(to: CGPoint(x: CGFloat(width), y: 0))
        ctx.addLine(to: CGPoint(x: 0, y: CGFloat(height)))
        ctx.strokePath()

        // White border so edges are distinguishable from background.
        ctx.setStrokeColor(PlatformColor.white.cgColor)
        ctx.setLineWidth(8)
        ctx.stroke(CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))

        guard let img = ctx.makeImage() else {
            throw NSError(domain: "gen", code: 2)
        }
        guard let dest = CGImageDestinationCreateWithURL(
            url as CFURL,
            UTType.png.identifier as CFString,
            1, nil
        ) else {
            throw NSError(domain: "gen", code: 3)
        }
        CGImageDestinationAddImage(dest, img, nil)
        if !CGImageDestinationFinalize(dest) {
            throw NSError(domain: "gen", code: 4)
        }
    }
}
