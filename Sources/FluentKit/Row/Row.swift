protocol AnyRow: class {
    var model: AnyModel.Type { get }
    var storage: Storage { get set }
}
