public struct DatabaseID: Hashable, Codable, Sendable {
    public let string: String
    public init(string: String) {
        self.string = string
    }
}
