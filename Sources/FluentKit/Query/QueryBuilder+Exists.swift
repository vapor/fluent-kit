//===----------------------------------------------------------------------===//
//
// This source file is part of the Vapor open source project
//
// SPDX-License-Identifier: MIT
//
//===----------------------------------------------------------------------===//

import NIOCore

extension QueryBuilder {
    /// Returns true if the query would return at least one row.
    ///
    /// This performs an efficient check by applying `LIMIT 1` and trying to fetch
    /// the first result, avoiding a full `COUNT(*)` scan across backends.
    ///
    /// - Returns: `true` when at least one row matches; otherwise `false`.
    @inlinable
    public func exists() async throws -> Bool {
        var qb = self
        qb.limit(1)
        return try await qb.first() != nil
    }

    /// Returns true if *any* row exists that matches the additional filter.
    ///
    /// This is shorthand for `filter(...).exists()`.
    ///
    /// - Parameter predicate: A closure that can apply additional filters to the builder.
    /// - Returns: `true` when at least one row matches; otherwise `false`.
    @inlinable
    public func exists(_ predicate: (inout QueryBuilder<Model>) -> Void) async throws -> Bool {
        var qb = self
        predicate(&qb)
        qb.limit(1)
        return try await qb.first() != nil
    }
}
