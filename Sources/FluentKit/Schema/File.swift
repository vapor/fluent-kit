import NIO
import Foundation

extension Database {
    /// Returns a schema builder that uses keypaths
    public func schema<M: Model>(_ type: M.Type) -> KeyPathSchemaBuilder<M> {
        KeyPathSchemaBuilder(database: self, type: type)
    }
}

public class KeyPathSchemaBuilder<M: Model> {
    let database: Database
    public var schema: DatabaseSchema

    init(database: Database, type: M.Type) {
        self.database = database
        self.schema = .init(schema: M.schema)
    }

    /// Adds an manually defined  field with the given parameters
    public func defineField(name: DatabaseSchema.FieldName, dataType: DatabaseSchema.DataType, constraints: [DatabaseSchema.FieldConstraint]) -> Self {
        schema.createFields.append(.definition(name: name, dataType: dataType, constraints: constraints))
        return self
    }

    /// Adds an manually defined custom  field
    public func defineField(custom: Any) -> Self {
        schema.createFields.append(.custom(custom))
        return self
    }

    /// Adds an identifier field with the given keypath. Specify if it should be auto or not
    public func id<IdType: DataTypeInferrable>(_ keyPath: KeyPath<M, ID<IdType>>, auto: Bool) -> Self {
        defineField(name: getFieldName(keyPath), dataType: inferDataType(IdType.self), constraints: [.identifier(auto: auto)])
    }

    /// Adds a general field with the given keypath
    public func field<FieldType: DataTypeInferrable>(_ keyPath: KeyPath<M, Field<FieldType>>) -> Self {
        defineField(name: getFieldName(keyPath), dataType: inferDataType(FieldType.self), constraints: isOptional(keyPath) ? [] : [.required])
    }

    /// Adds a parent field with the given keypath
    public func parent<M2: Model>(_ keyPath: KeyPath<M, Parent<M2>>) -> Self where M2.IDValue: DataTypeInferrable {
        defineField(name: getFieldName(keyPath), dataType: inferDataType(M2.IDValue.self), constraints: [.required])
    }

    /// Adds an optional parent field with the given keypath
    public func parent<M2: Model>(_ keyPath: KeyPath<M, OptionalParent<M2>>) -> Self where M2.IDValue: DataTypeInferrable {
        defineField(name: getFieldName(keyPath), dataType: inferDataType(M2.IDValue.self), constraints: [])
    }

    /// Adds a parent field with the given keypath, with a foreign key constraint
    public func parent<M2: Model>(
        _ keyPath: KeyPath<M, Parent<M2>>,
        references foreignIdKeyPath: KeyPath<M2, ID<M2.IDValue>>,
        onDelete: DatabaseSchema.Constraint.ForeignKeyAction = .noAction,
        onUpdate: DatabaseSchema.Constraint.ForeignKeyAction = .noAction) -> Self where M2.IDValue: DataTypeInferrable {
        let constraints: [DatabaseSchema.FieldConstraint] =
            [.required, .foreignKey(field: .string(schema: M2.schema, field: getString(foreignIdKeyPath)), onDelete: onDelete, onUpdate: onUpdate)]
        return defineField(name: getFieldName(keyPath), dataType: inferDataType(M2.IDValue.self), constraints: constraints)
    }

    /// Adds an optional parent field with the given keypath, with a foreign key constraint
    public func parent<M2: Model>(
        _ keyPath: KeyPath<M, OptionalParent<M2>>,
        references foreignIdKeyPath: KeyPath<M2, ID<M2.IDValue>>,
        onDelete: DatabaseSchema.Constraint.ForeignKeyAction = .noAction,
        onUpdate: DatabaseSchema.Constraint.ForeignKeyAction = .noAction) -> Self where M2.IDValue: DataTypeInferrable {
        let constraints: [DatabaseSchema.FieldConstraint] =
            [.foreignKey(field: .string(schema: M2.schema, field: getString(foreignIdKeyPath)), onDelete: onDelete, onUpdate: onUpdate)]
        return defineField(name: getFieldName(keyPath), dataType: inferDataType(M2.IDValue.self), constraints: constraints)
    }

    /// Adds a timestamp field with the given keypath
    public func timestamp(_ keyPath: KeyPath<M, Timestamp>) -> Self {
        return defineField(name: getFieldName(keyPath), dataType: .datetime, constraints: [])
    }

    /// Adds uniqueness constraints to the given keypaths. If several keypaths are supplied in the same called to `unique` they need to have the same field type
    public func unique<F: FieldRepresentable>(on keyPaths: KeyPath<M, F>...) -> Self {
        schema.constraints.append(.unique(fields: keyPaths.map(getFieldName)))
        return self
    }

    /// Adds a schema level foreign key constraint with the given parent id and foreign id keypaths, and optionally `onDelete` and `onUpdate` actions
    public func foreignKey<M2: Model>(
        _ keyPath: KeyPath<M, Parent<M2>>,
        references foreignIdKeyPath: KeyPath<M2, ID<M2.IDValue>>,
        onDelete: DatabaseSchema.Constraint.ForeignKeyAction = .noAction,
        onUpdate: DatabaseSchema.Constraint.ForeignKeyAction = .noAction
    ) -> Self {
        schema.constraints.append(.foreignKey(
            fields: [getFieldName(keyPath)],
            foreignSchema: M2.schema,
            foreignFields: [getFieldName(foreignIdKeyPath)],
            onDelete: onDelete,
            onUpdate: onUpdate
        ))
        return self
    }

