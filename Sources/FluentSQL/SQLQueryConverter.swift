public struct SQLQueryConverter {
    let delegate: SQLConverterDelegate
    public init(delegate: SQLConverterDelegate) {
        self.delegate = delegate
    }
    
    public func convert(_ fluent: DatabaseQuery) -> SQLExpression {
        let sql: SQLExpression
        switch fluent.action {
        case .read: sql = self.select(fluent)
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
        var delete = SQLDelete(table: SQLIdentifier(query.schema))
        delete.predicate = self.filters(query.filters)
        return delete
    }
    
    private func update(_ query: DatabaseQuery) -> SQLExpression {
        var update = SQLUpdate(table: SQLIdentifier(query.schema))
        for (i, field) in query.fields.enumerated() {
            update.values.append(SQLBinaryExpression(
                left: self.field(field),
                op: SQLBinaryOperator.equal,
                right: self.value(query.input[0][i])
            ))
        }
        update.predicate = self.filters(query.filters)
        return update
    }
    
    private func select(_ query: DatabaseQuery) -> SQLExpression {
        var select = SQLSelect()
        select.tables.append(SQLIdentifier(query.schema))
        select.columns = query.fields.map(self.field)
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
        var insert = SQLInsert(table: SQLIdentifier(query.schema))
        insert.columns = query.fields.map(self.field)
        insert.values = query.input.map { row in
            return row.map(self.value)
        }
        return insert
    }
    
    private func filters(_ filters: [DatabaseQuery.Filter]) -> SQLExpression? {
        guard !filters.isEmpty else {
            return nil
        }

        return SQLList(
            items: filters.map(self.filter),
            separator: SQLBinaryOperator.and
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
        case .join(let schema, let foreign, let local, let method):
            return SQLJoin(
                method: self.joinMethod(method),
                table: self.schema(schema),
                expression: SQLBinaryExpression(
                    left: self.field(local),
                    op: SQLBinaryOperator.equal,
                    right: self.field(foreign)
                )
            )
        }
    }

    private func schema(_ schema: DatabaseQuery.Schema) -> SQLExpression {
        switch schema {
        case .schema(let name, let alias):
            if let alias = alias {
                return SQLAlias(SQLIdentifier(name), as: SQLIdentifier(alias))
            } else {
                return SQLIdentifier(name)
            }
        case .custom(let any):
            return custom(any)
        }
    }
    
    private func joinMethod(_ method: DatabaseQuery.Join.Method) -> SQLExpression {
        switch method {
        case .inner: return SQLJoinMethod.inner
        case .left: return SQLJoinMethod.left
        case .right: return SQLJoinMethod.right
        case .outer: return SQLJoinMethod.outer
        case .custom(let any):
            return custom(any)
        }
    }
    
    private func field(_ field: DatabaseQuery.Field) -> SQLExpression {
        switch field {
        case .custom(let any):
            return custom(any)
        case .field(let path, let schema, let alias):
            // TODO: if joins don't exist, use short column name
            switch path.count {
            case 1:
                let name = path[0]
                if let schema = schema {
                    let id = SQLColumn(SQLIdentifier(name), table: SQLIdentifier(schema))
                    if let alias = alias {
                        return SQLAlias(id, as: SQLIdentifier(alias))
                    } else {
                        return id
                    }
                } else {
                    return SQLIdentifier(name)
                }
            case 2:
                // row->".code" = 4
                // return SQLRaw("\(path[0])->>'\(path[1])'")
                // return SQLRaw("JSON_EXTRACT(\(path[0]), '$.\(path[1])')")
                return self.delegate.nestedFieldExpression(path[0], [path[1]])
            default:
                fatalError("Deep SQL JSON nesting not yet supported.")
            }
        case .aggregate(let agg):
            switch agg {
            case .custom(let any):
                return any as! SQLExpression
            case .fields(let method, let fields):
                let name: String
                switch method {
                case .average: name = "AVG"
                case .count: name = "COUNT"
                case .sum: name = "SUM"
                case .maximum: name = "MAX"
                case .minimum: name = "MIN"
                case .custom(let custom): name = custom as! String
                }
                return SQLAlias(SQLFunction(name, args: fields.map { self.field($0) }), as: SQLIdentifier("fluentAggregate"))
            }
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
                guard let string = bind as? CustomStringConvertible else {
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
            let expression = SQLList(
                items: filters.map(self.filter),
                separator: self.relation(relation)
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
    
    struct DictValues: Encodable {
        let dict: [String: DatabaseQuery.Value]

        func encode(to encoder: Encoder) throws {
            var keyed = encoder.container(keyedBy: StringCodingKey.self)
            for (key, val) in self.dict {
                let key = StringCodingKey(key)
                switch val {
                case .bind(let encodable):
                    try keyed.encode(EncodableWrapper(encodable), forKey: key)
                case .null:
                    try keyed.encodeNil(forKey: key)
                default: fatalError()
                }
            }
        }
    }
    
    private func value(_ value: DatabaseQuery.Value) -> SQLExpression {
        switch value {
        case .bind(let encodable):
            return SQLBind(encodable)
        case .null:
            return SQLLiteral.null
        case .array(let values):
            return SQLGroupExpression(SQLList(items: values.map(self.value), separator: SQLRaw(",")))
        case .dictionary(let dict):
            return SQLBind(DictValues(dict: dict))
        case .default:
            return SQLLiteral.default
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
}

extension Encodable {
    var isNil: Bool {
        if let optional = self as? AnyOptionalType {
            return optional.wrappedValue == nil
        } else {
            return false
        }
    }
}

extension DatabaseQuery.Value {
    var isNull: Bool {
        switch self {
        case .null:
            return true
        case .bind(let bind):
            return bind.isNil
        default:
            return false
        }
    }
}

private struct StringCodingKey: CodingKey {
    /// `CodingKey` conformance.
    public var stringValue: String

    /// `CodingKey` conformance.
    public var intValue: Int? {
        return Int(self.stringValue)
    }

    /// Creates a new `StringCodingKey`.
    public init(_ string: String) {
        self.stringValue = string
    }

    /// `CodingKey` conformance.
    public init(stringValue: String) {
        self.stringValue = stringValue
    }

    /// `CodingKey` conformance.
    public init(intValue: Int) {
        self.stringValue = intValue.description
    }
}
