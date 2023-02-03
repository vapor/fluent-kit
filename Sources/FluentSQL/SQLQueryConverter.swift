import FluentKit

public struct SQLQueryConverter {
    let delegate: SQLConverterDelegate
    public init(delegate: SQLConverterDelegate) {
        self.delegate = delegate
    }
    
    public func convert(_ fluent: DatabaseQuery) -> SQLExpression {
        let sql: SQLExpression
        switch fluent.action {
        case .read, .aggregate: sql = self.select(fluent)
        case .create: sql = self.insert(fluent)
        case .update: sql = self.update(fluent)
        case .delete: sql = self.delete(fluent)
        case .custom(let any):
            return custom(any)
        }
        return sql
    }
    
    // MARK: Private
    
    private func delete(_ query: DatabaseQuery) -> SQLExpression {
        var delete = SQLDelete(table: SQLQualifiedTable(query.schema, space: query.space))
        delete.predicate = self.filters(query.filters)
        return delete
    }
    
    private func update(_ query: DatabaseQuery) -> SQLExpression {
        var update = SQLUpdate(table: SQLQualifiedTable(query.schema, space: query.space))
        guard case .dictionary(let values) = query.input.first! else {
            fatalError("Missing query input generating update query")
        }
        values.forEach { (key, value) in
            update.values.append(SQLColumnAssignment(
                setting: SQLColumn(self.key(key)),
                to: self.value(value)
            ))
        }
        update.predicate = self.filters(query.filters)
        return update
    }
    
    private func select(_ query: DatabaseQuery) -> SQLExpression {
        var select = SQLSelect()
        select.tables.append(SQLQualifiedTable(query.schema, space: query.space))
        switch query.action {
        case .read:
            select.isDistinct = query.isUnique
            select.columns = query.fields.map { field in self.field(field, aliased: true) }
        case .aggregate(let aggregate):
            select.columns = [self.aggregate(aggregate, isUnique: query.isUnique)]
        default: break
        }
        select.predicate = self.filters(query.filters)
        select.joins = query.joins.map(self.join)
        select.orderBy = query.sorts.map(self.sort)
        if let limit = query.limits.first {
            switch limit {
            case .count(let count):
                select.limit = count
            case .custom(let any):
                fatalError("Unsupported limit \(any)")
            }
        }
        if let offset = query.offsets.first {
            switch offset {
            case .count(let count):
                select.offset = count
            case .custom(let any):
                fatalError("Unsupported offset \(any)")
            }
        }
        return select
    }
    
    private func insert(_ query: DatabaseQuery) -> SQLExpression {
        var insert = SQLInsert(table: SQLQualifiedTable(query.schema, space: query.space))
        guard case .dictionary(let first) = query.input.first! else {
            fatalError("Unexpected query input: \(query.input)")
        }
        let keys: [FieldKey] = Array(first.keys)
        insert.columns = keys.map { key in
            SQLColumn(self.key(key))
        }
        insert.values = query.input.map { value in
            guard case .dictionary(let nested) = value else {
                fatalError("Unexpected query input: \(value)")
            }
            return keys.map { key in
                guard let value = nested[key] else {
                    fatalError("Non-uniform query input: \(query.input)")
                }
                return self.value(value)
            }
        }
        return insert
    }
    
    private func filters(_ filters: [DatabaseQuery.Filter]) -> SQLExpression? {
        guard !filters.isEmpty else {
            return nil
        }

        return SQLKit.SQLList(
            filters.map(self.filter),
            separator: " \(SQLBinaryOperator.and) " as SQLQueryString
        )
    }

    private func sort(_ sort: DatabaseQuery.Sort) -> SQLExpression {
        switch sort {
        case .sort(let field, let direction):
            return SQLOrderBy(expression: self.field(field), direction: self.direction(direction))
        case .custom(let any):
            return custom(any)
        }
    }

    private func direction(_ direction: DatabaseQuery.Sort.Direction) -> SQLExpression {
        switch direction {
        case .ascending:
            return SQLRaw("ASC")
        case .descending:
            return SQLRaw("DESC")
        case .custom(let any):
            return custom(any)
        }
    }
    
