//@dynamicMemberLookup
//public final class NestedProperty<Model, Property>
//    where Model: Fields, Property: FilterableProperty
//{
//    public let prefix: [FieldKey]
//    public let property: Property
//
//    public init(prefix: [FieldKey], property: Property) {
//        self.prefix = prefix
//        self.property = property
//    }
//
//    public subscript<Property>(
//        dynamicMember keyPath: KeyPath<FilterValue, Property>
//    ) -> NestedProperty<Model, Property> {
//        .init(prefix: self.path, property: self.value![keyPath: keyPath])
//    }
//}
//
//extension NestedProperty: FilterableProperty {
//    public var path: [FieldKey] {
//        self.prefix + self.property.path
//    }
//
//    public typealias FilterModel = Property.FilterModel
//    public typealias FilterValue = Property.FilterValue
//}
