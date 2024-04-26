import FluentKit
import FluentSQL
import NIOEmbedded
import SQLKit
import XCTFluent
import NIOConcurrencyHelpers

struct FakedDatabaseRow: DatabaseOutput, SQLRow {
    let data: [String: (any Sendable)?]
    let schema: String?
    
    private func column(for key: FieldKey) -> String { "\(self.schema.map { "\($0)_" } ?? "")\(key.description)" }
    func schema(_ schema: String) -> any DatabaseOutput { FakedDatabaseRow(self.data, schema: schema) }
    func contains(_ key: FieldKey) -> Bool { self.contains(column: self.column(for: key)) }
    func decodeNil(_ key: FieldKey) throws -> Bool { try self.decodeNil(column: self.column(for: key)) }
    func decode<T: Decodable>(_ key: FieldKey, as: T.Type) throws -> T { try self.decode(column: self.column(for: key), as: T.self) }
    
    var allColumns: [String] { .init(self.data.keys) }
    func contains(column: String) -> Bool { self.data.keys.contains(column) }
    func decodeNil(column: String) throws -> Bool { self.data[column].map { $0 == nil } ?? true }
    func decode<D: Decodable>(column c: String, as: D.Type) throws -> D {
        guard case .some(.some(let v)) = self.data[c] else { throw DecodingError.keyNotFound(SomeCodingKey(stringValue: c), .init(codingPath: [], debugDescription: "")) }
        guard let value = v as? D else { throw DecodingError.typeMismatch(D.self, .init(codingPath: [], debugDescription: "")) }
        return value
    }
    
    var description: String { "" }
    
    init(_ data: [String: (any Sendable)?], schema: String? = nil) {
        self.data = data
        self.schema = schema
    }
}

final class DummyDatabaseForTestSQLSerializer: Database, SQLDatabase {
    var inTransaction: Bool { false }

    struct Configuration: DatabaseConfiguration {
        func makeDriver(for databases: Databases) -> any DatabaseDriver { fatalError() }
        var middleware: [any AnyModelMiddleware] = []
    }

    var dialect: any SQLDialect { DummyDatabaseDialect() }

    let context: DatabaseContext

    let _sqlSerializers = NIOLockedValueBox<[SQLSerializer]>([])
    var sqlSerializers: [SQLSerializer] {
        get { self._sqlSerializers.withLockedValue { $0 } }
        set { self._sqlSerializers.withLockedValue { $0 = newValue } }
    }
    
    let _fakedRows = NIOLockedValueBox<[[FakedDatabaseRow]]>([])
    var fakedRows: [[FakedDatabaseRow]] {
        get { self._fakedRows.withLockedValue { $0 } }
        set { self._fakedRows.withLockedValue { $0 = newValue } }
    }

    init() {
        self.context = .init(
            configuration: Configuration(),
            logger: .init(label: "test"),
            eventLoop: EmbeddedEventLoop()
        )
    }

    func reset() {
        self.sqlSerializers = []
    }
    
    func execute(
        query: DatabaseQuery,
        onOutput: @escaping @Sendable (any DatabaseOutput) -> ()
    ) -> EventLoopFuture<Void> {
        let sqlExpression = SQLQueryConverter(delegate: DummyDatabaseConverterDelegate()).convert(query)
        
        return self.execute(sql: sqlExpression, { row in onOutput(row as! any DatabaseOutput) })
    }

    func execute(sql query: any SQLExpression, _ onRow: @escaping @Sendable (any SQLRow) -> ()) -> EventLoopFuture<Void> {
        var sqlSerializer = SQLSerializer(database: self)
        query.serialize(to: &sqlSerializer)
        self._sqlSerializers.withLockedValue { $0.append(sqlSerializer) }
        if !self.fakedRows.isEmpty {
            for row in self._fakedRows.withLockedValue({ $0.removeFirst() }) {
                onRow(row)
            }
        }
        return self.eventLoop.makeSucceededVoidFuture()
    }

    func transaction<T>(_ closure: @escaping @Sendable (any Database) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        closure(self)
    }
    
    func execute(schema: DatabaseSchema) -> EventLoopFuture<Void> {
        let sqlExpression = SQLSchemaConverter(delegate: DummyDatabaseConverterDelegate()).convert(schema)
        
        return self.execute(sql: sqlExpression, { _ in })
    }

    func execute(enum: DatabaseEnum) -> EventLoopFuture<Void> {
        // do nothing
        self.eventLoop.makeSucceededVoidFuture()
    }
    
    func withConnection<T>(
        _ closure: @escaping @Sendable (any Database) -> EventLoopFuture<T>
    ) -> EventLoopFuture<T> {
        closure(self)
    }

    func shutdown() {
        //
    }
}

// Copy from PostgresDialect
struct DummyDatabaseDialect: SQLDialect {
    var supportsAutoIncrement: Bool {
        true
    }

    var enumSyntax: SQLEnumSyntax {
        .unsupported
    }

    var name: String {
        "dummy db"
    }

    var identifierQuote: any SQLExpression {
        SQLRaw("\"")
    }

    var literalStringQuote: any SQLExpression {
        SQLRaw("'")
    }

    func bindPlaceholder(at position: Int) -> any SQLExpression {
        SQLRaw("$" + position.description)
    }

    func literalBoolean(_ value: Bool) -> any SQLExpression {
        SQLRaw(value ? "true" : "false")
    }

    var autoIncrementClause: any SQLExpression {
        SQLRaw("GENERATED BY DEFAULT AS IDENTITY")
    }
    
    var sharedSelectLockExpression: (any SQLExpression)? {
        SQLRaw("FOR SHARE")
    }

    var exclusiveSelectLockExpression: (any SQLExpression)? {
        SQLRaw("FOR UPDATE")
    }
}

// Copy from PostgresConverterDelegate
struct DummyDatabaseConverterDelegate: SQLConverterDelegate {
    func customDataType(_ dataType: DatabaseSchema.DataType) -> (any SQLExpression)? {
        switch dataType {
        case .uuid:
            return SQLRaw("UUID")
        case .bool:
            return SQLRaw("BOOL")
        case .data:
            return SQLRaw("BYTEA")
        case .datetime:
            return SQLRaw("TIMESTAMPTZ")
        default:
            return nil
        }
    }

    func nestedFieldExpression(_ column: String, _ path: [String]) -> any SQLExpression {
        SQLRaw("\(column)->>'\(path[0])'")
    }
}