    private func join(_ join: DatabaseQuery.Join) -> SQLExpression {
        switch join {
        case .custom(let any):
            return custom(any)

        case .join(let schema, let alias, let method, let foreign, let local):
            return self.joinCondition(schema: schema, alias: alias, method: method, filters: [.field(foreign, .equal, local)])

        case .extendedJoin(let schema, let space, let alias, let method, let foreign, let local):
            return self.joinCondition(space: space, schema: schema, alias: alias, method: method, filters: [.field(foreign, .equal, local)])

        case .advancedJoin(let schema, let space, let alias, let method, let filters):
            return self.joinCondition(space: space, schema: schema, alias: alias, method: method, filters: filters)
        }
    }
    
    private func joinCondition(
        space: String? = nil, schema: String,
        alias: String?,
        method: DatabaseQuery.Join.Method,
        filters: [DatabaseQuery.Filter]
    ) -> SQLExpression {
        let table: SQLExpression = alias.map { SQLAlias(SQLQualifiedTable(schema, space: space), as: SQLIdentifier($0)) } ??
                                   SQLQualifiedTable(schema, space: space)
        
        return SQLJoin(method: self.joinMethod(method), table: table, expression: self.filters(filters) ?? SQLLiteral.boolean(true))
    }
    
    private func joinMethod(_ method: DatabaseQuery.Join.Method) -> SQLExpression {
        switch method {
        case .inner: return SQLJoinMethod.inner
        case .left: return SQLJoinMethod.left
        case .custom(let any):
            return custom(any)
        }
    }
    
    private func field(_ field: DatabaseQuery.Field, aliased: Bool = false) -> SQLExpression {
        switch field {
        case .custom(let any):
            return custom(any)
        case .path(let path, let schema):
            return self.fieldPath(path, schema: schema, aliased: aliased)
        case .extendedPath(let path, let schema, let space):
            return self.fieldPath(path, space: space, schema: schema, aliased: aliased)
        }
    }
    
    private func fieldPath(_ path: [FieldKey], space: String? = nil, schema: String, aliased: Bool) -> SQLExpression {
        let field: SQLExpression
        
        switch path.count {
        case 1:
            field = SQLColumn(SQLIdentifier(self.key(path[0])), table: SQLQualifiedTable(schema, space: space))
        case 2...:
            field = self.delegate.nestedFieldExpression(self.key(path[0]), path[1...].map(self.key))
        default:
            fatalError("Field path must not be empty.")
        }
        
        if aliased {
            return SQLAlias(field, as: [space, schema, self.key(path[0])].compactMap({ $0 }).joined(separator: "_"))
        } else {
            return field
        }
    }
    
    private func aggregate(_ aggregate: DatabaseQuery.Aggregate, isUnique: Bool) -> SQLExpression {
        switch aggregate {
        case .custom(let any):
            return any as! SQLExpression
        case .field(let field, let method):
            let name: String
            switch method {
            case .average: name = "AVG"
            case .count: name = "COUNT"
            case .sum: name = "SUM"
            case .maximum: name = "MAX"
            case .minimum: name = "MIN"
            case .custom(let custom): name = custom as! String
            }
            return SQLAlias(
                SQLFunction(
                    name,
                    args: isUnique
                        ? [SQLDistinct(self.field(field))]
                        : [self.field(field)]
                ),
                as: SQLIdentifier(FieldKey.aggregate.description)
            )
        }
    }
    
    private func filter(_ filter: DatabaseQuery.Filter) -> SQLExpression {
        switch filter {
        case .value(let field, let method, let value):
            switch (method, value) {
            case (.equality(let inverse), _) where value.isNull:
                // special case when using != and = with NULL
                // must convert to IS NOT NULL and IS NULL respectively
                return SQLBinaryExpression(
                    left: self.field(field),
                    op: inverse ? SQLBinaryOperator.isNot : SQLBinaryOperator.is,
                    right: SQLLiteral.null
                )
            case (.contains(let inverse, let method), .bind(let bind)):
                let maybeString: String?
                if let string = bind as? String {
                    maybeString = string
                } else if let convertible = bind as? CustomStringConvertible {
                    maybeString = convertible.description
                } else {
                    maybeString = nil
                }
                guard let string = maybeString else {
                    fatalError("Only string binds are supported with contains")
                }
                let right: SQLExpression
                switch method {
                case .anywhere:
                    right = SQLBind("%" + string.description + "%")
                case .prefix:
                    right = SQLBind(string.description + "%")
                case .suffix:
                    right = SQLBind("%" + string.description)
                }
                return SQLBinaryExpression(
                    left: self.field(field),
                    op: inverse ? SQLBinaryOperator.notLike : SQLBinaryOperator.like,
                    right: right
                )
            case (.subset(let inverse), .array(let array)) where array.isEmpty:
                return SQLBinaryExpression(
                    left: SQLLiteral.numeric("1"),
                    op: inverse ? SQLBinaryOperator.notEqual : SQLBinaryOperator.equal,
                    right: SQLLiteral.numeric("0")
                )
            default:
                return SQLBinaryExpression(
                    left: self.field(field),
                    op: self.method(method),
                    right: self.value(value)
                )
            }
        case .field(let lhsField, let method, let rhsField):
            return SQLBinaryExpression(
                left: self.field(lhsField),
                op: self.method(method),
                right: self.field(rhsField)
            )
        case .custom(let any):
            return custom(any)
        case .group(let filters, let relation):
            // <item> OR <item> OR <item>
            let expression = SQLKit.SQLList(
                filters.map(self.filter),
                separator: " \(self.relation(relation)) " as SQLQueryString
            )
            // ( <expr> )
            return SQLGroupExpression(expression)
        }
    }
    
