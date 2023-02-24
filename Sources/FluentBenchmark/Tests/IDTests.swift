import FluentKit
import Foundation
import NIOCore
import XCTest

extension FluentBenchmarker {
    public func testID(
        autoincrement: Bool = true,
        custom: Bool = true
    ) throws {
        try self.testID_default()
        if custom {
            try self.testID_string()
        }
        if autoincrement {
            try self.testID_autoincrementing()
        }
        if custom && autoincrement {
            try self.testID_customAutoincrementing()
        }
    }

    private func testID_default() throws {
        try self.runTest(#function, [
            FooMigration()
        ]) {
            let foo1 = Foo()
            try foo1.save(on: self.database).wait()
            XCTAssertNotNil(foo1.id)
            let foo2 = Foo(id: nil)
            try foo2.save(on: self.database).wait()
            XCTAssertNotNil(foo2.id)
            XCTAssertNotEqual(foo1.id, foo2.id)
        }
    }

    private func testID_string() throws {
        try self.runTest(#function, [
            StringFooMigration()
        ]) {
            let foo1 = StringFoo(id: "a")
            try foo1.save(on: self.database).wait()
            XCTAssertEqual(foo1.id, "a")
            let foo2 = StringFoo(id: "b")
            try foo2.save(on: self.database).wait()
            XCTAssertEqual(foo2.id, "b")
        }
    }

    private func testID_autoincrementing() throws {
        try self.runTest(#function, [
            AutoincrementingFooMigration()
        ]) {
            let foo1 = AutoincrementingFoo()
            try foo1.save(on: self.database).wait()
            XCTAssertEqual(foo1.id, 1)
            let foo2 = AutoincrementingFoo(id: nil)
            try foo2.save(on: self.database).wait()
            XCTAssertEqual(foo2.id, 2)
        }
    }


    private func testID_customAutoincrementing() throws {
        try self.runTest(#function, [
            CustomAutoincrementingFooMigration()
        ]) {
            let foo1 = CustomAutoincrementingFoo()
            try foo1.save(on: self.database).wait()
            XCTAssertEqual(foo1.id, 1)
            let foo2 = CustomAutoincrementingFoo(id: nil)
            try foo2.save(on: self.database).wait()
            XCTAssertEqual(foo2.id, 2)
        }
    }
}

// Model recommended, default @ID configuration.
private final class Foo: Model {
    static let schema = "foos"

    @ID
    var id: UUID?

    init() { }

    init(id: UUID? = nil) {
        self.id = id
    }
}
private struct FooMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("foos")
            .id()
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("foos").delete()
    }
}

// Model with custom id key and type.
private final class StringFoo: Model {
    static let schema = "foos"

    @ID(custom: .id, generatedBy: .user)
    var id: String?

    init() { }

    init(id: String) {
        self.id = id
    }
}
private struct StringFooMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("foos")
            .field(.id, .string, .identifier(auto: false))
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("foos").delete()
    }
}

// Model with auto-incrementing id.
private final class AutoincrementingFoo: Model {
    static let schema = "foos"

    @ID(custom: .id, generatedBy: .database)
    var id: Int?

    init() { }

    init(id: Int? = nil) {
        self.id = id
    }
}
private struct AutoincrementingFooMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("foos")
            .field(.id, .int, .identifier(auto: true))
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("foos").delete()
    }
}

// Model with auto-incrementing and custom key.
private final class CustomAutoincrementingFoo: Model {
    static let schema = "foos"

    @ID(custom: "bar", generatedBy: .database)
    var id: Int?

    init() { }

    init(id: Int? = nil) {
        self.id = id
    }
}

private struct CustomAutoincrementingFooMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("foos")
            .field("bar", .int, .identifier(auto: true))
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("foos").delete()
    }
}
