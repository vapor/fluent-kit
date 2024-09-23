/// Common definitions for ``SQLQueryBuilder``s which support retrieving result rows.
public protocol SQLQueryFetcher: SQLQueryBuilder {}

// MARK: - First

extension SQLQueryFetcher {
    /// Returns the named column from the first output row, if any, decoded as a given type.
    ///
    /// - Parameters:
    ///   - column: The name of the column to decode.
    ///   - type: The type of the desired value.
    /// - Returns: The decoded value, if any.
    @inlinable
    public func first<D: Decodable>(decodingColumn column: String, as type: D.Type) async throws -> D? {
        try await self.first()?.decode(column: column, as: D.self)
    }

    /// Using a default-configured ``SQLRowDecoder``, returns the first output row, if any, decoded as a given type.
    ///
    /// - Parameter type: The type of the desired value.
    /// - Returns: The decoded value, if any.
    @inlinable
    public func first<D: Decodable>(decoding type: D.Type) async throws -> D? {
        try await self.first(decoding: D.self, with: .init())
    }

    /// Configure a new ``SQLRowDecoder`` as specified and use it to decode and return the first output row, if any,
    /// as a given type.
    /// 
    /// - Parameters:
    ///   - type: The type of the desired value.
    ///   - prefix: See ``SQLRowDecoder/prefix``.
    ///   - keyDecodingStrategy: See ``SQLRowDecoder/keyDecodingStrategy-swift.property``.
    ///   - userInfo: See ``SQLRowDecoder/userInfo``.
    /// - Returns: The decoded value, if any.
    @inlinable
    public func first<D: Decodable>(
        decoding type: D.Type,
        prefix: String? = nil,
        keyDecodingStrategy: SQLRowDecoder.KeyDecodingStrategy = .useDefaultKeys,
        userInfo: [CodingUserInfoKey: any Sendable] = [:]
    ) async throws -> D? {
        try await self.first(decoding: D.self, with: .init(prefix: prefix, keyDecodingStrategy: keyDecodingStrategy, userInfo: userInfo))
    }

    /// Using the given ``SQLRowDecoder``, returns the first output row, if any, decoded as a given type.
    ///
    /// - Parameters:
    ///   - type: The type of the desired value.
    ///   - decoder: A configured ``SQLRowDecoder`` to use.
    /// - Returns: The decoded value, if any.
    @inlinable
    public func first<D: Decodable>(decoding type: D.Type, with decoder: SQLRowDecoder) async throws -> D? {
        try await self.first()?.decode(model: D.self, with: decoder)
    }

    /// Returns the first output row, if any.
    /// 
    /// If `self` conforms to ``SQLPartialResultBuilder``, ``SQLPartialResultBuilder/limit(_:)`` is used to avoid
    /// loading more rows than necessary from the database.
    ///
    /// - Returns: The first output row, if any.
    @inlinable
    public func first() async throws -> (any SQLRow)? {
        (self as? any SQLPartialResultBuilder)?.limit(1)
        nonisolated(unsafe) var rows = [any SQLRow]()
        try await self.run { if rows.isEmpty { rows.append($0) } }
        return rows.first
    }
}

// MARK: - All

extension SQLQueryFetcher {
    /// Returns the named column from each output row, if any, decoded as a given type.
    ///
    /// - Parameters:
    ///   - column: The name of the column to decode.
    ///   - type: The type of the desired values.
    /// - Returns: The decoded values, if any.
    @inlinable
    public func all<D: Decodable>(decodingColumn column: String, as type: D.Type) async throws -> [D] {
        try await self.all().map { try $0.decode(column: column, as: D.self) }
    }

    /// Using a default-configured ``SQLRowDecoder``, returns all output rows, if any, decoded as a given type.
    ///
    /// - Parameter type: The type of the desired values.
    /// - Returns: The decoded values, if any.
    @inlinable
    public func all<D: Decodable>(decoding type: D.Type) async throws -> [D] {
        try await self.all(decoding: D.self, with: .init())
    }
    
