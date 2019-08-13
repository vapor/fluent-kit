//public protocol SoftDeletable: Model, _AnySoftDeletable {
//    var deletedAt: Date? { get set }
//}
//
//public protocol _AnySoftDeletable {
//    var _deletedAtField: Field<Date?> { get }
//    func _excludeSoftDeleted(_ query: inout DatabaseQuery)
//}
//
//extension SoftDeletable {
//    public var _deletedAtField: Field<Date?> {
//        guard let deletedAt = Mirror(reflecting: self).descendant("_deletedAt") else {
//            fatalError("deletedAt must be declared using @Field")
//        }
//        return deletedAt as! Field<Date?>
//    }
//

//}
