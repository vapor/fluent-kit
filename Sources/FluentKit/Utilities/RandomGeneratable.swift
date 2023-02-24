import Foundation

public protocol RandomGeneratable {
    static func generateRandom() -> Self
}

extension UUID: RandomGeneratable {
    public static func generateRandom() -> UUID {
        .init()
    }
}
