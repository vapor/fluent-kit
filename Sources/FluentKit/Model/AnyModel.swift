public protocol AnyModel: class, Codable {
    var properties: [Property] { get }
    var storage: Storage { get set }
    var entity: String { get }
    init(storage: Storage)
}

extension AnyModel {
    public typealias Property = ModelProperty
    public typealias Storage = ModelStorage
}

extension AnyModel {
    public init() {
        self.init(storage: DefaultModelStorage(output: nil, eagerLoads: [:], exists: false))
    }
}

extension AnyModel where Self: Encodable {
    public func encode(to encoder: Encoder) throws {
        var encoder = ModelEncoder(encoder: encoder)
        for field in self.properties {
            try field.encode(to: &encoder)
        }
    }
}

extension AnyModel where Self: Decodable {
    public init(from decoder: Decoder) throws {
        let decoder = try ModelDecoder(decoder: decoder)
        self.init()
        for field in self.properties {
            do {
                try field.decode(from: decoder)
            } catch {
                print("Could not decode \(field.name): \(error)")
            }
        }
    }
}

extension AnyModel {
    public var exists: Bool {
        #warning("support changing id")
        return self.storage.output != nil
    }
}


extension AnyModel {
    public var entity: String {
        return "\(Self.self)"
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
        return "\(Self.self)(input: \(input), output: \(output))"
    }
}
