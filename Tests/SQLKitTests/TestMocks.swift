import AsyncAlgorithms
import Logging
import OrderedCollections
@testable import SQLKit

extension SQLQueryBuilder {
    /// Serialize this builder's query and return the textual SQL, discarding any bindings.
    func simpleSerialize() -> String {
        self.advancedSerialize().sql
    }
    
    /// Serialize this builder's query and return the SQL and bindings (which conveniently can be done by just
    /// returning the serializer).
    func advancedSerialize() -> SQLSerializer {
        var serializer = SQLSerializer(database: self.database)

        self.query.serialize(to: &serializer)
        return serializer
    }
}

/// A very minimal mock `SQLDatabase` which implements `execut(sql:_:)` by saving the serialized SQL and bindings to
/// its internal arrays of accumulated "results". Most things about its dialect are mutable.
final class TestDatabase: SQLDatabase {
    let logger: Logger = { var l = Logger(label: "codes.vapor.sql.test"); l.logLevel = .debug; return l }()
    var queryLogLevel: Logger.Level? = .debug
    var results: [String] = []
    var bindResults: [[any Encodable & Sendable]] = []
    var outputs: [TestRow] = []
    var dialect: GenericDialect = .init()

    func execute(sql query: some SQLExpression) async throws -> AsyncSyncSequence<[TestRow]> {
        let (sql, binds) = self.serialize(query)

        self.results.append(sql)
        self.bindResults.append(binds)
        let outputs = self.outputs
        self.outputs = []
        return outputs.async
    }

    func withSession<R>(_ closure: @escaping @Sendable (any SQLDatabase) async throws -> R) async throws -> R {
        try await closure(self)
    }
}

/// A minimal but surprisingly complete mock `SQLRow` which correctly implements all required methods.
struct TestRow: SQLRow {
    var data: OrderedDictionary<String, (any Codable & Sendable)?>

    var allColumns: [String] {
        .init(self.data.keys)
    }
    
    func contains(column: String) -> Bool {
        self.data.keys.contains(column)
    }
    
    func decodeNil(column: String) throws -> Bool {
        self.data[column].map { $0.map { _ in false } ?? true } ?? true
    }
    
    func decode<D: Decodable & Sendable>(column: String, as: D.Type) throws -> D {
        let key = BasicCodingKey.key(column)

        /// Key not in dictionary? Key not found (no such column).
        guard case let .some(maybeValue) = self.data[column] else {
            throw DecodingError.keyNotFound(key, .init(
                codingPath: [], debugDescription: "No value associated with key '\(column)'."
            ))
        }
        /// Key exists but value is nil? Value not found (should have used decodeNil() instead).
        guard case let .some(value) = maybeValue else {
            throw DecodingError.valueNotFound(D.self, .init(
                codingPath: [key],
                debugDescription: "No value of type \(D.self) associated with key '\(column)'."
            ))
        }
        /// Value given but is wrong type? Type mismatch.
        guard let cast = value as? D else {
            throw DecodingError.typeMismatch(D.self, .init(
                codingPath: [key],
                debugDescription: "Expected to decode \(D.self) but found \(type(of: value)) instead."
            ))
        }
        return cast
    }
}

/// The mutable mock `SQLDialect` used by `TestDatabase`.
struct GenericDialect: SQLDialect {
    var name: String { "generic" }

    func bindPlaceholder(at position: Int) -> any SQLExpression { SQLUnsafeRaw("&\(position)") }
    var supportsExplicitDefaultValues = true
    var supportsAutoIncrement = true
    var supportsIfExists = true
    var supportsReturning = true
    var objectIdentifierQuote = "``"
    var typeIdentifierQuote: String? = "´´"
    var literalStringQuote = "'"
    var enumSyntax = SQLEnumSyntax.typeName
    var autoIncrementClause: (any SQLExpression)? = SQLUnsafeRaw("AWWTOEINCREMENT")
    var supportsDropBehavior = true
    var triggerSyntax = SQLTriggerSyntax(create: [], drop: [])
    var alterTableSyntax = SQLAlterTableSyntax(alterColumnDefinitionClause: SQLUnsafeRaw("MOODIFY"), alterColumnDefinitionTypeKeyword: nil)
    var upsertSyntax = SQLUpsertSyntax.standard
    var unionFeatures: Set<SQLUnionFeatures> = []
    var sharedSelectLockExpression: (any SQLExpression)? = SQLUnsafeRaw("FOUR SHAARE")
    var exclusiveSelectLockExpression: (any SQLExpression)? = SQLUnsafeRaw("FOUR UPDATE")
    func nestedSubpathExpression(in column: any SQLExpression, for path: [String]) -> (any SQLExpression)? {
        precondition(!path.isEmpty)
        let descender = SQLList([column] + path.dropLast().map(SQLLiteral.string(_:)), separator: "-»")
        return SQLGroupExpression(SQLList([descender, SQLLiteral.string(path.last!)], separator: "-»»"))
    }
    func customDataType(for dataType: SQLDataType) -> String? {
        dataType == .custom("STANDARD") ? "CUSTOM" : nil
    }
}

extension SQLDataType: Swift.Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.bigint, .bigint), (.blob, .blob), (.int, .int), (.real, .real),
             (.smallint, .smallint), (.text, .text), (.timestamp, .timestamp):
            true
        case (.enumeration(let lname, let lcases), .enumeration(let rname, let rcases)):
            lname == rname && lcases == rcases
        case (.custom(let lhs), .custom(let rhs)):
            lhs == rhs
        default:
            false
        }
    }
}
