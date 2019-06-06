public protocol RelationType {
    init()
}

@propertyWrapper
public final class Relation<R> where R: RelationType {
    public init() {
        self.value = .init()
    }

    public var value: R
}