    /// Configure a new ``SQLRowDecoder`` as specified and use it to decode and return the output rows, if any,
    /// as a given type.
    /// 
    /// - Parameters:
    ///   - type: The type of the desired values.
    ///   - prefix: See ``SQLRowDecoder/prefix``.
    ///   - keyDecodingStrategy: See ``SQLRowDecoder/keyDecodingStrategy-swift.property``.
    ///   - userInfo: See ``SQLRowDecoder/userInfo``.
    /// - Returns: The decoded values, if any.
    @inlinable
    public func all<D: Decodable>(
        decoding type: D.Type,
        prefix: String? = nil,
        keyDecodingStrategy: SQLRowDecoder.KeyDecodingStrategy = .useDefaultKeys,
        userInfo: [CodingUserInfoKey: any Sendable] = [:]
    ) async throws -> [D] {
        try await self.all(decoding: D.self, with: .init(prefix: prefix, keyDecodingStrategy: keyDecodingStrategy, userInfo: userInfo))
    }

    /// Using the given ``SQLRowDecoder``, returns the output rows, if any, decoded as a given type.
    ///
    /// - Parameters:
    ///   - type: The type of the desired values.
    ///   - decoder: A configured ``SQLRowDecoder`` to use.
    /// - Returns: The decoded values, if any.
    @inlinable
    public func all<D: Decodable>(decoding type: D.Type, with decoder: SQLRowDecoder) async throws -> [D] {
        try await self.all().map { try $0.decode(model: D.self, with: decoder) }
    }

    /// Returns all output rows, if any.
    ///
    /// - Returns: The output rows, if any.
    @inlinable
    public func all() async throws -> [any SQLRow] {
        nonisolated(unsafe) var rows = [any SQLRow]()
        try await self.run { rows.append($0) }
        return rows
    }
}

// MARK: - Run

extension SQLQueryFetcher {
    /// Using a default-configured ``SQLRowDecoder``, call the provided handler closure with the result of decoding
    /// each output row, if any, as a given type.
    ///
    /// - Parameters:
    ///   - type: The type of the desired values.
    ///   - handler: A closure which receives the result of each decoding operation, row by row.
    /// - Returns: A completion future.
    @inlinable
    public func run<D: Decodable>(decoding type: D.Type, _ handler: @escaping @Sendable (Result<D, any Error>) -> ()) async throws {
        try await self.run(decoding: D.self, with: .init(), handler)
    }
    
    /// Configure a new ``SQLRowDecoder`` as specified, use it to to decode each output row, if any, as a given type,
    /// and call the provided handler closure with each decoding result.
    ///
    /// - Parameters:
    ///   - type: The type of the desired values.
    ///   - prefix: See ``SQLRowDecoder/prefix``.
    ///   - keyDecodingStrategy: See ``SQLRowDecoder/keyDecodingStrategy-swift.property``.
    ///   - userInfo: See ``SQLRowDecoder/userInfo``.
    ///   - handler: A closure which receives the result of each decoding operation, row by row.
    /// - Returns: A completion future.
    @inlinable
    public func run<D: Decodable>(
        decoding type: D.Type,
        prefix: String? = nil,
        keyDecodingStrategy: SQLRowDecoder.KeyDecodingStrategy = .useDefaultKeys,
        userInfo: [CodingUserInfoKey: any Sendable] = [:],
        _ handler: @escaping @Sendable (Result<D, any Error>) -> ()
    ) async throws {
        try await self.run(decoding: D.self, with: .init(prefix: prefix, keyDecodingStrategy: keyDecodingStrategy, userInfo: userInfo), handler)
    }

    /// Using the given ``SQLRowDecoder``, call the provided handler closure with the result of decoding each output
    /// row, if any, as a given type.
    ///
    /// - Parameters:
    ///   - type: The type of the desired values.
    ///   - decoder: A configured ``SQLRowDecoder`` to use.
    ///   - handler: A closure which receives the result of each decoding operation, row by row.
    /// - Returns: A completion future.
    @inlinable
    public func run<D: Decodable>(
        decoding type: D.Type,
        with decoder: SQLRowDecoder,
        _ handler: @escaping @Sendable (Result<D, any Error>) -> ()
    ) async throws {
        try await self.run { row in handler(.init { try row.decode(model: D.self, with: decoder) }) }
    }

    /// Run the query specified by the builder, calling the provided handler closure with each output row, if any, as
    /// it is received.
    ///
    /// - Parameter handler: A closure which receives each output row one at a time.
    /// - Returns: A completion future.
    @inlinable
    public func run(_ handler: @escaping @Sendable (any SQLRow) -> ()) async throws {
        try await self.database.execute(sql: self.query, handler)
    }
}
