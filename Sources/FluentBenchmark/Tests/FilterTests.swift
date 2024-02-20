import FluentKit
import Foundation
import NIOCore
import XCTest
import FluentSQL

extension FluentBenchmarker {
    public func testFilter(sql: Bool = true) throws {
        try self.testFilter_field()
        if sql {
            try self.testFilter_sqlValue()
            try self.testFilter_sqlEmbedValue()
            try self.testFilter_sqlEmbedField()
            try self.testFilter_sqlEmbedFilter()
        }
        try self.testFilter_group()
        try self.testFilter_emptyGroup()
        try self.testFilter_emptyRightHandSide()
        try self.testFilter_optionalStringContains()
        try self.testFilter_enum()
        try self.testFilter_joinedEnum()
        try self.testFilter_joinedAliasedEnum()
    }

    private func testFilter_field() throws {
        try self.runTest(#function, [
            SolarSystem()
        ]) {
            let equalNumbers = try Moon.query(on: self.database)
                .filter(\.$craters == \.$comets).all().wait()
            XCTAssertEqual(equalNumbers.count, 7)
            let moreCraters = try Moon.query(on: self.database)
                .filter(\.$craters > \.$comets).all()
                .wait()
            XCTAssertEqual(moreCraters.count, 3)
            let moreComets = try Moon.query(on: self.database)
                .filter(\.$craters < \.$comets)
                .all().wait()
            XCTAssertEqual(moreComets.count, 1)
        }
    }

    private func testFilter_sqlValue() throws {
        try self.runTest(#function, [
            SolarSystem()
        ]) {
            let moon = try Moon.query(on: self.database)
                .filter(\.$name == .sql(raw: "'Moon'"))
                .first()
                .wait()

            XCTAssertNotNil(moon)
            XCTAssertEqual(moon?.name, "Moon")
        }
    }

    private func testFilter_sqlEmbedValue() throws {
        try self.runTest(#function, [
            SolarSystem()
        ]) {
            let moon = try Moon.query(on: self.database)
                .filter(\.$name == .sql(embed: "\(literal: "Moon")"))
                .first()
                .wait()

            XCTAssertNotNil(moon)
            XCTAssertEqual(moon?.name, "Moon")
        }
    }

    private func testFilter_sqlEmbedField() throws {
        try self.runTest(#function, [
            SolarSystem()
        ]) {
            let moon = try Moon.query(on: self.database)
                .filter(.sql(embed: "\(ident: "name")"), .equal, .bind("Moon"))
                .first()
                .wait()

            XCTAssertNotNil(moon)
            XCTAssertEqual(moon?.name, "Moon")
        }
    }

    private func testFilter_sqlEmbedFilter() throws {
        try self.runTest(#function, [
            SolarSystem()
        ]) {
            let moon = try Moon.query(on: self.database)
                .filter(.sql(embed: "\(ident: "name")=\(literal: "Moon")"))
                .first()
                .wait()

            XCTAssertNotNil(moon)
            XCTAssertEqual(moon?.name, "Moon")
        }
    }

    private func testFilter_group() throws {
        try self.runTest(#function, [
            SolarSystem()
        ]) {
            let planets = try Planet.query(on: self.database)
                .group(.or) {
                    $0.filter(\.$name == "Earth")
                        .filter(\.$name == "Mars")
                }
                .sort(\.$name)
                .all().wait()

            switch planets.count {
            case 2:
                XCTAssertEqual(planets[0].name, "Earth")
                XCTAssertEqual(planets[1].name, "Mars")
            default:
                XCTFail("Unexpected planets count: \(planets.count)")
            }
        }
    }

    private func testFilter_emptyGroup() throws {
        try self.runTest(#function, [
            SolarSystem()
        ]) {
            let planets = try Planet.query(on: self.database)
                .group(.or) { _ in }
                .all().wait()
            XCTAssertEqual(planets.count, 9)
        }
    }

    // https://github.com/vapor/fluent-kit/issues/257
    private func testFilter_emptyRightHandSide() throws {
        try self.runTest(#function, [
            SolarSystem()
        ]) {
            guard let correctUUID = try Planet.query(on: self.database).first().wait()?.id else {
                XCTFail("Cannot get UUID to test against")
                return
            }

            let firstQuery = try Planet.query(on: self.database).filter(\.$id ~~ [correctUUID]).filter(\.$id !~ []).count().wait()
            XCTAssertEqual(firstQuery, 1)

            let secondQuery = try Planet.query(on: self.database).filter(\.$id ~~ []).filter(\.$id !~ [correctUUID]).count().wait()
            XCTAssertEqual(secondQuery, 0)
        }
    }

    private func testFilter_optionalStringContains() throws {
        try self.runTest(#function, [
            FooOwnerMigration(),
            FooEnumMigration(),
            FooMigration()
        ]) {
            try Foo(bar: "foo").create(on: self.database).wait()
            try Foo(bar: "bar").create(on: self.database).wait()
            try Foo(bar: "baz").create(on: self.database).wait()
            let foos = try Foo.query(on: self.database)
                .filter(\.$bar ~~ "ba")
                .all()
                .wait()
            XCTAssertEqual(foos.count, 2)
        }
    }

    private func testFilter_enum() throws {
        try self.runTest(#function, [
            FooOwnerMigration(),
            FooEnumMigration(),
            FooMigration()
        ]) {
            try Foo(bar: "foo1", type: .foo).create(on: self.database).wait()
            try Foo(bar: "foo2", type: .foo).create(on: self.database).wait()
            try Foo(bar: "baz", type: .baz).create(on: self.database).wait()
            let foos = try Foo.query(on: self.database)
                .filter(\.$type == .foo)
                .all()
                .wait()
            XCTAssertEqual(foos.count, 2)
            let bazs = try Foo.query(on: self.database)
                .filter(\.$type == .baz)
                .all()
                .wait()
            XCTAssertEqual(bazs.count, 1)
        }
    }

    private func testFilter_joinedEnum() throws {
        try self.runTest(#function, [
            FooOwnerMigration(),
            FooEnumMigration(),
            FooMigration()
        ]) {
            let fooOwner = FooOwner(name: "foo_owner")
            try fooOwner.create(on: self.database).wait()

            let barOwner = FooOwner(name: "bar_owner")
            try barOwner.create(on: self.database).wait()

            let bazOwner = FooOwner(name: "baz_owner")
            try bazOwner.create(on: self.database).wait()

            try Foo(bar: "foo", type: .foo, ownerID: fooOwner.requireID()).create(on: self.database).wait()
            try Foo(bar: "bar", type: .bar, ownerID: barOwner.requireID()).create(on: self.database).wait()
            try Foo(bar: "baz", type: .baz, ownerID: bazOwner.requireID()).create(on: self.database).wait()

            let foos = try FooOwner.query(on: self.database)
                .join(Foo.self, on: \FooOwner.$id == \Foo.$owner.$id)
                .filter(Foo.self, \.$type == .foo)
                .all()
                .wait()

            XCTAssertEqual(foos.count, 1)
            XCTAssertEqual(foos.first?.name, "foo_owner")
        }
    }

    private func testFilter_joinedAliasedEnum() throws {
        try self.runTest(#function, [
            FooOwnerMigration(),
            FooEnumMigration(),
            FooMigration()
        ]) {
            let fooOwner = FooOwner(name: "foo_owner")
            try fooOwner.create(on: self.database).wait()

            let barOwner = FooOwner(name: "bar_owner")
            try barOwner.create(on: self.database).wait()

            let bazOwner = FooOwner(name: "baz_owner")
            try bazOwner.create(on: self.database).wait()

            try Foo(bar: "foo", type: .foo, ownerID: fooOwner.requireID()).create(on: self.database).wait()
            try Foo(bar: "bar", type: .bar, ownerID: barOwner.requireID()).create(on: self.database).wait()
            try Foo(bar: "baz", type: .baz, ownerID: bazOwner.requireID()).create(on: self.database).wait()

            let bars = try FooOwner.query(on: self.database)
                .join(FooAlias.self, on: \FooOwner.$id == \FooAlias.$owner.$id)
                .filter(FooAlias.self, \.$type == .bar)
                .all()
                .wait()

            XCTAssertEqual(bars.count, 1)
            XCTAssertEqual(bars.first?.name, "bar_owner")
        }
    }
}