    /// Adds a schema level foreign key constraint with the given optional parent ìd and foreign id keypaths, and optionally `onDelete` and `onUpdate` actions
    public func foreignKey<M2: Model>(
        _ keyPath: KeyPath<M, OptionalParent<M2>>,
        references foreignField: KeyPath<M2, ID<M2.IDValue>>,
        onDelete: DatabaseSchema.Constraint.ForeignKeyAction = .noAction,
        onUpdate: DatabaseSchema.Constraint.ForeignKeyAction = .noAction
    ) -> Self {
        schema.constraints.append(.foreignKey(
            fields: [getFieldName(keyPath)],
            foreignSchema: M2.schema,
            foreignFields: [getFieldName(foreignField)],
            onDelete: onDelete,
            onUpdate: onUpdate
        ))
        return self
    }

    /// Delete the given field
    public func deleteField<F: FieldRepresentable>(_ fieldKeyPath: KeyPath<M, F>) -> Self {
        schema.deleteFields.append(getFieldName(fieldKeyPath))
        return self
    }

    /// Delete the schema
    public func delete() -> EventLoopFuture<Void> {
        schema.action = .delete
        return database.execute(schema: schema)
    }

    /// Update the schema
    public func update() -> EventLoopFuture<Void> {
        schema.action = .update
        return database.execute(schema: schema)
    }

    /// Create the schema
    public func create() -> EventLoopFuture<Void> {
        schema.action = .create
        return database.execute(schema: schema)
    }
}

// Helper methods

/// Get the name of the given keypath as a `FieldName`
private func getFieldName<M: Model, F: FieldRepresentable>(_ keyPath: KeyPath<M, F>) -> DatabaseSchema.FieldName {
    .string(getString(keyPath))
}

/// Get the name of the given keypath as a `String`
private func getString<M: Model, F: FieldRepresentable>(_ keyPath: KeyPath<M, F>) -> String {
    M()[keyPath: keyPath].field.key
}

private protocol OptionalProtocol { }

extension Optional: OptionalProtocol { }

private func isOptional<M: Model, F: FieldRepresentable>(_ field: KeyPath<M, F>) -> Bool { F.Value.self is OptionalProtocol.Type }

public protocol DataTypeInferrable { }
extension Int: DataTypeInferrable { }
extension Int8: DataTypeInferrable { }
extension Int16: DataTypeInferrable { }
extension Int32: DataTypeInferrable { }
extension Int64: DataTypeInferrable { }
extension UInt8: DataTypeInferrable { }
extension UInt16: DataTypeInferrable { }
extension UInt32: DataTypeInferrable { }
extension UInt64: DataTypeInferrable { }
extension Bool: DataTypeInferrable { }
extension String: DataTypeInferrable { }
extension Date: DataTypeInferrable { }
extension Float: DataTypeInferrable { }
extension Double: DataTypeInferrable { }
extension Data: DataTypeInferrable { }
extension UUID: DataTypeInferrable { }
extension Optional: DataTypeInferrable where Wrapped: DataTypeInferrable { }
extension Array: DataTypeInferrable where Element: DataTypeInferrable { }

private func inferDataType(_ fieldType: DataTypeInferrable.Type) -> DatabaseSchema.DataType {
    switch fieldType {
    case is Int.Type, is Int8?.Type: return .int
    case is Int8.Type, is Int8?.Type: return .int8
    case is Int16.Type, is Int16?.Type: return .int16
    case is Int32.Type, is Int32?.Type: return .int32
    case is Int64.Type, is Int64?.Type: return .int64
    case is UInt8.Type, is UInt8?.Type: return .uint8
    case is UInt16.Type, is UInt16?.Type: return .uint16
    case is UInt32.Type, is UInt32?.Type: return .uint32
    case is UInt64.Type, is UInt64?.Type: return .uint64
    case is Bool.Type, is Bool?.Type: return .bool
    case is String.Type, is String?.Type: return .string
    case is Date.Type, is Date?.Type: return .date
    case is Float.Type, is Float?.Type: return .float
    case is Double.Type, is Double?.Type: return .double
    case is Data.Type, is Data?.Type: return .data
    case is UUID.Type, is UUID?.Type: return .uuid
    case is [Int].Type, is [Int]?.Type: return .array(of: .int)
    case is [Int8].Type, is [Int8]?.Type: return .array(of: .int8)
    case is [Int16].Type, is [Int16]?.Type: return .array(of: .int16)
    case is [Int32].Type, is [Int32]?.Type: return .array(of: .int32)
    case is [Int64].Type, is [Int64]?.Type: return .array(of: .int64)
    case is [UInt8].Type, is [UInt8]?.Type: return .array(of: .uint8)
    case is [UInt16].Type, is [UInt16]?.Type: return .array(of: .uint16)
    case is [UInt32].Type, is [UInt32]?.Type: return .array(of: .uint32)
    case is [UInt64].Type, is [UInt64]?.Type: return .array(of: .uint64)
    case is [Bool].Type, is [Bool]?.Type: return .array(of: .bool)
    case is [String].Type, is [String]?.Type: return .array(of: .string)
    case is [Date].Type, is [Date]?.Type: return .array(of: .date)
    case is [Float].Type, is [Float]?.Type: return .array(of: .float)
    case is [Double].Type, is [Double]?.Type: return .array(of: .double)
    case is [Data].Type, is [Data]?.Type: return .array(of: .data)
    case is [UUID].Type, is [UUID]?.Type: return .array(of: .uuid)
    default: fatalError("Can't infer datatype for \(fieldType)")
    }
}
