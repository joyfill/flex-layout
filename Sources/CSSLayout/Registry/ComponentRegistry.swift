// ComponentRegistry — maps component type names (`"button"`, `"text-input"`)
// to factory closures.
//
// A single `shared` instance serves as the package-wide default registry,
// but tests and previews instantiate their own registries to keep state
// isolated. The registry is *not* thread-safe in Phase 1 — callers should
// register everything during app startup. Phase 5 will add a lock.

import Foundation
import SwiftUI

/// Builds a SwiftUI view for one schema-supplied component.
///
/// The factory receives the props extracted from the schema and an event
/// sink that routes user interactions back to the `CSSLayout` host. Return
/// an `AnyView` to keep the registry value type-erased — each factory
/// controls its own body.
///
/// Tier 2 note: this typealias is the *legacy* factory shape. New
/// registrations should prefer ``ComponentBodyFactory`` via the
/// ``register(_:body:)`` overload, which returns the multi-host
/// ``ComponentBody`` wrapper. Unit 7 of the Tier-2 plan retires this
/// typealias in favour of `ComponentBody`; until then both shapes
/// coexist so call sites can migrate incrementally.
public typealias ComponentFactory = (_ props: ComponentProps, _ events: ComponentEvents) -> AnyView

/// Tier 2 factory shape — returns a ``ComponentBody`` wrapper that can
/// carry SwiftUI, UIKit, or WebKit-backed views uniformly.
public typealias ComponentBodyFactory = (_ props: ComponentProps, _ events: ComponentEvents) -> ComponentBody

/// Registry of component factories keyed by type name.
public final class ComponentRegistry {

    /// The package-wide default registry. Apps register their factories here
    /// once at startup; `CSSLayout` reads from it unless given a custom
    /// registry.
    public static let shared = ComponentRegistry()

    private var factories: [String: ComponentFactory] = [:]

    public init() {}

    /// Register a factory for `type`. If `type` was registered previously,
    /// the new factory replaces it (last-wins, matching how a developer
    /// would expect `register` to behave during hot reload).
    ///
    /// Returns `self` so registrations can be chained fluently:
    /// ```swift
    /// ComponentRegistry.shared
    ///     .register("button") { props, events in … }
    ///     .register("text")   { props, _      in … }
    /// ```
    @discardableResult
    public func register(
        _ type: String,
        factory: @escaping ComponentFactory
    ) -> ComponentRegistry {
        factories[type] = factory
        return self
    }

    /// Tier 2 register overload for the new ``ComponentBodyFactory`` shape.
    ///
    /// RED stub: compiles, accepts the closure, but silently drops it
    /// without populating any storage. Unit 3's green commit wires it
    /// through shared storage alongside the legacy overload.
    @discardableResult
    public func register(
        _ type: String,
        body: @escaping ComponentBodyFactory
    ) -> ComponentRegistry {
        // RED: intentionally a no-op to make bodyFactory(for:) return nil
        // for the tests that exercise the new path.
        _ = type
        _ = body
        return self
    }

    /// Look up a factory by component type. Returns `nil` for unknown types.
    public func factory(for type: String) -> ComponentFactory? {
        factories[type]
    }

    /// Tier 2: look up a ``ComponentBodyFactory`` by type.
    ///
    /// RED stub: always nil. Green merges body + legacy storage so either
    /// registration shape round-trips through this method.
    public func bodyFactory(for type: String) -> ComponentBodyFactory? {
        nil
    }
}
