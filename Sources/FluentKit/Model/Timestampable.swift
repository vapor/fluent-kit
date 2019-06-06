#warning("TODO: timestampable")
public protocol Timestampable { }
//public protocol Timestampable: Model, _AnyTimestampable {
//    var createdAt: Field<Date?> { get }
//    var updatedAt: Field<Date?> { get }
//}
//
//
//public protocol _AnyTimestampable {
//    func _touchCreated(_ input: inout [String: DatabaseQuery.Value])
//    func _touchUpdated(_ input: inout [String: DatabaseQuery.Value])
//    func _initializeTimestampable(_ input: inout [String: DatabaseQuery.Value])
//}
//
//extension Timestampable {
//    public func _touchCreated(_ input: inout [String: DatabaseQuery.Value]) {
//        let date = Date()
//        input[self.createdAt.name] = .bind(date)
//        input[self.updatedAt.name] = .bind(date)
//    }
//    public func _touchUpdated(_ input: inout [String: DatabaseQuery.Value]) {
//        input[self.updatedAt.name] = .bind(Date())
//    }
//    public func _initializeTimestampable(_ input: inout [String: DatabaseQuery.Value]) {
//        input[self.createdAt.name] = .bind(Date?.none)
//        input[self.updatedAt.name] = .bind(Date?.none)
//    }
//}
