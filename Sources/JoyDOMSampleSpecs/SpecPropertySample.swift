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

    /// Relative path inside `Resources/`, e.g.
    /// `"flexbox/flex-direction/row.json"`. Lets the snapshot helper
    /// pair each JSON with a baseline of the same leaf name without
    /// hard-coding the directory layout in test code.
    public let file: String

    /// Raw JSON payload, decode-runnable as a JoyDOM `Spec`.
    public let json: String

    /// Non-nil when this sample is a variant of an "overview" sample
    /// with the same (category, property). Set to the id-suffix that
    /// differentiates the variant from its overview, e.g. `"row"` for
    /// `flexbox-flex-direction-row` whose overview is
    /// `flexbox-flex-direction`. Drives the sidebar's indented-row
    /// rendering so multiple test cases under the same property are
    /// visually grouped instead of looking like duplicates.
    public let variantLabel: String?

    /// Optional viewport + height hints for snapshot testing. The
    /// generic per-category bundle-snapshot test reads these to pick a
    /// thoughtful canvas size per sample (wider for rows, taller for
    /// columns, default 800×600 when absent). Encoded in the manifest
    /// under the optional `"snapshot": { "viewportWidth": …, "height": … }`
    /// key per entry.
    public let snapshotConfig: SnapshotConfig?

    /// Per-sample snapshot canvas hint.
    public struct SnapshotConfig: Equatable, Codable {
        public let viewportWidth: Double
        public let height: Double

        /// Default 800×600 when the sample doesn't ship its own hint.
        public static let `default` = SnapshotConfig(viewportWidth: 800, height: 600)

        public init(viewportWidth: Double, height: Double) {
            self.viewportWidth = viewportWidth
            self.height = height
        }
    }
}

