public protocol Schema: Fields {
    static var schema: String { get }
    static var alias: String? { get }
}

extension Schema {
    public static var schemaOrAlias: String {
        self.alias ?? self.schema
    }
}
