public final class ModelRow<Model>: Codable, CustomStringConvertible
    where Model: FluentKit.Model
{
    public var exists: Bool {
        #warning("support changing id")
        return self.storage.exists
    }
    
    var storage: ModelStorage
    
    init(storage: ModelStorage) throws {
        self.storage = storage
        try self.storage.cacheOutput(for: Model.self)
    }
    
    public init() {
        self.storage = DefaultModelStorage(output: nil, eagerLoads: [:], exists: false)
    }
    
    public convenience init(from decoder: Decoder) throws {
        let decoder = try ModelDecoder(decoder: decoder)
        self.init()
        for field in Model.shared.all {
            do {
                try field.decode(from: decoder, to: &self.storage)
            } catch {
                print("Could not decode \(field.name): \(error)")
            }
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var encoder = ModelEncoder(encoder: encoder)
        for property in Model.shared.all {
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
