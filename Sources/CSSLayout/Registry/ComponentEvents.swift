// ComponentEvents — the outbound-event sink handed to each component factory.
//
// Phase 2: events now carry a `propagates` bit. The sink signature gained the
// flag so the `CSSLayout` dispatcher can skip ancestor handlers (including
// the root) when a factory emits a non-bubbling event.

import Foundation

/// The outbound event channel given to a component factory.
///
/// Factories call `emit` to notify the surrounding `CSSLayout` of user
/// interactions; the sink decides what to do with the event (typically fan
/// out to the registered `onEvent` handlers, but for tests it's often a
/// simple closure that records calls).
public struct ComponentEvents {
    /// The underlying dispatcher. `nil` means "no sink wired" — `emit` is a
    /// no-op. This keeps factory code safe to invoke in isolation (e.g.
    /// registry tests, previews).
    public typealias Sink = (
        _ name: String,
        _ payload: [String: String],
        _ propagates: Bool
    ) -> Void
    private let sink: Sink?

    public init(_ sink: Sink? = nil) {
        self.sink = sink
    }

    /// Emit a named event with an optional payload. `propagates` controls
    /// whether the event bubbles up the component tree to ancestor handlers
    /// (including the root `onEvent` handler). Defaults to `true`, matching
    /// DOM convention.
    public func emit(
        _ name: String,
        payload: [String: String] = [:],
        propagates: Bool = true
    ) {
        sink?(name, payload, propagates)
    }
}
