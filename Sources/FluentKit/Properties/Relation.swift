import NIOCore

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

/// A helper type used by ``CompositeChildrenProperty`` and ``CompositeOptionalChildProperty`` to generically
/// track the keypath of the property of the child model that defines the parent-child relationship.
///
/// Unfortunately, the additional generic constraint requiring `From.IDValue` to conform to ``Fields`` for the
/// purposes of ``CompositeChildrenProperty`` etc. makes it impractical to combine this and ``RelationParentKey``
/// in a single helper type.
///
/// - Note: This type is public partly to allow FluentKit users to introspect model metadata, but mostly it's
///   to maintain parity with ``RelationParentKey``, which was public in its original definition.
public enum CompositeRelationParentKey<From, To>
    where From: FluentKit.Model, To: FluentKit.Model, From.IDValue: Fields
{
    case required(KeyPath<To, To.CompositeParent<From>>)
    case optional(KeyPath<To, To.CompositeOptionalParent<From>>)
    
    /// Use the stored key path to retrieve the appropriate parent ID from the given child model.
    internal func referencedId(in model: To) -> From.IDValue? {
        switch self {
        case .required(let keypath): return model[keyPath: keypath].id
        case .optional(let keypath): return model[keyPath: keypath].id
        }
    }
    
    /// Use the parent property specified by the key path to filter the given query builder by each of the
    /// given parent IDs in turn. An empty ID list will apply no filters.
    ///
    /// Callers are responsible for providing an OR-grouping builder, which produces "any child model whose
    /// parent has one of these IDs" behavior (combining the filter groups with `OR` is less efficient than
    /// using the `IN` operator, but `IN`  doesn't work with composite values).
    ///
    /// See ``QueryFilterInput`` for additional implementation details.
    internal func queryFilterIds<C>(_ ids: C, in builder: QueryBuilder<To>) -> QueryBuilder<To>
        where C: Collection, C.Element == From.IDValue
    {
        guard !ids.isEmpty else { return builder }
        switch self {
        case .required(let keypath):
            let prop = To()[keyPath: keypath]
            return ids.reduce(builder) { b, id in b.group(.and) { prop.id = id; prop.input(to: QueryFilterInput(builder: $0)) } }
        case .optional(let keypath):
            let prop = To()[keyPath: keypath]
            return ids.reduce(builder) { b, id in b.group(.and) { prop.id = id; prop.input(to: QueryFilterInput(builder: $0)) } }
        }
    }
}

extension CompositeRelationParentKey: CustomStringConvertible {
    public var description: String {
        switch self {
        case .required(let keypath): return To()[keyPath: keypath].prefix.description
        case .optional(let keypath): return To()[keyPath: keypath].prefix.description
        }
    }
}
