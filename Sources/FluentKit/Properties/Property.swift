/// The type-erased form of ``Property`` (see below). ``AnyProperty`` is used to
/// access a model's set of Fluent properties in a fully generic fashion (with a
/// little help from runtime reflection). It is generally not meaningful to conform
/// to this protocol without also at least conforming to ``Property``.
public protocol AnyProperty: AnyObject {
    static var anyValueType: Any.Type { get }
    var anyValue: Any? { get }
}

/// A property wrapper type conforms to this protocol to participate in Fluent's
/// system for interfacing between the various properties of a model and the
/// representations of those properties in a database. All properties whose
/// wrappers conform to this protocol appear in Fluent's list of the data items
/// which exist on a given model - whether those items contain actual data,
/// such as a property representing a field in a database table, or are means to
/// access other data, such a list of associated models on the far side of a
/// many-to-many relation.
public protocol Property: AnyProperty {
    associatedtype Model: Fields
    associatedtype Value: Codable
    var value: Value? { get set }
}

/// ``AnyProperty``'s requirements are implemented in terms of ``Property``'s
/// requirements - they're the same requirements; ``Property`` is just more
/// specific about the types.
extension AnyProperty where Self: Property {
    /// The type-erased value of a property is the property's value.
    public var anyValue: Any? {
        self.value
    }
    
    /// The type-erased type of a property's value is the type of the property's value.
    public static var anyValueType: Any.Type {
        Value.self
    }
}

/// Marks a property as having "database" capability - in other words, the property
/// receives output from the results of read queries, provides input to write queries,
/// and/or represents one or more model fields.
///
/// - Note: Most "database" properties participate in all three aspects (is/has fields,
///   provides input, receives output), but certain properties only participate in
///   receiving output (most notably the non-parent relation property types). Those
///   properties only behave in this manner because the ability to look up the needed
///   information on demand was not available in Swift until after the implementation was
///   effectively complete. They should not be considered actual "database" properties.
public protocol AnyDatabaseProperty: AnyProperty {
    var keys: [FieldKey] { get }
    func input(to input: DatabaseInput)
    func output(from output: DatabaseOutput) throws
}

/// Marks a property as participating in the ``Fields`` protocol's (defaulted)
/// implementation of `Decodable` and `Encodable`. This allows the property
/// to encode and decode to and from representations other than storage in a
/// database, and to act as a container if it contains any additional properties
/// which also wish to participate. Just about every property type is codable.
///
/// > Warning: The various relation property types sometimes behave somewhat oddly
///   when encoded and/or decoded.
///
/// > TODO: When corresponding parent and child properties on their respective models
///   refer to each other, such as due to both relations being eager-loaded, both
///   encoding and decoding will crash due to infinite recursion. At some point, look
///   into a way to at least error out rather than crashing.
public protocol AnyCodableProperty: AnyProperty {
    /// Encode the property's data to an external representation.
    func encode(to encoder: Encoder) throws
    
    /// Decode an external representation and replace the property's current data with the result.
    func decode(from decoder: Decoder) throws
    
    /// Return `true` to skip encoding of this property. Defaults to `false` unless explicitly
    /// implemented.
    ///
    /// This is used by ``Fields`` to work around limitations of `Codable` in an efficient manner.
    /// You probably don't need to bother with it.
    var skipPropertyEncoding: Bool { get }
}

extension AnyCodableProperty {
    /// Default implementation of ``AnyCodableProperty/skipPropertyEncoding-87r6k``.
    public var skipPropertyEncoding: Bool { false }
}

/// The type-erased form of ``QueryableProperty`` (see below). ``AnyQueryableProperty``
/// is used most often as a type-generic check for whether or not a given property
/// represents an actual database field.
public protocol AnyQueryableProperty: AnyProperty {
    /// Provides the database field's "path" - a nonempty list of field keys whose last
    /// item provides the name the field has in the database (which need not be the same
    /// as the name the corresponding model property has in Swift). A path containing
    /// more than one key theoretically describes a nested structure within the database,
    /// such as a field containing a complex JSON document, but at present this is not
    /// fully implemented by Fluent, making a multi-key path as invalid as an empty one.
    var path: [FieldKey] { get }
    
