public protocol AnyModel: Schema, CustomStringConvertible { }

extension AnyModel {
    public static var alias: String? { nil }
}

extension AnyModel {
    public var description: String {
        let input = self.collectInput()
        let info = [
            "input": !input.isEmpty ? input.description : nil,
            "output": self.anyID.cachedOutput?.description
        ].compactMapValues({ $0 })
        
        return "\(Self.self)(\(info.isEmpty ? ":" : info.map { "\($0): \($1)" }.joined(separator: ", ")))"
    }

    // MARK: Joined

    public func joined<Joined>(_ model: Joined.Type) throws -> Joined
        where Joined: Schema
    {
        guard let output = self.anyID.cachedOutput else {
            fatalError("Can only access joined models using models fetched from database (from \(Self.self) to \(Joined.self)).")
        }
        let joined = Joined()
        try joined.output(from: output.qualifiedSchema(space: Joined.spaceIfNotAliased, Joined.schemaOrAlias))
        return joined
    }

    var anyID: AnyID {
        for (nameC, child) in _FastChildSequence(subject: self) {
            /// Match a property named `_id` which conforms to `AnyID`. `as?` is expensive, so check that last.
            if nameC?[0] == 0x5f/* '_' */,
               nameC?[1] == 0x69/* 'i' */,
               nameC?[2] == 0x64/* 'd' */,
               nameC?[3] == 0x00/* '\0' */,
               let idChild = child as? AnyID
            {
                return idChild
            }
        }
        fatalError("id property must be declared using @ID or @CompositeID")
    }
}
