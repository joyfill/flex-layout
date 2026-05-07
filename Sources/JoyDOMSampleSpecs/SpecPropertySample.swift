// SpecPropertySample — Swift façade over the per-property sample JSON
// payloads that ship in `Bundle.module` resources.
//
// Each entry in the manifest (`Resources/manifest.json`) names one
// runnable JoyDOM `Spec` document that exercises a single property
// (or a tightly related family — `top/left/bottom/right`,
// `min/maxWidth/Height`). The JSON content is lifted verbatim from
// `docs/Spec-Property-Reference.md` so the demo and the doc stay in
// lockstep.
//
// The API is split in three layers:
//   - `SpecPropertySample` — value type for one sample (id, category,
//     property, summary, raw JSON).
//   - `SpecPropertySamples.all` — every sample in declaration order.
//   - `SpecPropertySamples.byCategory` — convenience grouping for the
//     browser UI.
//
// Loading is one-shot at first access and memoised in a static `let`,
// so callers can index `all` repeatedly without re-reading the bundle.

import Foundation

/// One sample illustrating a spec property's behavior with a runnable
/// `Spec` payload covering every legal value.
public struct SpecPropertySample: Identifiable, Equatable {
    /// Stable ID, e.g. `"flexbox-flex-direction"` — matches the
    /// resource filename without the `.json` extension.
    public let id: String

    /// Human-readable category, e.g. `"Flexbox"`.
    public let category: String

    /// Spec property name as it appears in `spec.ts`, e.g.
    /// `"flexDirection"`. For combined-axis samples (insets, min/max),
    /// this is the family name (`"top/left/bottom/right"`).
    public let property: String

    /// One-line description of what the sample exercises.
    public let summary: String

    /// Raw JSON payload, decode-runnable as a JoyDOM `Spec`.
    public let json: String
}

/// Public registry of every property sample shipped in this target.
public enum SpecPropertySamples {

    // MARK: - Public API

    /// Every sample in manifest declaration order. Empty only if the
    /// manifest can't be loaded (which would be a build-time error
    /// because the manifest ships in the bundle).
    public static let all: [SpecPropertySample] = loadAll()

    /// Samples grouped by category, in the order categories first
    /// appear in the manifest. The grouping preserves manifest order
    /// inside each bucket so spec sections render predictably.
    public static let byCategory: [(category: String, samples: [SpecPropertySample])] = {
        var seen: [String: Int] = [:]
        var buckets: [(String, [SpecPropertySample])] = []
        for sample in all {
            if let idx = seen[sample.category] {
                buckets[idx].1.append(sample)
            } else {
                seen[sample.category] = buckets.count
                buckets.append((sample.category, [sample]))
            }
        }
        return buckets.map { (category: $0.0, samples: $0.1) }
    }()

    /// Lookup by id. `nil` if the id doesn't match a bundled sample.
    public static func sample(withID id: String) -> SpecPropertySample? {
        all.first(where: { $0.id == id })
    }

    // MARK: - Loader

    private struct ManifestEntry: Decodable {
        let id: String
        let file: String
        let category: String
        let property: String
        let summary: String
    }

    private struct Manifest: Decodable {
        let version: Int
        let samples: [ManifestEntry]
    }

    /// Read `Resources/manifest.json` and load each referenced JSON
    /// payload via `Bundle.module`. Failures collapse to an empty
    /// array — the integrity test (`testManifestMatchesBundledFiles`)
    /// asserts non-empty so misconfiguration surfaces in CI.
    private static func loadAll() -> [SpecPropertySample] {
        // Resources are shipped via `.copy("Resources")` in Package.swift,
        // so the directory tree is preserved as `Resources/<category>/<file>`
        // inside Bundle.module. Looking up with `subdirectory:` matches that.
        guard let manifestURL = Bundle.module.url(
            forResource: "manifest",
            withExtension: "json",
            subdirectory: "Resources"
        ) else {
            return []
        }
        guard let manifestData = try? Data(contentsOf: manifestURL),
              let manifest = try? JSONDecoder().decode(Manifest.self, from: manifestData) else {
            return []
        }

        var samples: [SpecPropertySample] = []
        samples.reserveCapacity(manifest.samples.count)

        for entry in manifest.samples {
            guard let json = loadSampleJSON(file: entry.file) else { continue }
            samples.append(SpecPropertySample(
                id: entry.id,
                category: entry.category,
                property: entry.property,
                summary: entry.summary,
                json: json
            ))
        }
        return samples
    }

    /// Read a sample file under the bundle. The manifest stores paths
    /// like `"flexbox/flex-direction.json"`, so we split into the
    /// subdirectory + base name pair `Bundle.module.url(...)` expects.
    private static func loadSampleJSON(file: String) -> String? {
        let parts = file.split(separator: "/", maxSplits: 1).map(String.init)
        let subdirectory: String
        let basenameWithExt: String
        if parts.count == 2 {
            subdirectory = "Resources/\(parts[0])"
            basenameWithExt = parts[1]
        } else {
            subdirectory = "Resources"
            basenameWithExt = file
        }

        let basename: String
        if basenameWithExt.hasSuffix(".json") {
            basename = String(basenameWithExt.dropLast(".json".count))
        } else {
            basename = basenameWithExt
        }

        guard let url = Bundle.module.url(
            forResource: basename,
            withExtension: "json",
            subdirectory: subdirectory
        ) else {
            return nil
        }

        return try? String(contentsOf: url, encoding: .utf8)
    }
}
