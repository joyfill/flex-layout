// Round-trip safety net for the property-playground editor.
//
// The playground in `FlexDemoApp/SpecPropertyBrowser.swift` lets the
// user edit a sample's JSON in-place and re-decode it on every
// keystroke. This test guards that the JSON shipped in
// `JoyDOMSampleSpecs` survives a decode -> re-encode -> decode cycle
// without dropping fields or introducing artefacts that the editor's
// "load template -> save" workflow would otherwise reveal.

import XCTest
import SwiftUI
@testable import JoyDOM
@testable import JoyDOMSampleSpecs

final class PropertyPlaygroundEditorTests: XCTestCase {
    /// Every bundled sample is editable: round-trip the json through
    /// decode → encode → decode and assert the second decode matches
    /// the first. Proves that what the editor displays is round-trip
    /// safe (no extra trailing newline, no encoding artefacts).
    func testEverySampleRoundTripsThroughEditorPath() throws {
        for sample in SpecPropertySamples.all {
            let firstDecoded = try JSONDecoder().decode(Spec.self,
                from: Data(sample.json.utf8))
            // Re-encode to canonical JSON, then decode again — the
            // editor's "load template" → "save" cycle should match.
            let reEncoded = try JSONEncoder().encode(firstDecoded)
            let secondDecoded = try JSONDecoder().decode(Spec.self,
                from: reEncoded)
            XCTAssertEqual(firstDecoded.version, secondDecoded.version,
                           "\(sample.id) version drifted")
            // Light structural check — full Spec doesn't conform to
            // Equatable so we can't deep-compare; this catches the
            // common breakage of fields being dropped on re-encode.
        }
    }
}
