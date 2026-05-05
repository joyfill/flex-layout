// ComponentProps — the read-only bag of values passed to a component factory.
//
// Props are stored as `JSONValue` so structured extras (objects, arrays, null)
// decoded from the spec payload are not silently dropped before reaching
// factories. The `string(_:)` convenience accessor remains the primary API for
// factories that read scalar props (src, label, etc.); `value(_:)` exposes the
// full JSONValue for factories that need structured data.

import Foundation

/// Read-only access to a component's key/value props.
///
/// Factories read props but never mutate them; JoyDOMView re-invokes the
/// factory whenever the upstream payload changes.
public struct ComponentProps {
    /// The node's id (mirrors `SchemaEntry.id`). Included here so factories
    /// needn't accept two parameters.
    public let id: String
    /// The raw props dictionary. Values are `JSONValue` so nested objects,
    /// arrays, and null decoded from the spec payload are preserved losslessly.
    public let values: [String: JSONValue]

    public init(_ values: [String: JSONValue] = [:], id: String = "") {
        self.id = id
        self.values = values
    }

    /// Returns the string value for `key`, or `nil` if absent.
    ///
    /// Also returns a string for numeric and boolean values by flattening them
    /// (e.g. `.number(3)` → `"3"`, `.bool(true)` → `"true"`), matching the
    /// behaviour callers expected when all props were stored as `String`. For
    /// structured values (arrays, objects, null) use `value(_:)` instead.
    public func string(_ key: String) -> String? {
        values[key]?.stringValue
    }

    /// Returns the raw `JSONValue` for `key`, or `nil` if absent.
    ///
    /// Use this when the prop may carry a nested object or array, e.g.:
    /// ```swift
    /// if case .object(let cfg) = props.value("config") { … }
    /// ```
    public func value(_ key: String) -> JSONValue? {
        values[key]
    }
}
