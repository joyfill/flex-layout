// Selector — the Phase 1 simple-selector AST.
//
// Phase 1 supports ID, class, and element selectors only. Phase 2 will
// introduce a `ComplexSelector` wrapper that composes these with combinators
// (`>`, descendant, `,` grouping) — the `SimpleSelector` value remains as-is
// and becomes the leaf of a compound selector chain.

import Foundation

/// A single simple selector.
public enum SimpleSelector: Equatable {
    /// `#foo`
    case id(String)
    /// `.primary`
    case `class`(String)
    /// `button`, `text-input`, etc. — matches a component by its registered type.
    case element(String)
}

/// A compound selector — a chain of simple selectors that all apply to the
/// same subject (no intervening whitespace or combinator). The CSS grammar
/// calls this a "compound selector" and it's the building block of
/// `ComplexSelector` (Phase 2 combinators).
///
/// Phase 2 currently uses a compound as the full rule selector, so a bare
/// `#a` is modelled as a compound of length one.
public struct CompoundSelector: Equatable {
    /// Non-empty sequence of simple selectors, preserved in source order.
    public let parts: [SimpleSelector]

    /// Preferred init for explicit part lists. Traps on empty input.
    public init(_ parts: [SimpleSelector]) {
        precondition(!parts.isEmpty, "CompoundSelector requires at least one part")
        self.parts = parts
    }

    /// Convenience init for the common "single simple selector" case.
    public init(_ single: SimpleSelector) {
        self.parts = [single]
    }
}

// Note: `CompoundSelector` deliberately has no dot-syntax factories. The
// dot-syntax conveniences live on `ComplexSelector` (below) so expressions
// like `rule.selector == .id("a")` resolve unambiguously now that the rule
// selector type is `ComplexSelector`.

/// A combinator linking two compound selectors in a complex selector chain.
public enum Combinator: Equatable {
    /// Whitespace between compounds — any ancestor matches.
    case descendant
    /// `>` — the immediate parent must match.
    case child
}

/// A complex selector — a chain of compound selectors joined by combinators.
///
/// `parts[0]` is the outermost (left-most) compound and `parts.last` is the
/// **subject** the rule applies to. `combinators[i]` joins `parts[i]` with
/// `parts[i + 1]`, so there is always exactly one fewer combinator than
/// compound.
///
/// A rule like `#form > .row .input` decomposes as:
/// `parts = [#form, .row, .input]`, `combinators = [.child, .descendant]`.
public struct ComplexSelector: Equatable {
    /// Non-empty compound chain — outer-most first, subject last.
    public let parts: [CompoundSelector]
    /// Links between adjacent parts. `combinators.count == parts.count - 1`.
    public let combinators: [Combinator]

    public init(parts: [CompoundSelector], combinators: [Combinator]) {
        precondition(!parts.isEmpty, "ComplexSelector needs at least one compound")
        precondition(
            combinators.count == parts.count - 1,
            "combinators count must be parts.count - 1"
        )
        self.parts = parts
        self.combinators = combinators
    }

    /// Convenience init wrapping a single compound (no combinators).
    public init(_ single: CompoundSelector) {
        self.init(parts: [single], combinators: [])
    }

    /// The subject compound — the one this rule applies to directly.
    public var subject: CompoundSelector { parts[parts.count - 1] }
}

// MARK: - Dot-syntax factories
//
// Mirror `SimpleSelector`'s cases on `ComplexSelector` so expressions like
// `XCTAssertEqual(rule.selector, .id("a"))` continue to typecheck now that
// `rule.selector` is a `ComplexSelector`.

extension ComplexSelector {
    public static func id(_ name: String) -> ComplexSelector {
        ComplexSelector(CompoundSelector(.id(name)))
    }
    public static func `class`(_ name: String) -> ComplexSelector {
        ComplexSelector(CompoundSelector(.class(name)))
    }
    public static func element(_ name: String) -> ComplexSelector {
        ComplexSelector(CompoundSelector(.element(name)))
    }
}
