extension QueryBuilder {
    // MARK: Parent, children, and siblings joins
    
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
        self.join(To.self, on: parent.appending(path: \.$id) == \To._$id, method: method)
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
        self.join(from: Model.self, parent: parent, method: method)
    }

    /// This will join a foreign table based on a `@OptionalParent` relation
    ///
    /// This will not decode the joined data, but can be used in order to filter.
    ///
    ///     Planet.query(on: db)
    ///         .join(from: Planet.self, parent: \.$star)
    ///         .filter(Star.self, \Star.$name == "Sun")
    ///
    /// - Parameters:
    ///   - model: The `Model` to join from
    ///   - parent: The `OptionalParentProperty` to join
    ///   - method: The method to use. The default is an inner join
    /// - Returns: A new `QueryBuilder`
    @discardableResult
    public func join<From, To>(
        from model: From.Type,
        parent: KeyPath<From, OptionalParentProperty<From, To>>,
        method: DatabaseQuery.Join.Method = .inner
    ) -> Self {
        self.join(To.self, on: parent.appending(path: \.$id) == \To._$id, method: method)
    }

    /// This will join a foreign table based on a `@OptionalParent` relation
    ///
    /// This will not decode the joined data, but can be used in order to filter.
    ///
    ///     Planet.query(on: db)
    ///         .join(parent: \.$star)
    ///         .filter(Star.self, \Star.$name == "Sun")
    ///
    /// - Parameters:
    ///   - parent: The `OptionalParentProperty` to join
    ///   - method: The method to use. The default is an inner join
    /// - Returns: A new `QueryBuilder`
    @discardableResult
    public func join<To>(
        parent: KeyPath<Model, OptionalParentProperty<Model, To>>,
        method: DatabaseQuery.Join.Method = .inner
    ) -> Self {
        self.join(from: Model.self, parent: parent, method: method)
    }
    
    /// This will join a foreign table based on a `@OptionalChild` relation
    ///
    /// This will not decode the joined data, but can be used in order to filter.
    ///
    ///     Planet.query(on: db)
    ///         .join(child: \.$governor)
    ///         .filter(Governor.self, \Governor.$name == "John Doe")
    ///
    /// - Parameters:
    ///   - model: The `Model` to join from
    ///   - child: The `ChildProperty` to join
    ///   - method: The method to use. The default is an inner join
    /// - Returns: A new `QueryBuilder`
    @discardableResult
    public func join<From, To>(
        from model: From.Type,
        child: KeyPath<From, OptionalChildProperty<From, To>>,
        method: DatabaseQuery.Join.Method = .inner
    ) -> Self {
        switch From()[keyPath: child].parentKey {
        case .optional(let parent): return self.join(To.self, on: \From._$id == parent.appending(path: \.$id), method: method)
        case .required(let parent): return self.join(To.self, on: \From._$id == parent.appending(path: \.$id), method: method)
        }
    }

    /// This will join a foreign table based on a `@OptionalChild` relation
    ///
    /// This will not decode the joined data, but can be used in order to filter.
    ///
    ///     Planet.query(on: db)
    ///         .join(child: \.$governor)
    ///         .filter(Governor.self, \Governor.$name == "John Doe")
    ///
    /// - Parameters:
    ///   - child: The `ChildProperty` to join
    ///   - method: The method to use. The default is an inner join
    /// - Returns: A new `QueryBuilder`
    @discardableResult
    public func join<To>(
        child: KeyPath<Model, OptionalChildProperty<Model, To>>,
        method: DatabaseQuery.Join.Method = .inner
    ) -> Self {
        self.join(from: Model.self, child: child, method: method)
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
        case .optional(let parent): return self.join(To.self, on: \From._$id == parent.appending(path: \.$id), method: method)
        case .required(let parent): return self.join(To.self, on: \From._$id == parent.appending(path: \.$id), method: method)
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
        self.join(from: Model.self, children: children, method: method)
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
        
        return self.join(Through.self, on: siblings.from.appending(path: \.$id) == \From._$id)
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
        self.join(from: Model.self, siblings: siblings)
    }
}
