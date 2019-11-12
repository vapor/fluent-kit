public struct DatabaseID: Hashable, Codable {
    public static let `default` = DatabaseID(string: "default")
    
    public let string: String
    public init(string: String) {
        self.string = string
    }
}
