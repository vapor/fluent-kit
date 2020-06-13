public protocol AnyOptionalType {
    static var wrappedType: Any.Type { get }
    static var `nil`: Any { get }
    var wrappedValue: Any? { get }
}

public protocol OptionalType: AnyOptionalType {
    associatedtype Wrapped
    init(_ wrapped: Wrapped)
}

extension OptionalType {
    public static var wrappedType: Any.Type {
        return Wrapped.self
    }
}

extension Optional: OptionalType {
    public static var `nil`: Any {
        Self.none as Any
    }

    public var wrappedValue: Any? {
        self
    }
}
