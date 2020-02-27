extension QueryBuilder {
    // MARK: Join

    @discardableResult
    public func join<Foreign, Local, Value>(
        _ foreign: Foreign.Type,
        on filter: JoinFilter<Foreign, Local, Value>,
        method: DatabaseQuery.Join.Method = .inner
    ) -> Self
        where Foreign: Schema, Local: Schema
    {
        self.join(Foreign.self, filter.foreign, to: Local.self, filter.local)
    }

    @discardableResult
    private func join<Foreign, Local>(
        _ foreign: Foreign.Type,
        _ foreignField: FieldKey,
        to local: Local.Type,
        _ localField: FieldKey,
        method: DatabaseQuery.Join.Method = .inner
    ) -> Self
        where Foreign: Schema, Local: Schema
    {
        self.models.append(Foreign.self)
        self.query.joins.append(.join(
            schema: Foreign.schema,
            alias: Foreign.alias,
            method,
            foreign: .field(foreignField, schema: Foreign.schemaOrAlias),
            local: .field(localField, schema: Local.schemaOrAlias)
        ))
        return self
    }
}

public func == <Foreign, ForeignField, Local, LocalField>(
    lhs: KeyPath<Local, LocalField>, rhs: KeyPath<Foreign, ForeignField>
) -> JoinFilter<Foreign, Local, ForeignField.FieldValue>
    where
        ForeignField: FieldProtocol,
        ForeignField.Model == Foreign,
        LocalField: FieldProtocol,
        LocalField.Model == Local,
        ForeignField.FieldValue == LocalField.FieldValue
{
    .init(foreign: .key(for: rhs), local: .key(for: lhs))
}

public func == <Foreign, ForeignField, Local, LocalField>(
    lhs: KeyPath<Local, LocalField>, rhs: KeyPath<Foreign, ForeignField>
) -> JoinFilter<Foreign, Local, ForeignField.FieldValue>
    where
        ForeignField: FieldProtocol,
        ForeignField.Model == Foreign,
        LocalField: FieldProtocol,
        LocalField.Model == Local,
        ForeignField.FieldValue == Optional<LocalField.FieldValue>
{
    .init(foreign: .key(for: rhs), local: .key(for: lhs))
}


public func == <Foreign, ForeignField, Local, LocalField>(
    lhs: KeyPath<Local, LocalField>, rhs: KeyPath<Foreign, ForeignField>
) -> JoinFilter<Foreign, Local, LocalField.FieldValue>
    where
        ForeignField: FieldProtocol,
        ForeignField.Model == Foreign,
        LocalField: FieldProtocol,
        LocalField.Model == Local,
        Optional<ForeignField.FieldValue> == LocalField.FieldValue
{
    .init(foreign: .key(for: rhs), local: .key(for: lhs))
}


public struct JoinFilter<Foreign, Local, Value>
    where Foreign: Fields, Local: Fields, Value: Codable
{
    let foreign: FieldKey
    let local: FieldKey
}
