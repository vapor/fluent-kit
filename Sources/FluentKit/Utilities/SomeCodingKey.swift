import SQLKit

extension SQLKit.SomeCodingKey {
    public var description: String {
        "SomeCodingKey(\"\(self.stringValue)\"\(self.intValue.map { ", int: \($0)" } ?? ""))"
    }
}