    /// If the property's current value has been set, return a description of the
    /// appropriate method for encoding that value into a database query. See
    /// ``DatabaseQuery/Value`` for more details. If the value is not set, the
    /// property must choose whether to request the `NULL` encoding or to return
    /// no value at all (whether or not this results in an error is highly context-
    /// dependent).
    func queryableValue() -> DatabaseQuery.Value?
}

/// Marks a property as being "queryable", meaning that it represents exactly one
/// "real" database field (i.e. the database table will contain a "physical" field
/// corresponding to the property, and it will be the only field that does so).
public protocol QueryableProperty: AnyQueryableProperty, Property {
    /// Requests a description of the appropriate method of encoding a value of the
    /// property's wrapped type into a database query. In essence, this is the static
    /// version of ``AnyQueryableProperty/queryableValue()-3uzih``, except that this
    /// version will always have an input and thus can not return `nil`.
    ///
    /// - Warning: The existence of this method implies that any two identically-typed
    ///   instances of a property _must_ encode their values into queries in exactly
    ///   the same fashion, and Fluent does have code paths which proceed on that
    ///   assumption. For example, this requirement is the primary reason that a
    ///   ``TimestampProperty``'s format is represented as a generic type parameter
    ///   rather than being provided to an initializer.
    static func queryValue(_ value: Value) -> DatabaseQuery.Value
}

extension AnyQueryableProperty where Self: QueryableProperty {
    /// By default, ``QueryableProperty``s uses ``QueryableProperty/queryValue(_:)-5df0n``
    /// to provide its ``AnyQueryableProperty/queryableValue()-4tkjo``. While it is not strictly required that
    /// this be the case, providing an alternative implementation risks violating the
    /// "identical encoding for identical property types" rule (see
    /// ``QueryableProperty/queryValue(_:)-5df0n``).
    public func queryableValue() -> DatabaseQuery.Value? {
        return self.value.map { Self.queryValue($0) }
    }
}

extension QueryableProperty {
    /// Since ``Property/Value`` conforms to `Codable`, the default encoding for
    /// any ``QueryableProperty``'s value is as a query placeholder and associated parameter
    /// binding (bindings are sent to a database driver encoded via `Encodable`).
    /// See ``DatabaseQuery/Value`` for more details on possible alternative encodings.
    public static func queryValue(_ value: Value) -> DatabaseQuery.Value {
        .bind(value)
    }
}

/// The type-erased form of ``QueryAddressableProperty`` (see below). Both protocols serve to
/// bridge the gap between `AnyQueryableProperty` - which describes a property whose singular
/// `Value` directly corresponds to the value stored in the database for that property - and
/// property types whose `Value` is a derivative of or expansion upon an underlying queryable
/// property. See the discussion of ``QueryAddressableProperty`` itself for additional details.
public protocol AnyQueryAddressableProperty: AnyProperty {
    var anyQueryableProperty: AnyQueryableProperty { get }
    var queryablePath: [FieldKey] { get }
}

/// Marks a property as being "query addressable", meaning that it is either itself queryable
/// (``QueryableProperty`` implies ``QueryAddressableProperty``), or it represents some other
/// single property that _is_ queryable. This allows properties whose purpose is to wrap or
/// otherwise stand in for other properties to be handled generically without the need to
/// add special case exceptions for those property types.
///
/// `@Parent` is the canonical example of an addressable, non-queryable property. It provides
/// the related model as its value, and contains a `@Field` property holding that model's ID.
/// That underlying property means the relation can be "addressed" by a query, but the value
/// type is wrong for it to be directly queryable. Providing the underlying field when the
/// relation is "addressed" allows handling a model's property list (or, say, the property
/// list of a ``Fields`` type being used as a composite ID value) fully generically and without
/// special-casing or having to revisit the logic if additional property types come along.
public protocol QueryAddressableProperty: AnyQueryAddressableProperty, Property {
    associatedtype QueryablePropertyType: QueryableProperty
    var queryableProperty: QueryablePropertyType { get }
}
