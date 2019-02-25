import Foundation

extension UUID: ModelID { }
extension Int: ModelID { }

public protocol ModelID: Codable, Hashable { }
