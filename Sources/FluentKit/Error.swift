public enum FluentError: Error {
    case missingField(name: String)
    case missingEagerLoad(name: String)
}
