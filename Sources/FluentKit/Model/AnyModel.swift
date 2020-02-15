public protocol AnyModel: class, CustomStringConvertible, Codable {
    static var schema: String { get }
    init()
}

extension AnyModel {
    // MARK: Description

    public var description: String {
        var info: [InfoKey: CustomStringConvertible] = [:]

        if !self.input.isEmpty {
            info["input"] = self.input
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

    // MARK: Internal

    var anyID: AnyID {
        guard let id = Mirror(reflecting: self).descendant("_id") as? AnyID else {
            fatalError("id property must be declared using @ID")
        }
        return id
    }

    func label(for property: AnyProperty) -> String {
        for (label, p) in self.properties {
            if property === p {
                return label
            }
        }
        fatalError("Property not found on model: \(property)")
    }

    var input: [String: DatabaseQuery.Value] {
        var input: [String: DatabaseQuery.Value] = [:]
        for (_, field) in self.fields {
            input[field.key] = field.inputValue
        }
        return input
    }

    func output(from output: DatabaseOutput) throws {
        try self.properties.forEach { (_, property) in
            try property.output(from: output)
        }
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
