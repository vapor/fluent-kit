import Foundation

public enum FluentError: Error, LocalizedError, CustomStringConvertible, CustomDebugStringConvertible {
    case idRequired
    case invalidField(name: String, valueType: Any.Type, error: Error)
    case missingField(name: String)
    case relationNotLoaded(name: String)
    case missingParent(from: String, to: String, key: String, id: String)
    case noResults

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

    public var debugDescription: String {
        switch self {
        case .idRequired, .missingField(_), .relationNotLoaded(_), .missingParent(_, _, _, _), .noResults:
            return self.description
        case .invalidField(let name, let valueType, let error):
            return "invalid field: '\(name)', type: \(valueType), error: \(String(reflecting: error))"
        }
    }

    public var errorDescription: String? {
        return self.description
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
