public struct Children<Value>
    where Value: Model
{
    public let name: String
    
    public init(_ name: String) {
        self.name = name
    }
    
    func encode(to encoder: inout ModelEncoder, from storage: ModelStorage) throws {
        #warning("TODO: fixme")
    }
    
    func decode(from decoder: ModelDecoder, to storage: inout ModelStorage) throws {
        #warning("TODO: fixme")
    }
}
