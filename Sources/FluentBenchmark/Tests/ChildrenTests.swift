import FluentKit
import Foundation
import NIOCore
import XCTest

extension FluentBenchmarker {
    public func testChildren() throws {
        try self.testChildren_with()
    }

    private func testChildren_with() throws {
        try self.runTest(#function, [
            FooMigration(),
            BarMigration(),
            BazMigration()
        ]) {
            let foo = Foo(name: "a")
            try foo.save(on: self.database).wait()
            let bar = Bar(bar: 42, fooID: foo.id!)
            try bar.save(on: self.database).wait()
            let baz = Baz(baz: 3.14, fooID: foo.id!)
            try baz.save(on: self.database).wait()

            let foos = try Foo.query(on: self.database)
                .with(\.$bars)
                .with(\.$bazs)
                .all().wait()

            for foo in foos {
                XCTAssertEqual(foo.bars[0].bar, 42)
                XCTAssertEqual(foo.bazs[0].baz, 3.14)
            }
        }
    }
}


private final class Foo: Model {
    static let schema = "foos"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Children(for: \.$foo)
    var bars: [Bar]

    @Children(for: \.$foo)
    var bazs: [Baz]

    init() { }

    init(id: IDValue? = nil, name: String) {
        self.id = id
        self.name = name
    }
}

private struct FooMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("foos")
            .field("id", .uuid, .identifier(auto: false))
            .field("name", .string, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("foos").delete()
    }
}

private final class Bar: Model {
    static let schema = "bars"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "bar")
    var bar: Int

    @Parent(key: "foo_id")
    var foo: Foo

    init() { }

    init(id: IDValue? = nil, bar: Int, fooID: Foo.IDValue) {
        self.id = id
        self.bar = bar
        self.$foo.id = fooID
    }
}

private struct BarMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("bars")
            .field("id", .uuid, .identifier(auto: false))
            .field("bar", .int, .required)
            .field("foo_id", .uuid, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("bars").delete()
    }
}

private final class Baz: Model {
    static let schema = "bazs"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "baz")
    var baz: Double

    @Parent(key: "foo_id")
    var foo: Foo

    init() { }

    init(id: IDValue? = nil, baz: Double, fooID: Foo.IDValue) {
        self.id = id
        self.baz = baz
        self.$foo.id = fooID
    }
}

private struct BazMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("bazs")
            .field("id", .uuid, .identifier(auto: false))
            .field("baz", .double, .required)
            .field("foo_id", .uuid, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("bazs").delete()
    }
}
