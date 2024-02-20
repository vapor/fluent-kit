#if compiler(<5.10)
@_silgen_name("swift_reflectionMirror_normalizedType")
internal func _getNormalizedType<T>(_: T, type: Any.Type) -> Any.Type

@_silgen_name("swift_reflectionMirror_count")
internal func _getChildCount<T>(_: T, type: Any.Type) -> Int

@_silgen_name("swift_reflectionMirror_subscript")
internal func _getChild<T>(
  of: T, type: Any.Type, index: Int,
  outName: UnsafeMutablePointer<UnsafePointer<CChar>?>,
  outFreeFunc: UnsafeMutablePointer<(@convention(c) (UnsafePointer<CChar>?) -> Void)?>
) -> Any
#endif

internal struct _FastChildIterator: IteratorProtocol {
    private final class _CStringBox {
        let ptr: UnsafePointer<CChar>
        let freeFunc: (@convention(c) (UnsafePointer<CChar>?) -> Void)
        init(ptr: UnsafePointer<CChar>, freeFunc: @escaping @convention(c) (UnsafePointer<CChar>?) -> Void) {
            self.ptr = ptr
            self.freeFunc = freeFunc
        }
        deinit { self.freeFunc(self.ptr) }
    }
    
#if compiler(<5.10)
    private let subject: AnyObject
    private let type: Any.Type
    private let childCount: Int
    private var index: Int
#else
    private var iterator: Mirror.Children.Iterator
#endif
    private var lastNameBox: _CStringBox?
    
#if compiler(<5.10)
    fileprivate init(subject: AnyObject, type: Any.Type, childCount: Int) {
        self.subject = subject
        self.type = type
        self.childCount = childCount
        self.index = 0
    }
#else
    fileprivate init(iterator: Mirror.Children.Iterator) {
        self.iterator = iterator
    }
#endif
    
    init(subject: AnyObject) {
#if compiler(<5.10)
        let type = _getNormalizedType(subject, type: Swift.type(of: subject))
        self.init(
            subject: subject,
            type: type,
            childCount: _getChildCount(subject, type: type)
        )
#else
        self.init(iterator: Mirror(reflecting: subject).children.makeIterator())
#endif
    }
    
    /// The `name` pointer returned by this iterator has a rather unusual lifetime guarantee - it shall remain valid
    /// until either the proceeding call to `next()` or the end of the iterator's scope. This admittedly bizarre
    /// semantic is a concession to the fact that this entire API is intended to bypass the massive speed penalties of
    /// `Mirror` as much as possible, and copying a name that many callers will never even access to begin with is
    /// hardly a means to that end.
    ///
    /// - Note: Ironically, in the fallback case that uses `Mirror` directly, preserving this semantic actually imposes
    ///   an _additional_ performance penalty.
    mutating func next() -> (name: UnsafePointer<CChar>?, child: Any)? {
#if compiler(<5.10)
        guard self.index < self.childCount else {
            self.lastNameBox = nil // ensure any lingering name gets freed
            return nil
        }

        var nameC: UnsafePointer<CChar>? = nil
        var freeFunc: (@convention(c) (UnsafePointer<CChar>?) -> Void)? = nil
        let child = _getChild(of: self.subject, type: self.type, index: self.index, outName: &nameC, outFreeFunc: &freeFunc)
        
        self.index += 1
        self.lastNameBox = nameC.flatMap { nameC in freeFunc.map { _CStringBox(ptr: nameC, freeFunc: $0) } } // don't make a box if there's no name or no free function to call
        return (name: nameC, child: child)
#else
        guard let child = self.iterator.next() else {
            self.lastNameBox = nil
            return nil
        }
        if var label = child.label {
            let nameC = label.withUTF8 {
                let buf = UnsafeMutableBufferPointer<CChar>.allocate(capacity: $0.count + 1)
                buf.initialize(repeating: 0)
                _ = $0.withMemoryRebound(to: CChar.self) { buf.update(fromContentsOf: $0) }
                return buf.baseAddress!
            }
            self.lastNameBox = _CStringBox(ptr: UnsafePointer(nameC), freeFunc: { $0?.deallocate() })
            return (name: UnsafePointer(nameC), child: child.value)
        } else {
            self.lastNameBox = nil
            return (name: nil, child: child.value)
        }
#endif
    }
}

internal struct _FastChildSequence: Sequence {
#if compiler(<5.10)
    private let subject: AnyObject
    private let type: Any.Type
    private let childCount: Int
#else
    private let children: Mirror.Children
#endif

    init(subject: AnyObject) {
#if compiler(<5.10)
        self.subject = subject
        self.type = _getNormalizedType(subject, type: Swift.type(of: subject))
        self.childCount = _getChildCount(subject, type: self.type)
#else
        self.children = Mirror(reflecting: subject).children
#endif
    }
    
    func makeIterator() -> _FastChildIterator {
#if compiler(<5.10)
        return _FastChildIterator(subject: self.subject, type: self.type, childCount: self.childCount)
#else
        return _FastChildIterator(iterator: self.children.makeIterator())
#endif
    }
}