    private func relation(_ relation: DatabaseQuery.Filter.Relation) -> SQLExpression {
        switch relation {
        case .and:
            return SQLBinaryOperator.and
        case .or:
            return SQLBinaryOperator.or
        case .custom(let any):
            return custom(any)
        }
    }

    
    private func value(_ value: DatabaseQuery.Value) -> SQLExpression {
        switch value {
        case .bind(let encodable):
            if let optional = encodable as? AnyOptionalType, optional.wrappedValue == nil {
                return SQLLiteral.null
            } else {
                return SQLBind(encodable)
            }
        case .null:
            return SQLLiteral.null
        case .array(let values):
            return SQLGroupExpression(SQLKit.SQLList(values.map(self.value), separator: SQLRaw(",")))
        case .dictionary(let dictionary):
            return SQLBind(EncodableDatabaseInput(input: dictionary))
        case .default:
            return SQLLiteral.default
        case .enumCase(let string):
            return SQLLiteral.string(string)
        case .custom(let any):
            return custom(any)
        }
    }
    
    private func method(_ method: DatabaseQuery.Filter.Method) -> SQLExpression {
        switch method {
        case .equality(let inverse):
            if inverse {
                return SQLBinaryOperator.notEqual
            } else {
                return SQLBinaryOperator.equal
            }
        case .subset(let inverse):
            if inverse {
                return SQLBinaryOperator.notIn
            } else {
                return SQLBinaryOperator.in
            }
        case .order(let inverse, let equality):
            switch (inverse, equality) {
            case (false, false):
                return SQLBinaryOperator.greaterThan
            case (false, true):
                return SQLBinaryOperator.greaterThanOrEqual
            case (true, false):
                return SQLBinaryOperator.lessThan
            case (true, true):
                return SQLBinaryOperator.lessThanOrEqual
            }
        case .contains:
            fatalError("Contains filter method not supported at this scope.")
        case .custom(let any):
            return custom(any)
        }
    }

    private func key(_ key: FieldKey) -> String {
        switch key {
        case .id:
            return "id"
        case .string(let name):
            return name
        case .aggregate:
            return key.description
        case .prefix(let prefix, let key):
            return self.key(prefix) + self.key(key)
        }
    }
}

private struct EncodableDatabaseInput: Encodable {
    let input: [FieldKey: DatabaseQuery.Value]

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: SomeCodingKey.self)
        for (key, value) in self.input {
            try container.encode(EncodableDatabaseValue(value: value), forKey: SomeCodingKey(stringValue: key.description))
        }
    }
}

private struct EncodableDatabaseValue: Encodable {
    let value: DatabaseQuery.Value
    func encode(to encoder: Encoder) throws {
        switch self.value {
        case .bind(let encodable):
            try encodable.encode(to: encoder)
        case .null:
            var container = encoder.singleValueContainer()
            try container.encodeNil()
        case .dictionary(let dictionary):
            try EncodableDatabaseInput(input: dictionary).encode(to: encoder)
        default:
            fatalError("Unsupported codable database value: \(self.value)")
        }
    }
}

extension DatabaseQuery.Value {
    var isNull: Bool {
        switch self {
        case .null:
            return true
        case .bind(let bind):
            guard let optional = bind as? AnyOptionalType, case .none = optional.wrappedValue else { return false }
            return true
        default:
            return false
        }
    }
}
