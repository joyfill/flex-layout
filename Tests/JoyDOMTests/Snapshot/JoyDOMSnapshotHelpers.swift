// JoyDOMSnapshotHelpers — thin wrappers over swift-snapshot-testing
// that take a JoyDOM `Spec` (or its JSON string) and render it at a
// fixed viewport before snapshotting.
//
// Snapshot tests close the gap that unit tests against `some View`
// returns can't fill: `_DOMImage.applyFit` returning the right
// modifier doesn't prove the AsyncImage layout cycle works, and a
// resolver test that VisualStyle.objectFit == .fill doesn't prove
// the image actually fills its wrapper at render time. The bugs
// fixed in PRs #20, #21, #26 (objectFit fill rendering, breakpoint
// visibility slots invisible, _DOMImage alignment) were all visual
// regressions invisible to type-only tests.
//
// Baseline images live in `__Snapshots__/<TestClassName>/` next to
// each test file. The first run records the baseline; subsequent
// runs diff against it. To re-record after an intentional change,
// pass `record: true` to `assertJoyDOMSnapshot(...)` or set the
// `SNAPSHOT_TESTING_RECORD` environment variable.

import XCTest
import SnapshotTesting
import SwiftUI
@testable import JoyDOM

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

extension XCTestCase {
    /// Render a JoyDOM Spec at a fixed viewport width and snapshot it.
    ///
    /// - Parameters:
    ///   - spec: The decoded Spec.
    ///   - viewportWidth: Drives breakpoint resolution. Defaults to 800
    ///     (a common desktop-ish width that triggers most `>=768`
    ///     breakpoints). Pass a smaller value to verify mobile layouts.
    ///   - height: Rendered frame height. The view's content is allowed
    ///     to overflow internally; this is only the snapshot bound.
    ///   - precision: Pixel-level match precision. Default 0.99 allows
    ///     ~1% pixel diff before the test fails — picks up structural
    ///     regressions while tolerating font / GPU rendering noise.
    ///   - perceptualPrecision: Perceptual (human-eye) similarity
    ///     threshold. 0.97 ≈ visually indistinguishable.
    ///   - record: Set true to re-record the baseline (use sparingly,
    ///     commit the diff intentionally).
    func assertJoyDOMSnapshot(
        spec: Spec,
        viewportWidth: CGFloat = 800,
        height: CGFloat = 600,
        precision: Float = 0.99,
        perceptualPrecision: Float = 0.97,
        record: Bool = false,
        named name: String? = nil,
        file: StaticString = #filePath,
        testName: String = #function,
        line: UInt = #line
    ) {
        let view = JoyDOMView(spec: spec)
            .viewport(.init(width: viewportWidth))
            .frame(width: viewportWidth, height: height)

        // Wrap in a hosting controller. swift-snapshot-testing's SwiftUI
        // strategies differ between UIKit and AppKit; hosting the View
        // in a platform-specific controller and snapshotting THAT gives
        // us one signature that works on both. The hosting controller's
        // view frame is pinned to the requested viewport+height so the
        // image is deterministic regardless of intrinsic sizing.
        let size = CGSize(width: viewportWidth, height: height)
        #if canImport(UIKit)
        let host = UIHostingController(rootView: view)
        host.view.frame = CGRect(origin: .zero, size: size)
        assertSnapshot(
            of: host,
            as: .image(
                precision: precision,
                perceptualPrecision: perceptualPrecision
            ),
            named: name,
            record: record,
            file: file,
            testName: testName,
            line: line
        )
        #elseif canImport(AppKit)
        let host = NSHostingController(rootView: view)
        host.view.frame = CGRect(origin: .zero, size: size)
        assertSnapshot(
            of: host,
            as: .image(
                precision: precision,
                perceptualPrecision: perceptualPrecision,
                size: size
            ),
            named: name,
            record: record,
            file: file,
            testName: testName,
            line: line
        )
        #endif
    }

    /// Convenience overload that decodes the JSON for the caller.
    /// Fails the test (rather than throwing) if the JSON is malformed —
    /// snapshot tests want a hard fail on bad input.
    func assertJoyDOMSnapshot(
        json: String,
        viewportWidth: CGFloat = 800,
        height: CGFloat = 600,
        precision: Float = 0.99,
        perceptualPrecision: Float = 0.97,
        record: Bool = false,
        named name: String? = nil,
        file: StaticString = #filePath,
        testName: String = #function,
        line: UInt = #line
    ) {
        do {
            let spec = try JSONDecoder().decode(Spec.self, from: Data(json.utf8))
            assertJoyDOMSnapshot(
                spec: spec,
                viewportWidth: viewportWidth,
                height: height,
                precision: precision,
                perceptualPrecision: perceptualPrecision,
                record: record,
                named: name,
                file: file,
                testName: testName,
                line: line
            )
        } catch {
            XCTFail(
                "JoyDOM snapshot helper: JSON failed to decode as Spec: \(error)",
                file: file,
                line: line
            )
        }
    }
}
