import Foundation

public enum FluentError: Error, LocalizedError, CustomStringConvertible {
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
            return "invalid field: \(name) type: \(valueType) error: \(error)"
        case .noResults:
            return "Query returned no results"
        }
    }

    public var errorDescription: String? {
        return self.description
    }
}
