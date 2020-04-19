import EchoProperties

public protocol AnyModel: Schema, CustomStringConvertible { }

extension AnyModel {
    public static var alias: String? { nil }
}

extension AnyModel {
    public var description: String {
        var info: [InfoKey: CustomStringConvertible] = [:]

        if !self.input.values.isEmpty {
            info["input"] = self.input.values
        }

        if let output = self.anyID.cachedOutput {
            info["output"] = output
        }

        return "\(Self.self)(\(info.debugDescription.dropFirst().dropLast()))"
    }

    // MARK: Joined

    public func joined<Joined>(_ model: Joined.Type) throws -> Joined
        where Joined: Schema
    {
        guard let output = self.anyID.cachedOutput else {
            fatalError("Can only access joined models using models fetched from database.")
        }
        let joined = Joined()
        try joined.output(from: output.schema(Joined.schemaOrAlias))
        return joined
    }

    var anyID: AnyID {
        let kps = Reflection.allNamedKeyPaths(for: self)
        guard let idKp = kps.first(where: { $0.name == "_id" }),
              let id = self[keyPath: idKp.keyPath] as? AnyID else {
            fatalError("id property must be declared using @ID")
        }
        
        return id
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
