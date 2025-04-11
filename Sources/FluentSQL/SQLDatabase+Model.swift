import SQLKit
import FluentKit

extension SQLQueryFetcher {
    public func first<Model: FluentKit.Model>(decodingFluent: Model.Type) async throws -> Model? {
        try await self.first().map { try $0.decode(fluentModel: Model.self) }
    }

    public func all<Model: FluentKit.Model>(decodingFluent: Model.Type) async throws -> [Model] {
        try await self.all().map { try $0.decode(fluentModel: Model.self) }
    }
}

extension SQLRow {
    public func decode<Model: FluentKit.Model>(fluentModel: Model.Type) throws -> Model {
        let model = Model()
        try model.output(from: SQLDatabaseOutput(sql: self))
        return model
    }
}

struct SQLDatabaseOutput: DatabaseOutput {
    let sql: any SQLRow

    var description: String {
        "\(self.sql)"
    }

    func schema(_ schema: String) -> any DatabaseOutput {
        self
    }

    func contains(_ key: FieldKey) -> Bool {
        self.sql.contains(column: key.description)
    }

    func decodeNil(_ key: FieldKey) throws -> Bool {
        try self.sql.decodeNil(column: key.description)
    }

    func decode<T>(_ key: FieldKey, as type: T.Type) throws -> T 
        where T: Decodable
    {
        try self.sql.decode(column: key.description, as: T.self)
    }
}

extension DatabaseQuery.Value {
    /// This is pretty much exactly the same as what `SQLQueryConverter.value(_:)` does. The only obvious difference
    /// is the `.dictionary()` case, which is never actually hit at runtime (it's not valid and ought to error out,
    /// really, but why add more fatal errors than we have to?).
    fileprivate var asSQLExpression: any SQLExpression {
        switch self {
        case .bind(let value):   SQLBind(value)
        case .null:              SQLLiteral.null
        case .array(let values): SQLGroupExpression(SQLList(values.map(\.asSQLExpression), separator: ","))
        case .default:           SQLLiteral.default
        case .enumCase(let str): SQLLiteral.string(str)
        case .custom(let any as any SQLExpression):
                                 any
        case .custom(let any as any CustomStringConvertible):
                                 SQLUnsafeRaw(any.description)
        case .dictionary(_):     fatalError("Dictionary database values are unimplemented for SQL")
        case .custom(_):         fatalError("Unsupported custom database value")
        }
    }
}

extension Model {
    fileprivate func encodeForSQL(withDefaultedValues: Bool) -> [(String, any SQLExpression)] {
        self.collectInput(withDefaultedValues: withDefaultedValues).map { ($0.description, $1.asSQLExpression) }.sorted(by: { $0.0 < $1.0 })
    }
}

extension SQLInsertBuilder {
    @discardableResult
    public func fluentModel<Model: FluentKit.Model>(_ model: Model) throws -> Self {
        try self.fluentModels([model])
    }

    @discardableResult
    public func fluentModels<Model: FluentKit.Model>(_ models: [Model]) throws -> Self {
        var validColumns: [String] = []
        
        for model in models {
            let pairs = model.encodeForSQL(withDefaultedValues: true)
            
            if validColumns.isEmpty {
                validColumns = pairs.map(\.0)
                self.columns(validColumns)
            } else {
                guard validColumns == pairs.map(\.0) else {
                    throw EncodingError.invalidValue(model, .init(codingPath: [], debugDescription: """
                        One or more input Fluent models does not encode to the same set of columns.
                        """
                    ))
                }
            }
            self.values(pairs.map(\.1))
        }
        return self
    }
}

extension SQLColumnUpdateBuilder {
    @discardableResult
    public func set<Model: FluentKit.Model>(
        fluentModel: Model
    ) throws -> Self {
        fluentModel.encodeForSQL(withDefaultedValues: false).reduce(self) { $0.set(SQLColumn($1.0), to: $1.1) }
    }
}

extension SQLConflictUpdateBuilder {
    @discardableResult
    public func set<Model: FluentKit.Model>(
        excludedContentOfFluentModel fluentModel: Model
    ) throws -> Self {
        fluentModel.encodeForSQL(withDefaultedValues: false).reduce(self) { $0.set(excludedValueOf: $1.0) }
    }
}
