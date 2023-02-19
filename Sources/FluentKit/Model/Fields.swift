/// A type conforming to ``Fields`` is able to use FluentKit's various property wrappers to declare
/// name, type, and semantic information for individual properties corresponding to fields in a
/// generic database storage system.
///
/// ``Fields`` is usually only used directly when in conjunction with the `@Group` and `@CompositeID`
/// property types. The ``Schema`` and ``Model`` protocols build on ``Fields`` to provide additional
/// capabilities and semantics.
///
/// Most of the protocol requirements of ``Fields`` are implemented in FluentKit. A conformant type
/// needs only to provide the definition of ``init()``, which will in turn almost always be empty.
/// (In fact, FluentKit would provide this implementation as well if the language permitted.) Providing
/// custom implementations of any other requirements is **strongly** discouraged; under most
/// circumstances, such implementations will not be invoked in any event. They are only declared on
/// the base protocol rather than solely in extensions because static dispatch improves performance.
public protocol Fields: AnyObject, Codable {
    /// Returns a fully generic list of every property on the given instance of the type which uses any of
    /// the FluentKit property wrapper types (e.g. any wrapper conforming to ``AnyProperty``). This accessor
    /// is not static because FluentKit depends upon access to the backing storage of the property wrappers,
    /// which is specific to each instance.
    ///
    /// - Warning: This accessor triggers the use of reflection, which is at the time of this writing the
    ///   most severe performance bottleneck in FluentKit by a huge margin. Every access of this property
    ///   carries the same cost; it is not possible to meaningfully cache the results. See
    ///   `MirrorBypass.swift` for a considerable amount of very low-level detail.
    var properties: [AnyProperty] { get }
    
    init()
    
    func input(to input: DatabaseInput)
    func output(from output: DatabaseOutput) throws
}

// MARK: Path

extension Fields {
    /// Returns an array of ``FieldKey``s representing the individual textual components of the full path
    /// of the database field corresponding to the given Swift property. This method can only reference
    /// properties which represent actual fields in the database, corresponding to the ``AnyQueryableProperty``
    /// protocol - for example, it can not be used with with the `@Children` property type, nor directly
    /// with an `@Parent` property.
    ///
    /// Almost all properties have only a single path component; support for multistep paths is primarily
    /// intended to support drilling down into JSON structures. At the time of this writing, the current
    /// version of FluentKit will always yield field paths with exactly one component. Unfortunately, the
    /// API can not be changed to eliminate the array wrapper without major source breakage.
    public static func path<Property>(for field: KeyPath<Self, Property>) -> [FieldKey]
        where Property: AnyQueryableProperty
    {
         Self.init()[keyPath: field].path
    }
}

// MARK: Database

extension Fields {
    /// Return an array of all database keys (i.e. non-nested field names) defined by all properties
    /// declared on the type. This includes properties which may contain multiple fields at once, such
    /// as `@Group`.
    public static var keys: [FieldKey] {
        self.init().databaseProperties.flatMap(\.keys)
    }

    /// For each property declared on the type, if that property is marked as having changed since the
    /// type was either loaded or created, add the key-value pair for said property to the given database
    /// input object. This prepares data in memory to be written to the database.
    ///
    /// - Note: It is trivial to construct ``DatabaseInput`` objects which do not in fact actually transfer
    ///   their contents to a database. FluentKit itself does this to implement a save/restore operation for
    ///   model state under certain conditions (see ``Model``).
    public func input(to input: DatabaseInput) {
        for field in self.databaseProperties {
            field.input(to: input)
        }
    }

    /// For each property declared on the type, if that property's key is available in the given database
    /// output object, attempt to load the corresponding value into the property. This transfers data
    /// received from the database into memory.
    ///
    /// - Note: It is trivial to construct ``DatabaseOutput`` objects which do not in fact actually represent
    ///   data from a database. FluentKit itself does this to help keep models up to date (see ``Model``).
    public func output(from output: DatabaseOutput) throws {
        for field in self.databaseProperties {
            try field.output(from: output)
        }
    }
}

// MARK: Properties

extension Fields {
    /// Default implementation of ``Fields/properties-dup4``.
    public var properties: [AnyProperty] {
        return _FastChildSequence(subject: self).compactMap { $1 as? AnyProperty }
    }
    
    /// A wrapper around ``properties`` which returns only the properties which have database keys and can be
    /// input to and output from a database (corresponding to the ``AnyDatabaseProperty`` protocol).
    internal var databaseProperties: [AnyDatabaseProperty] {
        self.properties.compactMap { $0 as? AnyDatabaseProperty }
    }

    /// Returns all properties which can be serialized and deserialized independently of a database via the
    /// built-in ``Codable`` machinery (corresponding to the ``AnyCodableProperty`` protocol), indexed by
    /// the coding key for each property.
    ///
    /// - Important: A property's _coding_ key is not the same as a _database_ key. The coding key is derived
    ///   directly from the property's Swift name as provided by reflection, while database keys are provided
    ///   in the property wrapper initializer declarations.
    ///
    /// - Warning: Even if the type has a custom ``CodingKeys`` enum, the property's coding key will _not_
    ///   correspond to the definition provided therein; it will always be based solely on the Swift
    ///   property name.
    ///
    /// - Warning: Like ``properties``, this method uses reflection, and incurs all of the accompanying
    ///   performance penalties.
    internal var codableProperties: [SomeCodingKey: AnyCodableProperty] {
        return .init(uniqueKeysWithValues: _FastChildSequence(subject: self).compactMap {
            guard let value = $1 as? AnyCodableProperty,
                  let nameC = $0, nameC[0] != 0, nameC[1] != 0,
                  let name = String(utf8String: nameC + 1)
            else {
                return nil
            }
            return (.init(stringValue: name), value)
        })
    }
}

// MARK: Has Changes

extension Fields {
    /// Returns `true` if a model has fields whose values have been explicitly set or modified
    /// since the most recent load from and/or save to the database (if any).
    ///
    /// If `false` is returned, attempts to save changes to the database (or more precisely, to
    /// send values to any given ``DatabaseInput``) will do nothing.
    public var hasChanges: Bool {
        let input = HasChangesInput()
        self.input(to: input)
        return input.hasChanges
    }
}

/// Helper type for the implementation of ``Fields/hasChanges``.
private final class HasChangesInput: DatabaseInput {
    var hasChanges: Bool = false

    func set(_: DatabaseQuery.Value, at _: FieldKey) {
        self.hasChanges = true
    }
}

// MARK: Collect Input

extension Fields {
    /// Returns a dictionary of field keys and associated values representing all "pending"
    /// data - e.g. all fields (if any) which have been changed by something other than Fluent.
    internal func collectInput() -> [FieldKey: DatabaseQuery.Value] {
        let input = DictionaryInput()
        self.input(to: input)
        return input.storage
    }
}

/// Helper type for the implementation of `Fields.collectInput()`.
private final class DictionaryInput: DatabaseInput {
    var storage: [FieldKey: DatabaseQuery.Value] = [:]

    func set(_ value: DatabaseQuery.Value, at key: FieldKey) {
        self.storage[key] = value
    }
}
