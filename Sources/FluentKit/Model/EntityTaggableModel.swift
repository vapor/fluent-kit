/// A `Model` which includes an eTag
public protocol EntityTaggableModel: Model {
    /// The eTag in the database
    var eTag: String { get set }

    /// Should generate the eTag for the given `Model`. The default generates a `UUID`.
    func generateETag() -> String
}

public extension EntityTaggableModel {
    var _$eTag: Field<String> {
        guard let mirror = Mirror(reflecting: self).descendant("_eTag"),
            let field = mirror as? Field<String> else {
                fatalError("eTag property must be declared using @Field")
        }

        return field
    }

    func generateETag() -> String {
        return "\"\(UUID().uuidString)\""
    }
}


