import NIOCore

/// Fluent's `Migration` can handle database migrations, which can include
/// adding new table, changing existing tables or adding
/// seed data. These actions are executed only once.
public protocol Migration: Sendable {
    /// The name of the migration which Fluent uses to track the state of.
    var name: String { get }

    /// Called when a migration is executed.
    /// - Parameters:
    ///     - database: `Database` to run the migration on,
    /// - returns: An asynchronous `Void`.

    func prepare(on database: any Database) async throws

    /// Called when the changes from a migration are reverted.
    /// - Parameters:
    ///     - database: `Database` to revert the migration on.
    /// - returns: An asynchronous `Void`.
    func revert(on database: any Database) async throws
}

extension Migration {
    public var name: String {
        self.defaultName
    }

    var defaultName: String {
        #if compiler(<6.1)
        /// `String.init(reflecting:)` creates a `Mirror` unconditionally, but
        /// when the parameter is a metatype (such as is the case here), that
        /// mirror is never actually used for anything. Unfortunately, just
        /// creating it slows this accessor down by at least 30% at best, and
        /// as much as 50% in some cases. Given that it's already incorrect to
        /// be depending on the stability of `String(reflecting:)`'s output
        /// anyway, it seems to make more sense to just call the underlying
        /// runtime function directly instead of taking the huge speed hit just
        /// because the leading underscore makes it harder to ignore the
        /// fragility of the usage.
        Swift._typeName(Self.self, qualified: true)
        #else
        String(reflecting: Self.self)
        #endif
    }
}
