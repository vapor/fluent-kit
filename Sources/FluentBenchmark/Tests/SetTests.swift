import FluentKit
import Foundation
import NIOCore
import XCTest

extension FluentBenchmarker {
    public func testSet() throws {
        try self.testSet_multiple()
        try self.testSet_optional()
        try self.testSet_enum()
    }
    
    private func testSet_multiple() throws {
        try runTest(#function, [
            TestMigration(),
        ]) {
            // Int value set first
            try Test.query(on: self.database)
                .set(\.$intValue, to: 1)
                .set(\.$stringValue, to: "a string")
                .update().wait()

            // String value set first
            try Test.query(on: self.database)
                .set(\.$stringValue, to: "a string")
                .set(\.$intValue, to: 1)
                .update().wait()
        }
    }

    private func testSet_optional() throws {
        try runTest(#function, [
            TestMigration(),
        ]) {
            try Test.query(on: self.database)
                .set(\.$intValue, to: nil)
                .set(\.$stringValue, to: nil)
                .update().wait()
        }
    }

    private func testSet_enum() throws {
        try runTest(#function, [
            Test2Migration(),
        ]) {
            try Test2.query(on: self.database)
                .set(\.$foo, to: .bar)
                .update().wait()
        }
    }
}

private final class Test: Model {
    static let schema = "test"

    @ID(key: .id)
    var id: UUID?

    @OptionalField(key: "int_value")
    var intValue: Int?

    @OptionalField(key: "string_value")
    var stringValue: String?
}

private struct TestMigration: FluentKit.Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("test")
            .field("id", .uuid, .identifier(auto: false))
            .field("int_value", .int)
            .field("string_value", .string)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("test").delete()
    }
}

private enum Foo: String, Codable {
    case bar, baz
}

private final class Test2: Model {
    static let schema = "test"

    @ID(key: .id)
    var id: UUID?

    @Enum(key: "foo")
    var foo: Foo
}

private struct Test2Migration: FluentKit.Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.enum("foo").case("bar").case("baz").create().flatMap { foo in
            database.schema("test")
                .id()
                .field("foo", foo)
                .create()
        }
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("test").delete()
    }
}

