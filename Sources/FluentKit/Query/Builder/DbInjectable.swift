//
//  File.swift
//  
//
//  Created by Markus Kasperczyk on 13.12.21.
//


public protocol DbInjectable : DbView {}


internal protocol _FieldBindingProtocol {
    
    var key : DatabaseQuery.Field {get}
    func inject(from any: Any)
    
}


@propertyWrapper
public final class FieldBindingProperty<Base : FluentKit.Model, Value : QueryableProperty> : _FieldBindingProtocol {
    
    public var wrappedValue : Value {
        guard let value = self.value else {
            fatalError("Cannot access field before it is fetched: \(self.key)")
        }
        return value
    }
    
    private let keyPath : KeyPath<Base, Value>
    private var value : Value?
    
    public init(_ keyPath: KeyPath<Base, Value>) {
        self.keyPath = keyPath
    }
    
    internal var key: DatabaseQuery.Field {
        .path(Base.path(for: keyPath),
              schema: Base.schema)
    }
    
    internal func inject(from any: Any) {
        value = (any as? Base)?[keyPath: keyPath]
    }
    
}


extension FieldBindingProperty : Codable where Value : Codable {
    
    /// - Important: This method is not implemented. The only reason why FieldBindingProperty conforms to ```Codable```rather than ```Encodable``` is that it makes conforming to Vapor's ```Content``` (and hence ```ResponseEncodable```) protocol easier.
    public convenience init(from decoder: Decoder) throws {
        fatalError("init(from: Decoder) not implemented.")
    }
    
    public func encode(to encoder: Encoder) throws {
        try wrappedValue.encode(to: encoder)
    }
    
}


internal extension DbInjectable {
    
    func searchFieldBindings(_ visitor: (_FieldBindingProtocol) -> Void) {
        
        var mirror = Mirror(reflecting: self)
        
        var childrenToCheck = Array(mirror.children)
        
        var nextIdx = 0
        
        while nextIdx < childrenToCheck.count {
            
            if let binding = mirror as? _FieldBindingProtocol {
                visitor(binding)
            }
            
            mirror = Mirror(reflecting: childrenToCheck[nextIdx].value)
            childrenToCheck.append(contentsOf: mirror.children)
            nextIdx += 1
            
        }
    }
    
}


public extension DbInjectable {
    
    typealias FieldBinding<Property : QueryableProperty> = FieldBindingProperty<Base, Property>
    
    var overrideFields: [DatabaseQuery.Field] {
        
        var fields = [DatabaseQuery.Field]()
        searchFieldBindings{fields.append($0.key)}
        return fields
        
    }
    
    func injected(from base: Base) throws -> Self {
        
        searchFieldBindings{$0.inject(from: base)}
        return self
        
    }
    
}


@propertyWrapper
public final class ArrayBindingProperty<Base : FluentKit.Model, ViewModel : DbView, Key : QueryableProperty> : _FieldBindingProtocol
where Key.Value == [ViewModel.Base] {
    
    public var wrappedValue : [ViewModel] {
        guard let value = self.value else {
            fatalError("Cannot access field before it is fetched: \(self.key)")
        }
        return value
    }
    
    private let keyPath : KeyPath<Base, Key>
    private var value : [ViewModel]?
    
    public init(_ keyPath: KeyPath<Base, Key>,
                as type: ViewModel.Type) {
        self.keyPath = keyPath
    }
    
    internal var key: DatabaseQuery.Field {
        .path(Base.path(for: keyPath),
              schema: Base.schema)
    }
    
    internal func inject(from any: Any) {
        guard let models = (any as? Base)?[keyPath: keyPath].value else {
            return
        }
        value = models.map {model in
            ViewModel().injected(from: model)
        }
    }
    
}
