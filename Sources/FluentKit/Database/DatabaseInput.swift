/// A helper type for working with properties which conform to the ``AnyDatabaseProperty`` protocol.
///
/// All types conforming to either ``Fields`` or ``AnyDatabaseProperty`` provide an `input(to:)` method
/// (see ``Fields/input(to:)-3g6gt`` and ``AnyDatabaseProperty/input(to:)``). This method in turn calls
/// the ``DatabaseInput/set(_:at:)`` method of the provided ``DatabaseInput`` once for each ``FieldKey``
/// the implementing type is responsible for, providing both the key and the ``DatabaseQuery/Value``
/// associated with that key.
///
/// As the protocol name suggests, the primary purpose of ``DatabaseInput`` is to allow a complete set of
/// data, in the form of a key-value map, to be generically gathered for input "into" a database. However,
/// to allow useful semantics such as composition (such as transparently remapping field keys) and alternate
/// data handling (such as saving existing state so it can be temporarily overwritten), this mechanism is
/// expressed as a protocol rather than just handing around a dictionary or other similar structure.
///
/// > TODO: Define a new protocol formalizing the `input(to:)` and `output(from:)` methods found on both
///   ``AnyDatabaseProperty`` and ``Fields``, and have them conform to it rather than independently
///   providing identical requirements. This will allow inputtable and outputtable (corresponding to
///   encodable and decodable) types to be generically addressed cleanly.
///
/// > See Also: ``FluentKit/DatabaseOutput``
public protocol DatabaseInput {
    /// Called by individual database properties to register a given field key and associated database
    /// value as part of the data set represented by the ``DatabaseInput``.
    ///
    /// Implemented by conforming types to handle key/value pairs provided by callers.
    ///
    /// Setting a value for a key which has already been registered is expected to overwrite the old
    /// value with the new. Conforming types _can_ choose alternative semantics, but must take care
    /// that doing so is compatible with the expectations of callers.
    ///
    /// > Note: As a rule, a key being set multiple times for a single input usually indicates or at
    ///   least implies buggy behavior (such as a Model which specifies a particular key in more than
    ///   one of its properties). However, there are cases where doing so is useful; as such, no
    ///   attempt is made to diagnose multiple sets for the same key and the API must permit said
    ///   behavior unless the semantics of the conforming type explicitly require otherwise and
    ///   the alternate behavior is clearly documented.
    func set(_ value: DatabaseQuery.Value, at key: FieldKey)
    
    /// Indicates whether this ``DatabaseInput`` instance is requesting key/value pairs for _all_ defined
    /// database fields regardless of status, or only those pairs where the current value
    /// is known to be out of date (also referred to variously as "dirty", "modified", or "has changes").
    ///
    /// By default, only changed values are requested. This choice was made because this property was
    /// added long after the first release of the protocol, before which time unmodified properties were
    /// always unconditionally omitted; as such, in order to remain fully source-compatible with existing
    /// conforming types, there must be a default which is chosen so as to preserve existing behavior.
    ///
    /// For the purposes of this flag, when the value is `true`, both unmodified _and unset_ properties
    /// should be included. The value of unset properties should be ``DatabaseQuery/Value/default``.
    ///
    /// > Important: The value of this property _MUST NOT_ change during the instance's lifetime. It is
    ///   generally recommended - though not required - that it be a constant value. This is the case for
    ///   all ``DatabaseInput`` types in FluentKit at the time of this writing. It has been left as an
    ///   instance property rather than being declared `static` to avoid artificially limiting the
    ///   flexibility of conforming types.
    ///
    /// > Warning: While all of FluentKit's built-in property wrapper types correctly honor this flag, if
    ///   there are any custom property types in use which do not defer to a builtin type as a backing
    ///   store (as ``IDProperty`` does, for example), that type's ``AnyDatabaseProperty`` conformance must
    ///   be updated accordingly.
    var wantsUnmodifiedKeys: Bool { get }
}

extension DatabaseInput {
    /// Default implementation of ``wantsUnmodifiedKeys-4tisb``. Always assume the old behavior (modified
    /// data only) unless explcitly told otherwise.
    public var wantsUnmodifiedKeys: Bool {
        false
    }
}

extension DatabaseInput {
    /// Return a ``DatabaseInput`` wrapping `self` so as to apply a given prefix to each field key
    /// before processing.
    public func prefixed(by prefix: FieldKey) -> DatabaseInput {
        PrefixedDatabaseInput(prefix: prefix, strategy: .none, base: self)
    }
    
