public enum FluentError: Error {
    case idRequired
    case missingField(name: String)
    case missingEagerLoad(name: String)
}
