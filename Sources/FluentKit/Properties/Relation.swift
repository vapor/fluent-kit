public protocol RelationType {
    init(nameOverride: String?)
}

@propertyWrapper
public final class Relation<R> where R: RelationType {
    public init() {
        self.value = .init(nameOverride: nil)
    }
    
    public init(_ name: String) {
        self.value = .init(nameOverride: name)
    }

    public var value: R
}

