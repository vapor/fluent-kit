/// A protocol which designates a conforming type as representing a database relation of any kind. Intended
/// for use only by FluentKit property wrappers.
///
/// - Note: This protocol should probably require conformance to ``Property``, but adding that requirement
///   wouldn't have enough value to be worth having to hand-wave a technically semver-major change.
public protocol Relation {
    associatedtype RelatedValue
    var name: String { get }
    var value: RelatedValue? { get set }
    func load(on database: Database) -> EventLoopFuture<Void>
}

extension Relation {
    /// Return the value of the relation, loading it first if necessary.
    ///
    /// If the value is loaded (including reloading), the value is set in the property before being returned.
    ///
    /// - Note: This API is strongly preferred over ``Relation/load(on:)``, even when the caller does not need
    ///   the returned value, in order to minimize unnecessary database traffic.
    ///
    /// - Parameters:
    ///   - reload: If `true`, load the value from the database unconditionally, overwriting any previously
    ///     loaded value.
    ///   - database: The database to use if the value needs to be loaded.
    /// - Returns: The loaded value.
    public func get(reload: Bool = false, on database: Database) -> EventLoopFuture<RelatedValue> {
        if let value = self.value, !reload {
            return database.eventLoop.makeSucceededFuture(value)
        } else {
            return self.load(on: database).flatMapThrowing {
                guard let value = self.value else { // This should never actually happen, but just in case...
                    throw FluentError.relationNotLoaded(name: self.name)
                }
                return value
            }
        }
    }
}
    
/// A helper type used by ``ChildrenProperty`` and ``OptionalChildProperty`` to generically track the keypath
/// of the property of the child model that defines the parent-child relationship.
///
/// This type was extracted from its original definitions as a subtype of the property types. A typealias is
/// provided on the property types to maintain public API compatibility.
public enum RelationParentKey<From, To>
    where From: FluentKit.Model, To: FluentKit.Model
{
    case required(KeyPath<To, To.Parent<From>>)
    case optional(KeyPath<To, To.OptionalParent<From>>)
}

extension RelationParentKey: CustomStringConvertible {
    public var description: String {
        switch self {
        case .optional(let keypath): return To.path(for: keypath.appending(path: \.$id)).description
        case .required(let keypath): return To.path(for: keypath.appending(path: \.$id)).description
        }
    }
}

