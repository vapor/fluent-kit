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

    /// This will join a foreign table based on a `@Parent` relation
    ///
    /// This will not decode the joined data, but can be used in order to filter.
    ///
    ///     Planet.query(on: db)
    ///         .join(from: Planet.self, parent: \.$star)
    ///         .filter(Star.self, \Star.$name == "Sun")
    ///
    /// - Parameters:
    ///   - model: The `Model` to join from
    ///   - parent: The `ParentProperty` to join
    ///   - method: The method to use. The default is an inner join
    /// - Returns: A new `QueryBuilder`
    @discardableResult
    public func join<From, To>(
        from model: From.Type,
        parent: KeyPath<From, ParentProperty<From, To>>,
        method: DatabaseQuery.Join.Method = .inner
    ) -> Self {
        join(To.self, on: parent.appending(path: \.$id) == \To._$id, method: method)
    }

    /// This will join a foreign table based on a `@Parent` relation
    ///
    /// This will not decode the joined data, but can be used in order to filter.
    ///
    ///     Planet.query(on: db)
    ///         .join(parent: \.$star)
    ///         .filter(Star.self, \Star.$name == "Sun")
    ///
    /// - Parameters:
    ///   - parent: The `ParentProperty` to join
    ///   - method: The method to use. The default is an inner join
    /// - Returns: A new `QueryBuilder`
    @discardableResult
    public func join<To>(
        parent: KeyPath<Model, ParentProperty<Model, To>>,
        method: DatabaseQuery.Join.Method = .inner
    ) -> Self {
        join(from: Model.self, parent: parent, method: method)
    }

    /// This will join a foreign table based on a `@Children` relation
    ///
    /// This will not decode the joined data, but can be used in order to filter.
    ///
    ///     Star.query(on: db)
    ///         .join(from: Star.self, children: \.$planets)
    ///         .filter(Planet.self, \Planet.$name == "Earth")
    ///
    /// - Parameters:
    ///   - model: The `Model` to join from
    ///   - children: The `ChildrenProperty` to join
    ///   - method: The method to use. The default is an inner join
    /// - Returns: A new `QueryBuilder`
    @discardableResult
    public func join<From, To>(
        from model: From.Type,
        children: KeyPath<From, ChildrenProperty<From, To>>,
        method: DatabaseQuery.Join.Method = .inner
    ) -> Self {
        switch From()[keyPath: children].parentKey {
        case .optional(let parent): return join(To.self, on: \From._$id == parent.appending(path: \.$id), method: method)
        case .required(let parent): return join(To.self, on: \From._$id == parent.appending(path: \.$id), method: method)
        }
    }

    /// This will join a foreign table based on a `@Children` relation
    ///
    /// This will not decode the joined data, but can be used in order to filter.
    ///
    ///     Star.query(on: db)
    ///         .join(children: \.$planets)
    ///         .filter(Planet.self, \Planet.$name == "Earth")
    ///
    /// - Parameters:
    ///   - children: The `ChildrenProperty` to join
    ///   - method: The method to use. The default is an inner join
    /// - Returns: A new `QueryBuilder`
    @discardableResult
    public func join<To>(
        children: KeyPath<Model, ChildrenProperty<Model, To>>,
        method: DatabaseQuery.Join.Method = .inner
    ) -> Self {
        join(from: Model.self, children: children, method: method)
    }

    /// This will join the foreign table based on a `@Siblings`relation
    /// This will result in joining two tables. The Pivot table and the wanted model table
    ///
    /// This will not decode the joined data, but can be used in order to filter.
    ///
    ///     Star.query(on: db)
    ///         .join(from: Star.self, siblings: \.$tags)
    ///         .filter(Tag.self, \Tag.$name == "Something")
    ///
    /// - Parameters:
    ///   - model: The `Model` to join form
    ///   - siblings: The `SiblingsProperty` to join
    /// - Returns: A new `QueryBuilder`
    @discardableResult
    public func join<From, To, Through>(
        from model: From.Type,
        siblings: KeyPath<From, SiblingsProperty<From, To, Through>>
    ) -> Self
        where From: FluentKit.Model, To: FluentKit.Model, Through: FluentKit.Model
    {
        let siblings = From()[keyPath: siblings]
        return join(Through.self, on: siblings.from.appending(path: \.$id) == \From._$id)
            .join(To.self, on: siblings.to.appending(path: \.$id) == \To._$id)
    }

    /// This will join the foreign table based on a `@Siblings`relation
    /// This will result in joining two tables. The Pivot table and the wanted model table
    ///
    /// This will not decode the joined data, but can be used in order to filter.
    ///
    ///     Star.query(on: db)
    ///         .join(siblings: \.$tags)
    ///         .filter(Tag.self, \Tag.$name == "Something")
    ///
    /// - Parameters:
    ///   - siblings: The `SiblingsProperty` to join
    /// - Returns: A new `QueryBuilder`
    @discardableResult
    public func join<To, Through>(
        siblings: KeyPath<Model, SiblingsProperty<Model, To, Through>>
    ) -> Self
        where To: FluentKit.Model, Through: FluentKit.Model
    {
        join(from: Model.self, siblings: siblings)
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
