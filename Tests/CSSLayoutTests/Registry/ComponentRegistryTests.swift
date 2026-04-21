import XCTest
import SwiftUI
@testable import CSSLayout

/// Unit (i) — `ComponentRegistry` stores factories by type name.
///
/// Tests exercise the contract shape only; they don't assert on the actual
/// View output, because inspecting opaque SwiftUI views is brittle. The
/// resolver tests (Unit k) verify that the right factory fires via marker
/// traces.
final class ComponentRegistryTests: XCTestCase {

    // MARK: - Test fixture

    /// A fresh registry per test — avoid leaking registrations between tests
    /// via the package-wide singleton.
    private var registry: ComponentRegistry!

    override func setUp() {
        super.setUp()
        registry = ComponentRegistry()
    }

    // MARK: - Registration

    func testRegisterAndLookupByType() {
        registry.register("button") { _, _ in AnyView(EmptyView()) }
        XCTAssertNotNil(registry.factory(for: "button"))
    }

    func testLastRegistrationWins() {
        var hit = 0
        registry.register("text") { _, _ in hit = 1; return AnyView(EmptyView()) }
        registry.register("text") { _, _ in hit = 2; return AnyView(EmptyView()) }
        _ = registry.factory(for: "text")?(ComponentProps([:]), ComponentEvents())
        XCTAssertEqual(hit, 2)
    }

    func testUnknownTypeReturnsNil() {
        XCTAssertNil(registry.factory(for: "never-registered"))
    }

    func testRegisterIsChainable() {
        let returned = registry
            .register("a") { _, _ in AnyView(EmptyView()) }
            .register("b") { _, _ in AnyView(EmptyView()) }
        XCTAssertTrue(returned === registry)
        XCTAssertNotNil(registry.factory(for: "a"))
        XCTAssertNotNil(registry.factory(for: "b"))
    }

    // MARK: - Tier 2: ComponentBody factory overload

    /// The new `register(_:body:)` overload stores the factory; a
    /// subsequent `bodyFactory(for:)` lookup returns the same closure,
    /// and invoking it runs the supplied builder.
    func testRegisterBodyFactoryAndInvoke() {
        var calls = 0
        registry.register("card") { _, _ -> ComponentBody in
            calls += 1
            return .custom { EmptyView() }
        }
        let retrieved = registry.bodyFactory(for: "card")
        XCTAssertNotNil(retrieved, "body factory must round-trip through registry")
        _ = retrieved?(ComponentProps([:]), ComponentEvents())
        XCTAssertEqual(calls, 1)
    }

    /// Both legacy and Tier-2 overloads co-exist under different type
    /// keys. Each lookup method surfaces its own registration.
    func testBothOverloadsCoexistForDifferentTypes() {
        registry.register("legacy")   { _, _ in AnyView(EmptyView()) }
        registry.register("modern",   body: { _, _ in .custom { EmptyView() } })
        // Unified lookup: both APIs succeed regardless of which overload
        // was used to register (green-phase promise).
        XCTAssertNotNil(registry.bodyFactory(for: "legacy"),
                        "legacy registrations must be reachable as ComponentBody too")
        XCTAssertNotNil(registry.bodyFactory(for: "modern"))
        XCTAssertNotNil(registry.factory(for: "legacy"))
    }

    /// Re-registering a key via the body overload must replace the
    /// legacy registration: a subsequent `bodyFactory(for:)` returns a
    /// closure whose body-version counter increments, not the legacy
    /// one's.
    func testBodyRegistrationOverridesAnyViewRegistrationForSameKey() {
        var legacyCalls = 0
        var bodyCalls = 0
        registry.register("x") { _, _ -> AnyView in
            legacyCalls += 1
            return AnyView(EmptyView())
        }
        registry.register("x", body: { _, _ -> ComponentBody in
            bodyCalls += 1
            return .custom { EmptyView() }
        })
        _ = registry.bodyFactory(for: "x")?(
            ComponentProps([:]), ComponentEvents()
        )
        XCTAssertEqual(bodyCalls, 1)
        XCTAssertEqual(legacyCalls, 0, "legacy factory must be shadowed")
    }

    // MARK: - ComponentProps

    func testPropsStringSubscript() {
        let props = ComponentProps(["label": "Submit", "placeholder": "Name"])
        XCTAssertEqual(props.string("label"), "Submit")
        XCTAssertEqual(props.string("placeholder"), "Name")
    }

    func testPropsStringReturnsNilForMissingKey() {
        let props = ComponentProps([:])
        XCTAssertNil(props.string("missing"))
    }

    func testPropsID() {
        let props = ComponentProps(["label": "Go"], id: "submit")
        XCTAssertEqual(props.id, "submit")
    }

    // MARK: - ComponentEvents

    func testEventsEmitIsANoOpWhenNoSink() {
        // No sink wired — calling emit should not crash.
        let events = ComponentEvents()
        events.emit("tap", payload: ["key": "value"])
    }

    func testEventsSinkReceivesCalls() {
        var received: [(String, [String: String], Bool)] = []
        let events = ComponentEvents { name, payload, propagates in
            received.append((name, payload, propagates))
        }
        events.emit("submit", payload: ["form": "signup"])
        events.emit("tap",    payload: [:],  propagates: false)
        XCTAssertEqual(received.count, 2)
        XCTAssertEqual(received[0].0, "submit")
        XCTAssertEqual(received[0].1["form"], "signup")
        XCTAssertTrue(received[0].2, "default emit bubbles")
        XCTAssertEqual(received[1].0, "tap")
        XCTAssertFalse(received[1].2, "explicit propagates: false respected")
    }
}
