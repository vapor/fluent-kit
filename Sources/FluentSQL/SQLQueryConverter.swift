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
            #warning("TODO:")
            return any as! SQLExpression
        }
        return sql
    }
    
    // MARK: Private
    
    private func delete(_ query: DatabaseQuery) -> SQLExpression {
        var delete = SQLDelete(table: SQLIdentifier(query.entity))
        delete.predicate = self.filters(query.filters)
        return delete
    }
    
    private func update(_ query: DatabaseQuery) -> SQLExpression {
        var update = SQLUpdate(table: SQLIdentifier(query.entity))
        #warning("TODO: better indexing")
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
        select.tables.append(SQLIdentifier(query.entity))
        select.columns = query.fields.map(self.field)
        select.predicate = self.filters(query.filters)
        select.joins = query.joins.map(self.join)
        return select
    }
    
    private func insert(_ query: DatabaseQuery) -> SQLExpression {
        var insert = SQLInsert(table: SQLIdentifier(query.entity))
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
    
    private func join(_ join: DatabaseQuery.Join) -> SQLExpression {
        switch join {
        case .custom(let any): return any as! SQLExpression
        case .model(let foreign, let local, let method):
            let table: SQLExpression
            switch foreign {
            case .custom(let any): table = any as! SQLExpression
            case .field(let path, let entity, let alias):
                table = SQLIdentifier(entity!)
            case .aggregate(let agg):
                fatalError("can't join on aggregate")
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
        case .right: return SQLJoinMethod.right
        case .outer: return SQLJoinMethod.outer
        case .custom(let any):
            #warning("TODO:")
            return any as! SQLExpression
        }
    }
    
    private func field(_ field: DatabaseQuery.Field) -> SQLExpression {
        switch field {
        case .custom(let any):
            #warning("TODO:")
            return any as! SQLExpression
        case .field(let path, let entity, let alias):
            #warning("TODO: if joins don't exist, use short column name")
            switch path.count {
            case 1:
                let name = path[0]
                if let entity = entity {
                    let id = SQLColumn(SQLIdentifier(name), table: SQLIdentifier(entity))
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
            default: fatalError()
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
        case .basic(let field, let method, let value):
            return SQLBinaryExpression(
                left: self.field(field),
                op: self.method(method),
                right: self.value(value)
            )
        case .custom(let any):
            #warning("TODO:")
            return any as! SQLExpression
        case .group(let filters, let relation):
            return SQLList(items: filters.map(self.filter), separator: self.relation(relation))
        }
    }
    
    private func relation(_ relation: DatabaseQuery.Filter.Relation) -> SQLExpression {
        switch relation {
        case .and: return SQLBinaryOperator.and
        case .or: return SQLBinaryOperator.or
        case .custom(let any): return any as! SQLExpression
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
            return SQLGroupExpression(SQLList(items: values.map(self.value), separator: SQLRaw(", ")))
        case .dictionary(let dict):
            return SQLBind(DictValues(dict: dict))
        default:
            #warning("TODO:")
            fatalError("\(value) not yet supported")
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
        default:
            #warning("TODO:")
            fatalError("\(method) not yet supported")
        }
    }
}
