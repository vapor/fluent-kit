public protocol SequenceInitializeable: Collection {
    init<Source>(_ source: Source) where Element == Source.Element, Source: Sequence
}

extension Array: SequenceInitializeable { }
extension Set: SequenceInitializeable { }
