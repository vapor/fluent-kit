//public protocol ModelSchema {
//    associatedtype Model: FluentKit.Model
//    static var name: DatabaseQuery.Schema { get }
//}
//
//public protocol ModelAlias: ModelSchema {
//    static var alias: String { get }
//}

//extension ModelAlias {
//    public static var name: DatabaseQuery.Schema {
//        .schema(Self.Model.schema, alias: Self.alias)
//    }
//}
//
//extension Model {
//    public static var name: DatabaseQuery.Schema {
//        .schema(self.schema, alias: nil)
//    }
//}
