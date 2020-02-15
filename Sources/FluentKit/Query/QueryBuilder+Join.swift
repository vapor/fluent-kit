extension QueryBuilder {
    // MARK: Join

    @discardableResult
    public func join<Value>(
        _ field: KeyPath<Model, Model.Parent<Value>>,
        alias: String? = nil
    ) -> Self
        where Value: FluentKit.Model
    {
        return self.join(
            Value.self, Value.key(for: \._$id),
            to: Model.self, Model.key(for: field.appending(path: \.$id)),
            method: .inner,
            alias: alias
        )
    }
    
    @discardableResult
    public func join<Value>(
        _ field: KeyPath<Value, Value.Parent<Model>>,
        alias: String? = nil
    ) -> Self
        where Value: FluentKit.Model
    {
        return self.join(
            Value.self, Value.key(for: field.appending(path: \.$id)),
            to: Model.self, Model.key(for: \._$id),
            method: .inner,
            alias: alias
        )
    }

    @discardableResult
    public func join<Foreign, Local, Value>(
        _ foreign: KeyPath<Foreign, Model.Field<Value?>>,
        to local: KeyPath<Local, Model.Field<Value>>,
        method: DatabaseQuery.Join.Method = .inner,
        alias: String? = nil
    ) -> Self
        where Value: Codable, Foreign: FluentKit.Model, Local: FluentKit.Model
    {
        return self.join(
            Foreign.self, Foreign.key(for: foreign),
            to: Local.self, Local.key(for: local),
            method: .inner,
            alias: alias
        )
    }

    @discardableResult
    public func join<Foreign, Local, Value>(
        _ foreign: KeyPath<Foreign, Model.Field<Value>>,
        to local: KeyPath<Local, Model.Field<Value?>>,
        method: DatabaseQuery.Join.Method = .inner,
        alias: String? = nil
    ) -> Self
        where Value: Codable, Foreign: FluentKit.Model, Local: FluentKit.Model
    {
        return self.join(
            Foreign.self, Foreign.key(for: foreign),
            to: Local.self, Local.key(for: local),
            method: .inner,
            alias: alias
        )
    }

    @discardableResult
    public func join<Foreign, Local, Value>(
        _ foreign: KeyPath<Foreign, Model.Field<Value>>,
        to local: KeyPath<Local, Model.Field<Value>>,
        method: DatabaseQuery.Join.Method = .inner,
        alias: String? = nil
    ) -> Self
        where Value: Codable, Foreign: FluentKit.Model, Local: FluentKit.Model
    {
        return self.join(
            Foreign.self, Foreign.key(for: foreign),
            to: Local.self, Local.key(for: local),
            method: .inner,
            alias: alias
        )
    }

    @discardableResult
    public func join<Foreign, Local, Value>(
        _ foreign: Foreign.Type,
        on filter: JoinFilter<Foreign, Local, Value>,
        method: DatabaseQuery.Join.Method = .inner
    ) -> Self
        where Foreign: FluentKit.Model, Local: FluentKit.Model
    {
        return self.join(
            Foreign.self, filter.foreign,
            to: Local.self, filter.local,
            alias: nil
        )
    }

    @discardableResult
    public func join<ForeignAlias, Local, Value>(
        _ foreignAlias: ForeignAlias.Type,
        on filter: JoinFilter<ForeignAlias.Model, Local, Value>,
        method: DatabaseQuery.Join.Method = .inner
    ) -> Self
        where ForeignAlias: ModelAlias, Local: FluentKit.Model
    {
        return self.join(
            ForeignAlias.Model.self, filter.foreign,
            to: Local.self, filter.local,
            alias: ForeignAlias.alias
        )
    }

    @discardableResult
    private func join<Foreign, Local>(
        _ foreign: Foreign.Type,
        _ foreignField: String,
        to local: Local.Type,
        _ localField: String,
        method: DatabaseQuery.Join.Method = .inner,
        alias schemaAlias: String? = nil
    ) -> Self
        where Foreign: FluentKit.Model, Local: FluentKit.Model
    {
        self.joinedModels.append(.init(model: Foreign(), alias: schemaAlias))
        self.query.joins.append(.join(
            schema: .schema(name: Foreign.schema, alias: schemaAlias),
            foreign: .field(
                path: [foreignField],
                schema: schemaAlias ?? Foreign.schema,
                alias: nil
            ),
            local: .field(
                path: [localField],
                schema: Local.schema,
                alias: nil
            ),
            method: method
        ))
        return self
    }
}

public func == <Foreign, ForeignField, Local, LocalField>(
    lhs: KeyPath<Local, LocalField>, rhs: KeyPath<Foreign, ForeignField>
) -> JoinFilter<Foreign, Local, ForeignField.Value>
    where
    Foreign: Model, ForeignField: FieldRepresentable,
    Local: Model, LocalField: FieldRepresentable,
    ForeignField.Value == LocalField.Value
{
    return .init(foreign: Foreign.key(for: rhs), local: Local.key(for: lhs))
}

public func == <Foreign, ForeignField, Local, LocalField>(
    lhs: KeyPath<Local, LocalField>, rhs: KeyPath<Foreign, ForeignField>
) -> JoinFilter<Foreign, Local, ForeignField.Value>
    where
    Foreign: Model, ForeignField: FieldRepresentable,
    Local: Model, LocalField: FieldRepresentable,
    ForeignField.Value == Optional<LocalField.Value>
{
    return .init(foreign: Foreign.key(for: rhs), local: Local.key(for: lhs))
}


public func == <Foreign, ForeignField, Local, LocalField>(
    lhs: KeyPath<Local, LocalField>, rhs: KeyPath<Foreign, ForeignField>
) -> JoinFilter<Foreign, Local, LocalField.Value>
    where
    Foreign: Model, ForeignField: FieldRepresentable,
    Local: Model, LocalField: FieldRepresentable,
    Optional<ForeignField.Value> == LocalField.Value
{
    return .init(foreign: Foreign.key(for: rhs), local: Local.key(for: lhs))
}


public struct JoinFilter<Foreign, Local, Value>
    where Foreign: Model, Local: Model, Value: Codable
{
    let foreign: String
    let local: String
}
