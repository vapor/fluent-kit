struct UnsafeTransfer<Wrapped>: @unchecked Sendable {
    var wrappedValue: Wrapped
}

#if swift(<5.10)
@usableFromInline
final class UnsafeMutableTransferBox<Wrapped>: @unchecked Sendable {
    @usableFromInline
    var wrappedValue: Wrapped
    
    @inlinable
    init(_ wrappedValue: Wrapped) {
        self.wrappedValue = wrappedValue
    }
}
#endif
