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
        var delete = SQLDelete(table: SQLIdentifier(query.schema))
        delete.predicate = self.filters(query.filters)
        return delete
    }
    
    private func update(_ query: DatabaseQuery) -> SQLExpression {
        var update = SQLUpdate(table: SQLIdentifier(query.schema))
        guard case .dictionary(let nested) = query.input.first! else {
            fatalError()
        }
        var keysAndValues: [[FieldKey]: DatabaseQuery.Value] = [:]
        nested.forEach { (key, value) in
            self.accumlateKeysAndValues(value, path: [key], keysAndValues: &keysAndValues)
        }

        keysAndValues.forEach { (path, value) in
            update.values.append(SQLBinaryExpression(
                left: SQLColumn(self.path(path)),
                op: SQLBinaryOperator.equal,
                right: self.value(value)
            ))
        }
        update.predicate = self.filters(query.filters)
        return update
    }
    
    private func select(_ query: DatabaseQuery) -> SQLExpression {
        var select = SQLSelect()
        select.tables.append(SQLIdentifier(query.schema))
        switch query.action {
        case .read:
            select.isDistinct = query.isUnique
            select.columns = query.fields.map { field in
                switch field {
                case .custom(let any):
                    return custom(any)
                case .path(let path, let schema):
                    return SQLAlias(
                        SQLColumn(self.path(path), table: schema),
                        as: SQLIdentifier(schema + "_" + self.path(path))
                    )
                }
            }
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

    private func accumlateKeysAndValues(
        _ value: DatabaseQuery.Value,
        path: [FieldKey],
        keysAndValues: inout [[FieldKey]: DatabaseQuery.Value]
    ) {
        switch value {
        case .dictionary(let nested):
            nested.forEach { (key, value) in
                self.accumlateKeysAndValues(value, path: path + [key], keysAndValues: &keysAndValues)
            }
        default:
            keysAndValues[path] = value
        }
    }

    private func accumlateKeys(
        _ value: DatabaseQuery.Value,
        path: [FieldKey],
        fields: inout [[FieldKey]]
    ) {
        switch value {
        case .dictionary(let nested):
            nested.forEach { (key, value) in
                self.accumlateKeys(value, path: path + [key], fields: &fields)
            }
        default:
            fields.append(path)
        }
    }

    private func fetch(path: [FieldKey], from value: DatabaseQuery.Value) -> DatabaseQuery.Value {
        switch value {
        case .dictionary(let dictionary):
            return self.fetch(path: Array(path[1...]), from: dictionary[path[0]]!)
        default:
            assert(path.count == 0)
            return value
        }
    }
    
    private func insert(_ query: DatabaseQuery) -> SQLExpression {
        var insert = SQLInsert(table: SQLIdentifier(query.schema))

        guard case .dictionary(let nested) = query.input.first! else {
            fatalError()
        }
        var fields: [[FieldKey]] = []
        nested.forEach { (key, value) in
            self.accumlateKeys(value, path: [key], fields: &fields)
        }
        insert.columns = fields.map { path in
            SQLColumn(self.path(path))
        }
        insert.values = query.input.map { value in
            fields.map { path in
                self.fetch(path: path, from: value)
            }.map(self.value)
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
        case .join(let schema, let alias, let method, let foreign, let local):
            let table: SQLExpression
            if let alias = alias {
                table = SQLAlias(SQLIdentifier(schema), as: SQLIdentifier(alias))
            } else {
                table = SQLIdentifier(schema)
            }
            return SQLJoin(
                method: self.joinMethod(method),
                table: table,
                expression: SQLBinaryExpression(
                    left: self.field(local),
                    op: SQLBinaryOperator.equal,
                    right: self.field(foreign)
                )
            )
        }
    }
    
    private func joinMethod(_ method: DatabaseQuery.Join.Method) -> SQLExpression {
        switch method {
        case .inner: return SQLJoinMethod.inner
        case .left: return SQLJoinMethod.left
        case .custom(let any):
            return custom(any)
        }
    }

    private func field(_ field: DatabaseQuery.Field) -> SQLExpression {
        self.field(field, ignoreSchema: false)
    }

    private func field(_ field: DatabaseQuery.Field, ignoreSchema: Bool) -> SQLExpression {
        switch field {
        case .custom(let any):
            return custom(any)
        case .path(let path, let schema):
            if ignoreSchema {
                return SQLIdentifier(self.path(path))
            } else {
                return SQLColumn(self.path(path), table: schema)
            }
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
            case (.subset, .array(let array)) where array.isEmpty:
                return SQLBinaryExpression(
                    left: SQLLiteral.numeric("1"),
                    op: SQLBinaryOperator.equal,
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

    
    private func value(_ value: DatabaseQuery.Value) -> SQLExpression {
        switch value {
        case .bind(let encodable):
            return SQLBind(encodable)
        case .null:
            return SQLLiteral.null
        case .array(let values):
            return SQLGroupExpression(SQLList(items: values.map(self.value), separator: SQLRaw(",")))
        case .dictionary:
            fatalError()
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

    private func path(_ path: [FieldKey]) -> String {
        path.map(self.key).joined(separator: "_")
    }

    private func key(_ key: FieldKey) -> String {
        switch key {
        case .id:
            return "id"
        case .string(let name):
            return name
        case .aggregate:
            return key.description
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
