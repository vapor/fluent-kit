public protocol AnyModel: Schema, CustomStringConvertible { }

extension AnyModel {
    public static var alias: String? { nil }
}

extension AnyModel {
    public var description: String {
        var info: [InfoKey: CustomStringConvertible] = [:]

        let input = self.collectInput()
        if !input.isEmpty {
            info["input"] = input
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
            fatalError("Can only access joined models using models fetched from database (from \(Self.self) to \(Joined.self)).")
        }
        let joined = Joined()
        try joined.output(from: output.schema(Joined.schemaOrAlias))
        return joined
    }

    var anyID: AnyID {
        for (nameC, child) in _FastChildSequence(subject: self) {
            /// Match a property named `_id` which conforms to `AnyID`. `as?` is expensive, so check that last.
            if nameC?.advanced(by: 0).pointee == 0x5f/* '_' */, nameC?.advanced(by: 1).pointee == 0x69/* 'i' */,
               nameC?.advanced(by: 2).pointee == 0x64/* 'd' */, nameC?.advanced(by: 3).pointee == 0x00/* '\0' */,
               let idChild = child as? AnyID
            {
                return idChild
            }
        }
        fatalError("id property must be declared using @ID or @CompositeID")
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
