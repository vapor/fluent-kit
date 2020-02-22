import NIO

public protocol AnyModel: Fields, CustomStringConvertible {
    static var schema: String { get }
}

extension AnyModel {
    public var description: String {
        var info: [InfoKey: CustomStringConvertible] = [:]

        if !self.input.values.isEmpty {
            info["input"] = self.input.values
        }

        if let output = self.anyID.cachedOutput {
            info["output"] = output.row
        }

        return "\(Self.self)(\(info.debugDescription.dropFirst().dropLast()))"
    }

    // MARK: Joined

    public func joined<Joined>(_ model: Joined.Type) throws -> Joined.Model
        where Joined: ModelAlias
    {
        guard let output = self.anyID.cachedOutput else {
            fatalError("Can only access joined models using models fetched from database.")
        }
        let joined = Joined.Model()
        try joined.output(
            from: output.row.prefixed(by: Joined.alias + "_").output(for: output.database)
        )
        return joined
    }

    public func joined<Joined>(_ model: Joined.Type) throws -> Joined
        where Joined: FluentKit.Model
    {
        guard let output = self.anyID.cachedOutput else {
            fatalError("Can only access joined models using models fetched from database.")
        }
        let joined = Joined()
        try joined.output(
            from: output.row.prefixed(by: Joined.schema + "_").output(for: output.database)
        )
        return joined
    }

    var anyID: AnyID {
        let mirror = Mirror(reflecting: self)
        let children = mirror.children
        
        let table = idTable.currentValue ?? AnyIDTable()
        let value: Any
        
        if let index = table.ids.first(where: { $0.typeId == ObjectIdentifier(Self.self) })?.1 {
            value = children[index].value
        } else {
            guard let index = children.firstIndex(where: { $0.label == "_id" }) else {
                fatalError("id property must be declared using @ID")
            }
            
            value = children[index].value
        }
        
        assert(value is AnyID, "id property did not conform to AnyID, make sure it's declared using @ID")
        
        return value as! AnyID
    }
}

private final class AnyIDTable {
    var ids: [(typeId: ObjectIdentifier, offset: AnyIndex)] = []
    
    init() {}
}

private let idTable = ThreadSpecificVariable<AnyIDTable>()

extension Fields {

    // MARK: Internal
    func label(for property: AnyProperty) -> String {
        for (label, p) in self.properties {
            if property === p {
                return label
            }
        }
        fatalError("Property not found on model: \(property)")
    }
}

private struct InfoKey: ExpressibleByStringLiteral, Hashable, CustomStringConvertible {
    let value: String
    var description: String {
        return self.value
    }
    init(stringLiteral value: String) {
        self.value = value
    }
}
