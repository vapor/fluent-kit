public protocol AnyOptionalType {
    static var wrappedType: Any.Type { get }
    var wrappedValue: Any? { get }
}

public protocol OptionalType: AnyOptionalType {
    associatedtype Wrapped

    init()
    init(_ value: Wrapped)
}

extension OptionalType {
    public static var wrappedType: Any.Type {
        return Wrapped.self
    }
}

extension Optional: OptionalType {
    public init() {
        self = .none
    }

    public var wrappedValue: Any? {
        return self
    }
}
