public struct DatabaseID: Hashable, Codable {
    public let string: String
    public init(string: String) {
        self.string = string
    }
}
