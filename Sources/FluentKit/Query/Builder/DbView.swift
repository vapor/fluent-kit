//
//  DbView.swift
//  
//
//  Created by Markus Kasperczyk on 13.12.21.
//

import NIOCore



public protocol DbView {
    
    associatedtype Base : FluentKit.Model
    init()
    func injected(from base: Base) -> Self
    var overrideFields : [DatabaseQuery.Field] {get}
    
}

public protocol Initializable {
    init()
}


#if !os(Linux) || !compiler(<5.3)

// MARK: ViewBinder
public final class ViewBinder<Base : FluentKit.Model, Prototype : Initializable> : DbView {
    
    var visitors = [(Base, inout Prototype) -> Void]()
    internal(set) public var overrideFields = [DatabaseQuery.Field]()
    private(set) public var prototype : Prototype
    
    init(prototype : Prototype) {
        self.prototype = prototype
    }
    
    // conformance
    
    public convenience init() {
        self.init(prototype: .init())
    }
    public func injected(from base: Base) -> Self {
        for visitor in visitors {
            visitor(base, &prototype)
        }
        return self
    }
    
}

#endif

public extension QueryBuilder {
    
    func view<View>(as prototype: View) -> QueryViewBuilder<View>
    where
    View : DbView,
    View.Base == Model {
        
        return .init(builder: copy(),
                     prototype: prototype)
        
    }
    
    func view<View>(as type: View.Type) -> QueryViewBuilder<View>
    where View : DbView,
          View.Base == Model {
              view(as: View())
          }
    
#if !os(Linux) || !compiler(<5.3)
    
    func project<View>(onto prototype: View)
    -> QueryViewBuilder<ViewBinder<Model, View>> where
    View : DbView,
    View.Base == Model {
        view(as: .init(prototype: prototype))
    }
    
    func project<View>(onto type: View.Type) -> QueryViewBuilder<ViewBinder<Model, View>>
    where
    View : DbView,
    View.Base == Model {
        project(onto: .init())
    }
    
#endif
    
}


public final class QueryViewBuilder<View> where View : DbView {
    
    public typealias Model = View.Base
    public let builder : QueryBuilder<Model>
    internal(set) public var prototype : View
    
    internal init(builder: QueryBuilder<Model>,
                  prototype: View)
    {
        self.builder = builder
        self.prototype = prototype
    }
    
}


public extension QueryViewBuilder {
    
#if !os(Linux) || !compiler(<5.3)
    
    func bind<Base, Wrapped : Initializable, Property : QueryableProperty>(
        _ prop: KeyPath<Model, Property>,
        to writable: WritableKeyPath<Wrapped, Property>) -> Self
    where
    View == ViewBinder<Base, Wrapped> {
        prototype.overrideFields.append(.path(Base.path(for: prop), schema: Base.schema))
        prototype.visitors.append {model, proto in
            proto[keyPath: writable] = model[keyPath: prop]
        }
        return self
    }
    
#endif
    
    private func prepareForFetch() {
        builder.query.fields = prototype.overrideFields
    }
    
    func all() -> EventLoopFuture<[View]> {
        prepareForFetch()
        return builder.all().map {models in
            models.map(self.prototype.injected)
        }
    }
    
    func first() -> EventLoopFuture<View?> {
        prepareForFetch()
        return builder.first().map{maybeModel in
            maybeModel.map(self.prototype.injected)
        }
    }
    
}
