import Foundation

public enum FluentError: Error, LocalizedError, CustomStringConvertible, CustomDebugStringConvertible {
    case idRequired
    case invalidField(name: String, valueType: Any.Type, error: any Error)
    case missingField(name: String)
    case relationNotLoaded(name: String)
    case missingParent(from: String, to: String, key: String, id: String)
    case noResults

    // `CustomStringConvertible` conformance.
    public var description: String {
        switch self {
        case .idRequired:
            return "ID required"
        case .missingField(let name):
            return "field missing: \(name)"
        case .relationNotLoaded(let name):
            return "relation not loaded: \(name)"
        case .missingParent(let model, let parent, let key, let id):
            return "parent missing: \(model).\(key): \(parent).\(id)"
        case .invalidField(let name, let valueType, let error):
            return "invalid field: '\(name)', type: \(valueType), error: \(String(describing: error))"
        case .noResults:
            return "Query returned no results"
        }
    }

    // `CustomDebugStringConvertible` conformance.
    public var debugDescription: String {
        switch self {
        case .idRequired, .missingField(_), .relationNotLoaded(_), .missingParent(_, _, _, _), .noResults:
            return self.description
        case .invalidField(let name, let valueType, let error):
            return "invalid field: '\(name)', type: \(valueType), error: \(String(reflecting: error))"
        }
    }

    // `LocalizedError` conformance.
    public var errorDescription: String? {
        self.description
    }

    // `LocalizedError` conformance.
    public var failureReason: String? {
        self.description
    }
}

extension FluentError {
    internal static func missingParentError<Child: Model, Parent: Model>(
        _: Child.Type = Child.self, _: Parent.Type = Parent.self, keyPath: KeyPath<Child, Child.Parent<Parent>>, id: Parent.IDValue
    ) -> Self {
        .missingParent(
            from: "\(Child.self)",
            to: "\(Parent.self)",
            key: Child.path(for: keyPath.appending(path: \.$id)).map(\.description).joined(separator: ".->"),
            id: "\(id)"
        )
    }

    internal static func missingParentError<Child: Model, Parent: Model>(
        _: Child.Type = Child.self, _: Parent.Type = Parent.self, keyPath: KeyPath<Child, Child.CompositeParent<Parent>>, id: Parent.IDValue
    ) -> Self where Parent.IDValue: Fields {
        .missingParent(
            from: "\(Child.self)",
            to: "\(Parent.self)",
            key: Child()[keyPath: keyPath].prefix.description,
            id: "\(id)"
        )
    }

    internal static func missingParentError<Child: Model, Parent: Model>(
        _: Child.Type = Child.self, _: Parent.Type = Parent.self, keyPath: KeyPath<Child, Child.OptionalParent<Parent>>, id: Parent.IDValue
    ) -> Self {
        .missingParent(
            from: "\(Child.self)",
            to: "\(Parent.self)",
            key: Child.path(for: keyPath.appending(path: \.$id)).map(\.description).joined(separator: ".->"),
            id: "\(id)"
        )
    }

    internal static func missingParentError<Child: Model, Parent: Model>(
        _: Child.Type = Child.self, _: Parent.Type = Parent.self, keyPath: KeyPath<Child, Child.CompositeOptionalParent<Parent>>, id: Parent.IDValue
    ) -> Self where Parent.IDValue: Fields {
        .missingParent(
            from: "\(Child.self)",
            to: "\(Parent.self)",
            key: Child()[keyPath: keyPath].prefix.description,
            id: "\(id)"
        )
    }
}

/// An error describing a failure during an an operation on an ``SiblingsProperty``.
///
/// > Note: This should just be another case on ``FluentError``, not a separate error type, but at the time
///   of this writing, non-frozen enums are still not available to non-stdlib packages, so to avoid source
///   breakage we chose this as the least annoying of the several annoying workarounds.
public enum SiblingsPropertyError: Error, LocalizedError, CustomStringConvertible, CustomDebugStringConvertible {
    /// An attempt was made to query, attach to, or detach from a siblings property whose owning model's ID
    /// is not currently known (usually because that model has not yet been saved to the database).
    ///
    /// Includes the relation name of the siblings property.
    case owningModelIdRequired(property: String)
    
    /// An attempt was made to attach, detach, or check attachment to a siblings property of a model whose
    /// ID is not currently known (usually because that model has not yet been saved to the database).
    ///
    /// More explicitly, this case means that the model to be attached or detached (an instance of the "To"
    /// model) is unsaved, whereas the above ``owningModelIdRequired`` case means that the model containing
    /// the sublings property itself (an instead of the "From") model is unsaved.
    ///
    /// Includes the relation name of the siblings property.
    case operandModelIdRequired(property: String)
    
    // `CustomStringConvertible` conformance.
    public var description: String {
        switch self {
        case .owningModelIdRequired(property: let property):
            return "siblings relation \(property) is missing owning model's ID (owner likely unsaved)"
        case .operandModelIdRequired(property: let property):
            return "operant model for siblings relation \(property) has no ID (attach/detach/etc. model likely unsaved)"
        }
    }
    
    // `CustomDebugStringConvertible` conformance.
    public var debugDescription: String { self.description }
    
    // `LocalizedError` conformance.
    public var errorDescription: String? { self.description }

    // `LocalizedError` conformance.
    public var failureReason: String? { self.description }
}
