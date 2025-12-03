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

    public static var spaceIfNotAliased: String? {
        self.alias == nil ? self.space : nil
    }
}