private final class FooOwner: Model {
    static let schema = "foo_owners"
    @ID var id: UUID?
    @Field(key: "name") var name: String
    init() {}
    init(name: String) {
        self.name = name
    }
}

private enum FooEnumType: String, Codable {
    case foo
    case bar
    case baz
}

private final class Foo: Model {
    static let schema = "foos"
    @ID var id: UUID?
    @OptionalField(key: "bar") var bar: String?
    @OptionalEnum(key: "type") var type: FooEnumType?
    @OptionalParent(key: "owner_id") var owner: FooOwner?
    init() {}
    init(bar: String? = nil, type: FooEnumType? = nil, ownerID: UUID? = nil) {
        self.bar = bar
        self.type = type
        self.$owner.id = ownerID
    }
}

private final class FooAlias: ModelAlias {
    static let name = "foos_alias"
    let model = Foo()
}

private struct FooEnumMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.enum("foo_type")
            .case("foo")
            .case("bar")
            .case("baz")
            .create()
            .transform(to: ())
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.enum("foo_type").delete()
    }
}

private struct FooOwnerMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("foo_owners")
            .id()
            .field("name", .string, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("foo_owners").delete()
    }
}

private struct FooMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.enum("foo_type").read().flatMap { fooType in
            database.schema("foos")
                .id()
                .field("bar", .string)
                .field("type", fooType)
                .field("owner_id", .uuid, .references(FooOwner.schema, .id, onDelete: .setNull))
                .create()
        }
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("foos").delete()
    }
}
