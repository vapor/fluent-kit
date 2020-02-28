protocol AnyID {
    func generate()
    var exists: Bool { get set }
    var cachedOutput: DatabaseOutput? { get set }
}
