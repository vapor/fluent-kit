import FluentKit
import Foundation
import NIOCore
import FluentSQL
import SQLKit
import XCTest

extension FluentBenchmarker {
    public func testChild() throws {
        try self.testChild_with()
        
        guard let sql = self.database as? SQLDatabase else {
            return
        }
        try self.testChild_sqlIdInt(sql)
        
    }

    private func testChild_with() throws {
        try self.runTest(#function, [
            FooMigration(),
            BarMigration(),
            BazMigration()
        ]) {
            let foo = Foo(name: "a")
            try foo.save(on: self.database).wait()
            let bar = Bar(bar: 42, fooID: foo.id!)
            try bar.save(on: self.database).wait()
            let baz = Baz(baz: 3.14)
            try baz.save(on: self.database).wait()
            
            // Test relationship @Parent - @OptionalChild
            // query(on: Parent)
            let foos = try Foo.query(on: self.database)
                .with(\.$bar)
                .with(\.$baz)
                .all().wait()

            for foo in foos {
                // Child `bar` is eager loaded
                XCTAssertEqual(foo.bar?.bar, 42)
                // Child `baz` isn't eager loaded
                XCTAssertNil(foo.baz?.baz)
            }
            
            // Test relationship @Parent - @OptionalChild
            // query(on: Child)
            let bars = try Bar.query(on: self.database)
                .with(\.$foo)
                .all().wait()
            
            for bar in bars {
                XCTAssertEqual(bar.foo.name, "a")
            }
            
            // Test relationship @OptionalParent - @OptionalChild
            // query(on: Child)
            let bazs = try Baz.query(on: self.database)
                .with(\.$foo)
                .all().wait()
            
            for baz in bazs {
                // test with missing parent
                XCTAssertNil(baz.foo?.name)
            }
            
            baz.$foo.id = foo.id
            try baz.save(on: self.database).wait()
            
            let updatedBazs = try Baz.query(on: self.database)
                .with(\.$foo)
                .all().wait()
            
            for updatedBaz in updatedBazs {
                // test with valid parent
                XCTAssertEqual(updatedBaz.foo?.name, "a")
            }
        }
    }
    
    private func testChild_sqlIdInt(_ sql: SQLDatabase) throws {
        try self.runTest(#function, [
            GameMigration(),
            PlayerMigration()
        ]) {
            let game = Game(title: "Solitare")
            try game.save(on: self.database).wait()
            
            let frantisek = Player(name: "Frantisek", gameID: game.id!)
            try frantisek.save(on: self.database).wait()
            
            
            let player = try Player.query(on: self.database)
                .with(\.$game)
                .first().wait()
            
            XCTAssertNotNil(player)
            if let player = player {
                XCTAssertEqual(player.id, frantisek.id)
                XCTAssertEqual(player.name, frantisek.name)
                XCTAssertEqual(player.$game.id, frantisek.$game.id)
                XCTAssertEqual(player.$game.id, game.id)
                
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

    @OptionalChild(for: \.$foo)
    var bar: Bar?

    @OptionalChild(for: \.$foo)
    var baz: Baz?

    init() { }

    init(id: IDValue? = nil, name: String) {
        self.id = id
        self.name = name
    }
}

private struct FooMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Foo.schema)
            .field(.id, .uuid, .identifier(auto: false), .required)
            .field("name", .string, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Foo.schema).delete()
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
        database.schema(Bar.schema)
            .field(.id, .uuid, .identifier(auto: false), .required)
            .field("bar", .int, .required)
            .field("foo_id", .uuid, .required)
            .unique(on: "foo_id")
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Bar.schema).delete()
    }
}

private final class Baz: Model {
    static let schema = "bazs"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "baz")
    var baz: Double

    @OptionalParent(key: "foo_id")
    var foo: Foo?

    init() { }

    init(id: IDValue? = nil, baz: Double, fooID: Foo.IDValue? = nil) {
        self.id = id
        self.baz = baz
        self.$foo.id = fooID
    }
}

private struct BazMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Baz.schema)
            .field(.id, .uuid, .identifier(auto: false), .required)
            .field("baz", .double, .required)
            .field("foo_id", .uuid)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Baz.schema).delete()
    }
}

private final class Game: Model {
    static let schema = "games"

    @ID(custom: .id, generatedBy: .database)
    var id: Int?

    @Field(key: "title")
    var title: String

    // It's a solitare game :P
    @OptionalChild(for: \.$game)
    var player: Player?
    
    init() { }

    init(
        id: Int? = nil,
        title: String
    ) {
        self.id = id
        self.title = title
    }
}

private struct GameMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Game.schema)
            .field(.id, .int, .identifier(auto: true), .required)
            .field("title", .string, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Game.schema).delete()
    }
}

private final class Player: Model {
    static let schema = "players"

    @ID(custom: .id, generatedBy: .database)
    var id: Int?

    @Field(key: "name")
    var name: String

    @Parent(key: "game_id")
    var game: Game

    init() { }

    init(
        id: Int? = nil,
        name: String, gameID: Game.IDValue) {
        self.id = id
        self.name = name
        self.$game.id = gameID
    }
}

private struct PlayerMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Player.schema)
            .field(.id, .int, .identifier(auto: true), .required)
            .field("name", .string, .required)
            .field("game_id", .int, .required)
            .unique(on: "game_id")
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Player.schema).delete()
    }
}