    /// Return a ``DatabaseInput`` wrapping `self` so as to apply a given prefix, according to a given
    /// ``KeyPrefixingStrategy``, to each field key before processing.
    public func prefixed(by prefix: FieldKey, using stratgey: KeyPrefixingStrategy) -> DatabaseInput {
        PrefixedDatabaseInput(prefix: prefix, strategy: stratgey, base: self)
    }
}

/// A ``DatabaseInput`` which applies a key prefix according to a ``KeyPrefixingStrategy`` to each key
/// sent to it before passing the resulting key and the unmodified value on to another ``DatabaseInput``.
private struct PrefixedDatabaseInput<Base: DatabaseInput>: DatabaseInput {
    let prefix: FieldKey
    let strategy: KeyPrefixingStrategy
    let base: Base
    
    var wantsUnmodifiedKeys: Bool { self.base.wantsUnmodifiedKeys }

    func set(_ value: DatabaseQuery.Value, at key: FieldKey) {
        self.base.set(value, at: self.strategy.apply(prefix: self.prefix, to: key))
    }
}

/// A ``DatabaseInput`` which generates a ``DatabaseQuery/Filter`` based on each key-value pair sent to it,
/// using ``DatabaseQuery/Filter/Method/equal``, and adds each such filter to a ``QueryBuilder``.
///
/// All fields directed to the input are assumed to belong to the entity referenced by `InputModel`, which
/// need not be the same as `BuilderModel` (the base model of the query builder). This permits filtering
/// to be applied based on a joined model, and enables support for ``ModelAlias``.
///
/// If ``QueryFilterInput/inverted`` is `true`, the added filters will use the ``DatabaseQuery/Filter/Method/notEqual``
/// method instead.
///
/// The ``DatabaseInput/wantsUnmodifiedKeys-1qajw`` flag is enabled for this input type.
///
/// The query builder is modified in-place. Callers may either retain their own reference to the builder or
/// retrieve it from this structure when ready. It is the caller's responsibility to ensure that grouping of
/// multiple filters is handled appropriately for their use case - most commonly by using the builder passed
/// to a  ``QueryBuilder/group(_:_:)`` closure to create an instance of this type.
///
/// > Tip: Applying a query filter via database input is especially useful as a means of providing generic
///   support for filters involving a ``CompositeIDProperty``. For example, using an instance of this type
///   as the input for a ``CompositeParentProperty`` filters the query according to the set of appropriately
///   prefixed field keys the property encapsulates.
internal struct QueryFilterInput<BuilderModel: FluentKit.Model, InputModel: Schema>: DatabaseInput {
    let builder: QueryBuilder<BuilderModel>
    let inverted: Bool
    
    var wantsUnmodifiedKeys: Bool { true }
    
    init(builder: QueryBuilder<BuilderModel>, inverted: Bool = false) where BuilderModel == InputModel {
        self.init(BuilderModel.self, builder: builder, inverted: inverted)
    }
    
    init(_: InputModel.Type, builder: QueryBuilder<BuilderModel>, inverted: Bool = false) {
        self.builder = builder
        self.inverted = inverted
    }

    func set(_ value: DatabaseQuery.Value, at key: FieldKey) {
        self.builder.filter(
            .extendedPath([key], schema: InputModel.schemaOrAlias, space: InputModel.spaceIfNotAliased),
            self.inverted ? .notEqual : .equal,
            value
        )
    }
}

/// A ``DatabaseInput`` which passes all keys through to another ``DatabaseInput`` with
/// ``DatabaseQuery/Value/null`` as the value, ignoring any value provided.
///
/// The ``DatabaseInput/wantsUnmodifiedKeys-1qajw`` flag is always set regardless of what the
/// "base" input requested, as the use case for this input is to easily specify an explicitly
/// nil composite relation.
internal struct NullValueOverrideInput<Base: DatabaseInput>: DatabaseInput {
    let base: Base
    var wantsUnmodifiedKeys: Bool { true }
    
    func set(_: DatabaseQuery.Value, at key: FieldKey) {
        self.base.set(.null, at: key)
    }
}

extension DatabaseInput {
    /// Returns `self` wrapped with a ``NullValueOverrideInput``. This is here primarily so the actual
    /// implementation be defined generically rather than using existentials.
    internal func nullValueOveridden() -> DatabaseInput {
        NullValueOverrideInput(base: self)
    }
}