/// Public access to the resource bundle for this target. Snapshot tests
/// that load bundled image assets (`bundle://photo-landscape` etc.)
/// register this bundle with JoyDOM's image loader so `_DOMImage` can
/// resolve assets synchronously without going through AsyncImage.
public enum JoyDOMSampleSpecsBundle {
    /// The SwiftPM-generated resource bundle.
    public static let bundle: Bundle = .module
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
        groupByCategory(all)
    }()

    /// All manifest-loaded samples PLUS any JSON file in a property
    /// folder that the manifest doesn't list yet. The demo browser
    /// uses this so newly authored samples appear automatically — drop
    /// a JSON in `Resources/<category>/<property>/` and it shows up
    /// next launch without manifest editing.
    ///
    /// Auto-discovered entries inherit `category` + `property` from the
    /// folder's manifested overview (so they render in the right group
    /// in the sidebar) and get a synthesised id of
    /// `<overview-id>-<basename>`. Their summary is a placeholder
    /// (`"(auto-discovered) <basename>"`) — author a manifest entry to
    /// override.
    ///
    /// **Tests continue to use `.all`** (manifest-only) so test IDs
    /// stay stable and `assertSnapshotsForSamples` doesn't pick up
    /// half-finished JSONs.
    public static let allWithDiscovered: [SpecPropertySample] = {
        let manifestSamples = all
        let discovered = discoverUnmanifestedSamples(against: manifestSamples)
        return manifestSamples + discovered
    }()

    /// `byCategory` over `allWithDiscovered`. Used by the demo browser.
    public static let byCategoryWithDiscovered: [(category: String, samples: [SpecPropertySample])] = {
        groupByCategory(allWithDiscovered)
    }()

    /// Two-level grouping: category → property → samples. The sidebar
    /// renders one category header per outer entry, one property header
    /// per inner entry, and each property's samples as `↳ <basename>`
    /// rows underneath. Every sample appears as a variant — the
    /// property name surfaces only as a non-clickable header, never
    /// folded into a sample row (avoids the
    /// "where did row-reverse go?" UX trap when a property has no
    /// dedicated overview.json).
    public typealias PropertyGroup = (property: String, samples: [SpecPropertySample])
    public typealias CategoryGroup = (category: String, properties: [PropertyGroup])
    public static let byCategoryAndPropertyWithDiscovered: [CategoryGroup] = {
        groupByCategoryAndProperty(allWithDiscovered)
    }()

    /// Lookup by id. `nil` if the id doesn't match a bundled sample.
    public static func sample(withID id: String) -> SpecPropertySample? {
        all.first(where: { $0.id == id })
            ?? allWithDiscovered.first(where: { $0.id == id })
    }

    /// Group samples by category (preserving first-seen category order)
    /// **and** cluster each category's contents by property so a
    /// property's overview + variants render contiguously in the
    /// sidebar regardless of manifest ordering.
    ///
    /// Within each property: overview first (`variantLabel == nil`),
    /// then variants sorted alphabetically by their label. Without this
    /// reshuffle, a property whose variants are interleaved in the
    /// manifest with a sibling property (e.g. `flexDirection` entries
    /// scattered before and after the `flexDirection-iOSExt` block)
    /// visually leaks across property boundaries in the sidebar.
    private static func groupByCategory(
        _ samples: [SpecPropertySample]
    ) -> [(category: String, samples: [SpecPropertySample])] {
        // Step 1: bucket by category, preserving first-seen category order.
        var categoryOrder: [String] = []
        var samplesByCategory: [String: [SpecPropertySample]] = [:]
        for sample in samples {
            if samplesByCategory[sample.category] == nil {
                categoryOrder.append(sample.category)
            }
            samplesByCategory[sample.category, default: []].append(sample)
        }

        // Step 2: within each category, bucket by property (first-seen
        // property order). Within each property: overview first, then
        // variants sorted alphabetically.
        return categoryOrder.map { category in
            let catSamples = samplesByCategory[category] ?? []
            var propertyOrder: [String] = []
            var samplesByProperty: [String: [SpecPropertySample]] = [:]
            for s in catSamples {
                if samplesByProperty[s.property] == nil {
                    propertyOrder.append(s.property)
                }
                samplesByProperty[s.property, default: []].append(s)
            }
            let reordered: [SpecPropertySample] = propertyOrder.flatMap { prop -> [SpecPropertySample] in
                // Every sample now carries a variantLabel (file
                // basename). Within a property, sort alphabetically
                // with `overview` first when present so the canonical
                // demo appears at the top.
                let group = samplesByProperty[prop] ?? []
                return group.sorted { lhs, rhs in
                    let l = lhs.variantLabel ?? lhs.id
                    let r = rhs.variantLabel ?? rhs.id
                    if l == "overview" && r != "overview" { return true }
                    if r == "overview" && l != "overview" { return false }
                    return l < r
                }
            }
            return (category: category, samples: reordered)
        }
    }

    /// Same two-level bucketing as `groupByCategory` but exposing the
    /// inner property structure to the caller. Used by the sidebar to
    /// render headers + variant rows without re-deriving the property
    /// boundaries from a flat list.
    private static func groupByCategoryAndProperty(
        _ samples: [SpecPropertySample]
    ) -> [CategoryGroup] {
        var categoryOrder: [String] = []
        var samplesByCategory: [String: [SpecPropertySample]] = [:]
        for sample in samples {
            if samplesByCategory[sample.category] == nil {
                categoryOrder.append(sample.category)
            }
            samplesByCategory[sample.category, default: []].append(sample)
        }

        return categoryOrder.map { category in
            let catSamples = samplesByCategory[category] ?? []
            var propertyOrder: [String] = []
            var samplesByProperty: [String: [SpecPropertySample]] = [:]
            for s in catSamples {
                if samplesByProperty[s.property] == nil {
                    propertyOrder.append(s.property)
                }
                samplesByProperty[s.property, default: []].append(s)
            }
            let propertyGroups: [PropertyGroup] = propertyOrder.map { prop in
                let group = samplesByProperty[prop] ?? []
                let sorted = group.sorted { lhs, rhs in
                    let l = lhs.variantLabel ?? lhs.id
                    let r = rhs.variantLabel ?? rhs.id
                    if l == "overview" && r != "overview" { return true }
                    if r == "overview" && l != "overview" { return false }
                    return l < r
                }
                return (property: prop, samples: sorted)
            }
            return (category: category, properties: propertyGroups)
        }
    }

    /// Walk every property folder that the manifest already references
    /// and surface any JSON file in it that isn't manifested.
    ///
    /// The manifest implicitly defines the universe of folders the demo
    /// cares about (`flexbox/flex-direction/`, `flexbox/flex-grow/`, …).
    /// For each such folder we scan `Bundle.module` and add any
    /// unmanifested `.json` files as variants.
    private static func discoverUnmanifestedSamples(
        against manifested: [SpecPropertySample]
    ) -> [SpecPropertySample] {
        let manifestedFiles = Set(manifested.map { $0.file })

        // Folder → metadata derived from the first manifested sample
        // for that folder. Every sample carries category/property; the
        // first one we see for a given folder defines the inherited
        // metadata for any auto-discovered siblings.
        struct FolderMeta {
            let category: String
            let property: String
            let firstSeenID: String
        }
        var folderMeta: [String: FolderMeta] = [:]
        for sample in manifested {
            let parts = sample.file.split(separator: "/")
            guard parts.count >= 2 else { continue }
            let folder = parts.dropLast().joined(separator: "/")
            if folderMeta[folder] == nil {
                folderMeta[folder] = FolderMeta(
                    category: sample.category,
                    property: sample.property,
                    firstSeenID: sample.id
                )
            }
        }

        var discovered: [SpecPropertySample] = []
        for (folder, meta) in folderMeta {
            guard let urls = Bundle.module.urls(
                forResourcesWithExtension: "json",
                subdirectory: "Resources/\(folder)"
            ) else { continue }
            for url in urls {
                let basename = url.deletingPathExtension().lastPathComponent
                let relativePath = "\(folder)/\(basename).json"
                guard !manifestedFiles.contains(relativePath) else { continue }
                guard let data = try? Data(contentsOf: url),
                      let json = String(data: data, encoding: .utf8) else { continue }
                discovered.append(SpecPropertySample(
                    id: "\(meta.firstSeenID)-\(basename)",
                    category: meta.category,
                    property: meta.property,
                    summary: "(auto-discovered) \(basename)",
                    file: relativePath,
                    json: json,
                    variantLabel: basename,
                    snapshotConfig: nil
                ))
            }
        }
        // Deterministic order so the demo's sidebar doesn't reshuffle
        // between launches when new files appear.
        return discovered.sorted { $0.id < $1.id }
    }

    // MARK: - Loader

    private struct ManifestEntry: Decodable {
        let id: String
        let file: String
        let category: String
        let property: String
        let summary: String
        /// Optional — generic snapshot-test reads this to pick a per-sample
        /// canvas size. Absent → use `SpecPropertySample.SnapshotConfig.default`.
        let snapshot: SpecPropertySample.SnapshotConfig?
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

        // Every sample's `variantLabel` is its file basename. Earlier
        // versions tried to elect one "overview" per (category,
        // property) pair (variantLabel = nil) and treat the rest as
        // variants — that broke when a property had no canonical
        // overview file (e.g. flexDirection-iOSExt's row-reverse +
        // column-reverse pair). The "synthetic overview" lost its
        // value name in the sidebar (you'd see "flexDirection-iOSExt"
        // instead of "row-reverse") and the selection / detail flow
        // got tangled when the synthetic overview was selected.
        //
        // Treating every sample as a labelled variant — with the
        // property name surfaced separately as a non-clickable header
        // in `byCategoryAndPropertyWithDiscovered` — is structurally
        // simpler and reads consistently in the sidebar regardless of
        // whether an overview.json exists.

        for entry in manifest.samples {
            guard let json = loadSampleJSON(file: entry.file) else { continue }
            let basename = ((entry.file as NSString).lastPathComponent as NSString)
                .deletingPathExtension
            samples.append(SpecPropertySample(
                id: entry.id,
                category: entry.category,
                property: entry.property,
                summary: entry.summary,
                file: entry.file,
                json: json,
                variantLabel: basename,
                snapshotConfig: entry.snapshot
            ))
        }
        return samples
    }

    /// Read a sample file under the bundle. The manifest stores paths
    /// like `"flexbox/flex-direction/row.json"` (property-scoped
    /// subdirectories), so split on the LAST `/` to keep the full
    /// nested directory path. `Bundle.module.url(subdirectory:)` accepts
    /// multi-level paths verbatim.
    private static func loadSampleJSON(file: String) -> String? {
        let subdirectory: String
        let basenameWithExt: String
        if let lastSlash = file.lastIndex(of: "/") {
            subdirectory = "Resources/\(file[..<lastSlash])"
            basenameWithExt = String(file[file.index(after: lastSlash)...])
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
