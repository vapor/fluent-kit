public final class Row<Model>: Codable, CustomStringConvertible
    where Model: FluentKit.Model
{
    public var exists: Bool {
        #warning("support changing id")
        return self.storage.exists
    }
    
    public var storage: ModelStorage
    
    public init(storage: ModelStorage) {
        self.storage = storage
    }
    
    public convenience init() {
        self.init(storage: DefaultModelStorage(output: nil, eagerLoads: [:], exists: false))
    }
    
    public convenience init(from decoder: Decoder) throws {
        let decoder = try ModelDecoder(decoder: decoder)
        self.init()
        for field in Model.default.all {
            do {
                try field.decode(from: decoder, to: &self.storage)
            } catch {
                print("Could not decode \(field.name): \(error)")
            }
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var encoder = ModelEncoder(encoder: encoder)
        for property in Model.default.all {
            try property.encode(to: &encoder, from: self.storage)
        }
    }
    
    public var description: String {
        let input: String
        if self.storage.input.isEmpty {
            input = "nil"
        } else {
            input = self.storage.input.description
        }
        let output: String
        if let o = self.storage.output {
            output = o.description
        } else {
            output = "nil"
        }
        return "\(Model.self)(input: \(input), output: \(output))"
    }
}
