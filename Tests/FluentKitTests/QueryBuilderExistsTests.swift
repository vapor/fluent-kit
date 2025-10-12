//===----------------------------------------------------------------------===//
//
// This source file is part of the Vapor open source project
//
// SPDX-License-Identifier: MIT
//
//===----------------------------------------------------------------------===//

import XCTest
import FluentKit
import FluentSQLiteDriver
import NIOCore

final class QueryBuilderExistsTests: XCTestCase {
    private var db: Database!

    override func setUp() async throws {
        let app = Application(.testing)
        app.databases.use(.sqlite(.memory), as: .sqlite, isDefault: true)

        app.migrations.add(CreateTodo())
        try await app.autoMigrate()

        // Store the default DB for convenience
        self.db = app.db
    }

    override func tearDown() async throws {
        try await self.db.eventLoop.flatten()
    }

    func testExistsFalseOnEmpty() async throws {
        let exists = try await Todo.query(on: self.db).exists()
        XCTAssertFalse(exists, "No rows in table, exists() should be false")
    }

    func testExistsTrueWhenRowPresent() async throws {
        let _ = Todo(title: "first").save(on: self.db)
        _ = try await self.db.eventLoop.makeSucceededVoidFuture().get()

        let exists = try await Todo.query(on: self.db).exists()
        XCTAssertTrue(exists, "Row present, exists() should be true")
    }

    func testExistsWithPredicate() async throws {
        try await Todo(title: "keep").save(on: self.db)
        try await Todo(title: "other").save(on: self.db)

        let existsKeep = try await Todo.query(on: self.db).exists { $0.filter(\.$title == "keep") }
        XCTAssertTrue(existsKeep)

        let existsNone = try await Todo.query(on: self.db).exists { $0.filter(\.$title == "missing") }
        XCTAssertFalse(existsNone)
    }
}

// MARK: - Test Model & Migration

final class Todo: Model, @unchecked Sendable {
    static let schema = "todos"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "title")
    var title: String

    init() {}
    init(id: UUID? = nil, title: String) {
        self.id = id
        self.title = title
    }
}

struct CreateTodo: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Todo.schema)
            .id()
            .field("title", .string, .required)
            .create()
    }
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Todo.schema).delete()
    }
}
