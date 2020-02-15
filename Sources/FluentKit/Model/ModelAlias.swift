public protocol ModelAlias {
    associatedtype Model: FluentKit.Model
    static var alias: String { get }
}
