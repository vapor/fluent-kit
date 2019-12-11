import Foundation

public enum FluentError: Error, LocalizedError, CustomStringConvertible {
    case idRequired
    case invalidField(name: String, valueType: Any.Type)
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
        case .invalidField(let name, let valueType):
            return "invalid field: \(name), expected type: \(valueType)"
        case .noResults:
            return "Query returned no results"
        }
    }

    public var errorDescription: String? {
        return self.description
    }

    public var isNoResults: Bool {
        guard case .noResults = self else { return false }
        return true
    }
}
