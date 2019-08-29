public protocol AnyOptionalType {
    static var wrappedType: Any.Type { get }
}

public protocol OptionalType: AnyOptionalType {
    associatedtype Wrapped

    var value: Optional<Wrapped> { get }
}

extension OptionalType {
    public static var wrappedType: Any.Type { Wrapped.self }
}

extension Optional: OptionalType {
    public var value: Optional<Wrapped> { self }
}
