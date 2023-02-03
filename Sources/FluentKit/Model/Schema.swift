public protocol Schema: Fields {
    static var space: String? { get }
    static var schema: String { get }
    static var alias: String? { get }
}

extension Schema {
    public static var space: String? { nil }
    
    public static var schemaOrAlias: String {
        self.alias ?? self.schema
    }
    
    static var spaceIfNotAliased: String? {
        return self.alias == nil ? self.space : nil
    }
}
