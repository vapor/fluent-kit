public struct DatabaseEnum {
    public enum Action {
        case create
        case update
        case delete
    }

    public var action: Action
    public var name: String

    public var createCases: [String]
    public var deleteCases: [String]

    public init(name: String) {
        self.action = .create
        self.name = name
        self.createCases = []
        self.deleteCases = []
    }
}
