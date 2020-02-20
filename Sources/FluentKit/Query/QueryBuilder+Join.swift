extension QueryBuilder {
    // MARK: Join

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
        _ foreignField: FieldKey,
        to local: Local.Type,
        _ localField: FieldKey,
        method: DatabaseQuery.Join.Method = .inner,
        alias schemaAlias: String? = nil
    ) -> Self
        where Foreign: FluentKit.Model, Local: FluentKit.Model
    {
        self.join(Foreign.self, [foreignField], to: Local.self, [localField], method: method, alias: schemaAlias)
    }

    @discardableResult
    private func join<Foreign, Local>(
        _ foreign: Foreign.Type,
        _ foreignFieldPath: [FieldKey],
        to local: Local.Type,
        _ localFieldPath: [FieldKey],
        method: DatabaseQuery.Join.Method = .inner,
        alias schemaAlias: String? = nil
    ) -> Self
        where Foreign: FluentKit.Model, Local: FluentKit.Model
    {
        self.joinedModels.append(.init(model: Foreign(), alias: schemaAlias))
        self.query.joins.append(.join(
            schema: .schema(name: Foreign.schema, alias: schemaAlias),
            foreign: .field(
                path: foreignFieldPath,
                schema: schemaAlias ?? Foreign.schema,
                alias: nil
            ),
            local: .field(
                path: localFieldPath,
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
    Foreign: Model, ForeignField: FieldProtocol,
    Local: Model, LocalField: FieldProtocol,
    ForeignField.Value == LocalField.Value
{
    return .init(foreign: Foreign.path(for: rhs), local: Local.path(for: lhs))
}

public func == <Foreign, ForeignField, Local, LocalField>(
    lhs: KeyPath<Local, LocalField>, rhs: KeyPath<Foreign, ForeignField>
) -> JoinFilter<Foreign, Local, ForeignField.Value>
    where
    Foreign: Model, ForeignField: FieldProtocol,
    Local: Model, LocalField: FieldProtocol,
    ForeignField.Value == Optional<LocalField.Value>
{
    return .init(foreign: Foreign.path(for: rhs), local: Local.path(for: lhs))
}


public func == <Foreign, ForeignField, Local, LocalField>(
    lhs: KeyPath<Local, LocalField>, rhs: KeyPath<Foreign, ForeignField>
) -> JoinFilter<Foreign, Local, LocalField.Value>
    where
    Foreign: Model, ForeignField: FieldProtocol,
    Local: Model, LocalField: FieldProtocol,
    Optional<ForeignField.Value> == LocalField.Value
{
    return .init(foreign: Foreign.path(for: rhs), local: Local.path(for: lhs))
}


public struct JoinFilter<Foreign, Local, Value>
    where Foreign: Model, Local: Model, Value: Codable
{
    let foreign: [FieldKey]
    let local: [FieldKey]
}
