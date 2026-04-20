// FormState — stub introduced in the red commit so the test suite compiles.
//
// Every method here is intentionally wrong: it satisfies the type checker
// but fails the behavioral assertions in `FormStateTests`. The matching
// green commit replaces the bodies with the real implementation.
//
// This keeps CI building on the red commit (so `git bisect` stays useful)
// while still proving test-first ordering from the commit log.

import Foundation
import Combine

/// The Phase-3 value store for bindings. See `FormStateTests` for the
/// contract — this stub is not the final implementation.
public final class FormState: ObservableObject {

    @Published public private(set) var values: [String: String] = [:]

    public init(values: [String: String] = [:]) {
        // Intentionally ignores seed values in the red stub.
        _ = values
    }

    public func get(_ path: String) -> String? {
        _ = path
        return nil
    }

    public func set(_ path: String, _ value: String) {
        _ = (path, value)
    }

    public func snapshot() -> [String: String] {
        [:]
    }

    public func prune(keeping paths: Set<String>) {
        _ = paths
    }
}
