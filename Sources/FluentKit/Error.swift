import Foundation

public enum FluentError: Error, LocalizedError, CustomStringConvertible {
    case idRequired
    case invalidField(name: String, valueType: Any.Type, error: Error)
    case missingField(name: String)
    case missingEagerLoad(name: String)
    case missingParent
    case noResults

    public var description: String {
        switch self {
        case .idRequired:
            return "ID required"
        case .missingField(let name):
            return "field missing: \(name)"
        case .missingEagerLoad(let name):
            return "eager load missing: \(name)"
        case .missingParent:
            return "parent missing"
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
