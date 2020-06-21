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
        self.join(Foreign.self, filter.foreign, to: Local.self, filter.local , method: method)
    }

    func join<From, To>(
        parent: KeyPath<From, ParentProperty<From, To>>,
        method: DatabaseQuery.Join.Method = .inner
    ) -> Self {
        join(To.self, on: parent.appending(path: \.$id) == \To._$id, method: method)
    }

    func join<From, To>(
        children: KeyPath<From, ChildrenProperty<From, To>>,
        method: DatabaseQuery.Join.Method = .inner
    ) -> Self {
        switch From()[keyPath: children].parentKey {
        case .optional(let parent): return join(To.self, on: \From._$id == parent.appending(path: \.$id), method: method)
        case .required(let parent): return join(To.self, on: \From._$id == parent.appending(path: \.$id), method: method)
        }
    }

    func join<From, To, Through>(
        siblings: KeyPath<From, SiblingsProperty<From, To, Through>>
    ) -> Self
        where From: FluentKit.Model, To: FluentKit.Model, Through: FluentKit.Model
    {
        let siblings = From()[keyPath: siblings]
        return join(Through.self, on: siblings.from.appending(path: \.$id) == \From._$id)
            .join(To.self, on: siblings.to.appending(path: \.$id) == \To._$id)
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
        self.join(Foreign.self, [foreignField], to: Local.self, [localField], method: method)
    }

    @discardableResult
    private func join<Foreign, Local>(
        _ foreign: Foreign.Type,
        _ foreignPath: [FieldKey],
        to local: Local.Type,
        _ localPath: [FieldKey],
        method: DatabaseQuery.Join.Method = .inner
    ) -> Self
        where Foreign: Schema, Local: Schema
    {
        self.models.append(Foreign.self)
        self.query.joins.append(.join(
            schema: Foreign.schema,
            alias: Foreign.alias,
            method,
            foreign: .path(foreignPath, schema: Foreign.schemaOrAlias),
            local: .path(localPath, schema: Local.schemaOrAlias)
        ))
        return self
    }
}

// MARK: Local == Foreign

public func == <Foreign, ForeignField, Local, LocalField>(
    lhs: KeyPath<Local, LocalField>, rhs: KeyPath<Foreign, ForeignField>
) -> JoinFilter<Foreign, Local, ForeignField.Value>
    where
        ForeignField: QueryableProperty,
        ForeignField.Model == Foreign,
        LocalField: QueryableProperty,
        LocalField.Model == Local,
        ForeignField.Value == LocalField.Value
{
    .init(foreign: Foreign.path(for: rhs), local: Local.path(for: lhs))
}

public func == <Foreign, ForeignField, Local, LocalField>(
    lhs: KeyPath<Local, LocalField>, rhs: KeyPath<Foreign, ForeignField>
) -> JoinFilter<Foreign, Local, ForeignField.Value>
    where
        ForeignField: QueryableProperty,
        ForeignField.Model == Foreign,
        LocalField: QueryableProperty,
        LocalField.Model == Local,
        ForeignField.Value == Optional<LocalField.Value>
{
    .init(foreign: Foreign.path(for: rhs), local: Local.path(for: lhs))
}


public func == <Foreign, ForeignField, Local, LocalField>(
    lhs: KeyPath<Local, LocalField>, rhs: KeyPath<Foreign, ForeignField>
) -> JoinFilter<Foreign, Local, LocalField.Value>
    where
        ForeignField: QueryableProperty,
        ForeignField.Model == Foreign,
        LocalField: QueryableProperty,
        LocalField.Model == Local,
        Optional<ForeignField.Value> == LocalField.Value
{
    .init(foreign: Foreign.path(for: rhs), local: Local.path(for: lhs))
}

// MARK: Foreign == Local

public func == <Foreign, ForeignField, Local, LocalField>(
    lhs: KeyPath<Foreign, ForeignField>, rhs: KeyPath<Local, LocalField>
) -> JoinFilter<Foreign, Local, ForeignField.Value>
    where
        ForeignField: QueryableProperty,
        ForeignField.Model == Foreign,
        LocalField: QueryableProperty,
        LocalField.Model == Local,
        ForeignField.Value == LocalField.Value
{
    .init(foreign: Foreign.path(for: lhs), local: Local.path(for: rhs))
}

public func == <Foreign, ForeignField, Local, LocalField>(
    lhs: KeyPath<Foreign, ForeignField>, rhs: KeyPath<Local, LocalField>
) -> JoinFilter<Foreign, Local, ForeignField.Value>
    where
        ForeignField: QueryableProperty,
        ForeignField.Model == Foreign,
        LocalField: QueryableProperty,
        LocalField.Model == Local,
        ForeignField.Value == Optional<LocalField.Value>
{
    .init(foreign: Foreign.path(for: lhs), local: Local.path(for: rhs))
}


public func == <Foreign, ForeignField, Local, LocalField>(
    lhs: KeyPath<Foreign, ForeignField>, rhs: KeyPath<Local, LocalField>
) -> JoinFilter<Foreign, Local, LocalField.Value>
    where
        ForeignField: QueryableProperty,
        ForeignField.Model == Foreign,
        LocalField: QueryableProperty,
        LocalField.Model == Local,
        Optional<ForeignField.Value> == LocalField.Value
{
    .init(foreign: Foreign.path(for: lhs), local: Local.path(for: rhs))
}


public struct JoinFilter<Foreign, Local, Value>
    where Foreign: Fields, Local: Fields, Value: Codable
{
    let foreign: [FieldKey]
    let local: [FieldKey]
}
