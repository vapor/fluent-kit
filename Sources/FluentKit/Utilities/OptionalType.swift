public protocol AnyOptionalType {
    static var wrappedType: Any.Type { get }
}

public protocol OptionalType: AnyOptionalType {
    associatedtype Wrapped
}

extension OptionalType {
    public static var wrappedType: Any.Type {
        return Wrapped.self
    }
}

extension Optional: OptionalType { }
