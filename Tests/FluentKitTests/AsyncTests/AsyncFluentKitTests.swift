#if compiler(>=5.5) && canImport(_Concurrency)
#if !os(Linux)
import FluentKit
import FluentBenchmark
import XCTest
import Foundation
import FluentSQL
import XCTFluent

@available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
final class AsyncFluentKitTests: XCTestCase {
    override class func setUp() {
        super.setUp()
        XCTAssertTrue(isLoggingConfigured)
    }

    func testGalaxyPlanetSorts() async throws {
        let db = DummyDatabaseForTestSQLSerializer()
        _ = try await Planet.query(on: db).sort(\.$name, .descending).all()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql.contains(#"ORDER BY "planets"."name" DESC"#), true)
        db.reset()

        _ = try await Planet.query(on: db)
            .join(parent: \Planet.$star)
            .sort(Star.self, \.$name, .ascending)
            .all()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql.contains(#"ORDER BY "stars"."name" ASC"#), true)
        db.reset()

        _ = try await Planet.query(on: db).sort(\.$id, .descending).all()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql.contains(#"ORDER BY "planets"."id" DESC"#), true)
        db.reset()

        _ = try await Planet.query(on: db)
            .join(parent: \.$star)
            .sort(Star.self, \.$id, .ascending)
            .all()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql.contains(#"ORDER BY "stars"."id" ASC"#), true)
        db.reset()

        _ = try await Planet.query(on: db).sort("name", .descending).all()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql.contains(#"ORDER BY "planets"."name" DESC"#), true)
        db.reset()

        _ = try await Planet.query(on: db)
            .join(parent: \Planet.$star)
            .sort(Star.self, "name", .ascending)
            .all()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql.contains(#"ORDER BY "stars"."name" ASC"#), true)
        db.reset()
    }

    func testGroupSorts() async throws {
        let db = DummyDatabaseForTestSQLSerializer()
        _ = try await User.query(on: db).sort(\.$pet.$name).all { _ in }
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql.contains(#"ORDER BY "users"."pet_name" ASC"#), true)
        db.reset()

        _ = try await User.query(on: db).sort(\.$pet.$toy.$name, .descending).all { _ in }
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql.contains(#"ORDER BY "users"."pet_toy_name" DESC"#), true)
        db.reset()

        _ = try await User.query(on: db).sort(\.$pet.$toy.$foo.$bar, .ascending).all { _ in }
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql.contains(#"ORDER BY "users"."pet_toy_foo_bar" ASC"#), true)
        db.reset()
    }

    func testJoins() async throws {
        let db = DummyDatabaseForTestSQLSerializer()
        _ = try await Planet.query(on: db).join(child: \Planet.$governor).all()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql.contains(#"INNER JOIN "governors" ON "planets"."id" = "governors"."planet_id"#), true)
        db.reset()

        _ = try await Planet.query(on: db).join(children: \Planet.$moons).all()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql.contains(#"INNER JOIN "moons" ON "planets"."id" = "moons"."planet_id"#), true)
        db.reset()

        _ = try await Planet.query(on: db).join(parent: \Planet.$star).all()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql.contains(#"INNER JOIN "stars" ON "planets"."star_id" = "stars"."id"#), true)
        db.reset()

        _ = try await Planet.query(on: db).join(siblings: \Planet.$tags).all()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql.contains(#"INNER JOIN "planet+tag" ON "planets"."id" = "planet+tag"."planet_id""#), true)
        XCTAssertEqual(db.sqlSerializers.first?.sql.contains(#"INNER JOIN "tags" ON "planet+tag"."tag_id" = "tags"."id""#), true)
        db.reset()
    }

    func testSingleColumnSelect() async throws {
        let db = DummyDatabaseForTestSQLSerializer()

        _ = try await Planet.query(on: db).all(\.$name)
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql, #"SELECT "planets"."name" AS "planets_name" FROM "planets""#)
        db.reset()
    }

    func testSQLDistinct() async throws {
        let db = DummyDatabaseForTestSQLSerializer()

        _ = try await Planet.query(on: db).unique().all(\.$name)
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql, #"SELECT DISTINCT "planets"."name" AS "planets_name" FROM "planets""#)
        db.reset()

        _ = try await Planet.query(on: db).unique().all()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql.starts(with: #"SELECT DISTINCT "planets"."#), true)
        db.reset()

        _ = try await Planet.query(on: db).unique().count(\.$name)
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql, #"SELECT COUNT(DISTINCT("planets"."name")) AS "aggregate" FROM "planets""#)
        db.reset()

        _ = try await Planet.query(on: db).unique().sum(\.$id)
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql, #"SELECT SUM(DISTINCT("planets"."id")) AS "aggregate" FROM "planets""#)
        db.reset()
    }

    func testSQLSchemaCustomIndex() async throws {
        let db = DummyDatabaseForTestSQLSerializer()
        try await db.schema("foo").field(.custom("INDEX i_foo (foo)")).update()
        print(db.sqlSerializers)
    }

    func testRequiredFieldConstraint() async throws {
        let db = DummyDatabaseForTestSQLSerializer()
        try await db.schema("planets")
            .field("id", .int64, .required)
            .create()

        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql, #"CREATE TABLE "planets"("id" BIGINT NOT NULL)"#)
    }

    func testIdentifierFieldConstraint() async throws {
        let db = DummyDatabaseForTestSQLSerializer()
        try await db.schema("planets")
            .field("id", .int64, .identifier(auto: false))
            .create()

        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql, #"CREATE TABLE "planets"("id" BIGINT PRIMARY KEY)"#)
        db.reset()

        try await db.schema("planets")
            .field("id", .int64, .identifier(auto: true))
            .create()

        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql, #"CREATE TABLE "planets"("id" BIGINT PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY)"#)
    }

    func testForeignKeyFieldConstraint() async throws {
        let db = DummyDatabaseForTestSQLSerializer()
        try await db.schema("planets")
            .field("galaxy_id", .int64, .references("galaxies", "id"))
            .create()

        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql, #"CREATE TABLE "planets"("galaxy_id" BIGINT REFERENCES "galaxies" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION)"#)
        db.reset()

        try await db.schema("planets")
            .field("galaxy_id", .int64, .references("galaxies", "id", onDelete: .restrict, onUpdate: .cascade))
            .create()

        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql, #"CREATE TABLE "planets"("galaxy_id" BIGINT REFERENCES "galaxies" ("id") ON DELETE RESTRICT ON UPDATE CASCADE)"#)
    }

    func testMultipleFieldConstraint() async throws {
        let db = DummyDatabaseForTestSQLSerializer()
        try await db.schema("planets")
            .field("id", .int64, .required, .identifier(auto: true))
            .create()

        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql, #"CREATE TABLE "planets"("id" BIGINT NOT NULL PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY)"#)
    }

    func testUniqueTableConstraint() async throws {
        let db = DummyDatabaseForTestSQLSerializer()
        try await db.schema("planets")
            .field("id", .int64)
            .unique(on: "id")
            .create()

        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql, #"CREATE TABLE "planets"("id" BIGINT, CONSTRAINT "uq:planets.id" UNIQUE ("id"))"#)
        db.reset()

        try await db.schema("planets")
            .field("id", .int64)
            .field("name", .string)
            .unique(on: "id", "name")
            .create()

        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql, #"CREATE TABLE "planets"("id" BIGINT, "name" TEXT, CONSTRAINT "uq:planets.id+planets.name" UNIQUE ("id", "name"))"#)
    }

    func testForeignKeyTableConstraint() async throws {
        let db = DummyDatabaseForTestSQLSerializer()
        try await db.schema("planets")
            .field("galaxy_id", .int64)
            .foreignKey("galaxy_id", references: "galaxies", "id")
            .create()

        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql, #"CREATE TABLE "planets"("galaxy_id" BIGINT, CONSTRAINT "fk:planets.galaxy_id+planets.id" FOREIGN KEY ("galaxy_id") REFERENCES "galaxies" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION)"#)
        db.reset()

        try await db.schema("planets")
            .field("galaxy_id", .int64)
            .foreignKey(
                "galaxy_id",
                references: "galaxies", "id",
                onDelete: .restrict,
                onUpdate: .cascade
            )
            .create()

        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql, #"CREATE TABLE "planets"("galaxy_id" BIGINT, CONSTRAINT "fk:planets.galaxy_id+planets.id" FOREIGN KEY ("galaxy_id") REFERENCES "galaxies" ("id") ON DELETE RESTRICT ON UPDATE CASCADE)"#)
    }

    func testIfNotExistsTableCreate() async throws {
        let db = DummyDatabaseForTestSQLSerializer()
        try await db.schema("planets")
            .field("galaxy_id", .int64)
            .ignoreExisting()
            .create()


        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql, #"CREATE TABLE IF NOT EXISTS "planets"("galaxy_id" BIGINT)"#)
        db.reset()

        try await db.schema("planets")
            .field("galaxy_id", .int64)
            .create()


        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql, #"CREATE TABLE "planets"("galaxy_id" BIGINT)"#)
    }

    func testCreateEmptyModelArrayDoesntQuery() async throws {
        let db = DummyDatabaseForTestSQLSerializer()
        try await [Planet2]().create(on: db)
        XCTAssertEqual(db.sqlSerializers.count, 0)
    }

    func testPlanel2FilterPlaceholder1() async throws {
        let db = DummyDatabaseForTestSQLSerializer()
        _ = try await Planet2
            .query(on: db)
            .filter(\.$nickName != "first")
            .count()

        XCTAssertEqual(db.sqlSerializers.count, 1)
        let result: String = (db.sqlSerializers.first?.sql)!
        let expected = #"SELECT COUNT("planets"."id") AS "aggregate" FROM "planets" WHERE "planets"."nickname" <> $1"#
        XCTAssertEqual(result, expected)
        db.reset()
    }

    func testPlanel2FilterPlaceholder2() async throws {
        let db = DummyDatabaseForTestSQLSerializer()
        _ = try await Planet2
            .query(on: db)
            .filter(\.$nickName != nil)
            .count()

        XCTAssertEqual(db.sqlSerializers.count, 1)
        let result: String = (db.sqlSerializers.first?.sql)!
        let expected = #"SELECT COUNT("planets"."id") AS "aggregate" FROM "planets" WHERE "planets"."nickname" IS NOT NULL"#
        XCTAssertEqual(result, expected)
        db.reset()
    }

    func testPlanel2FilterPlaceholder3() async throws {
        let db = DummyDatabaseForTestSQLSerializer()
        _ = try await Planet2
            .query(on: db)
            .filter(\.$nickName != "first")
            .filter(\.$nickName == "second")
            .filter(\.$nickName != "third")
            .count()

        XCTAssertEqual(db.sqlSerializers.count, 1)
        let result: String = (db.sqlSerializers.first?.sql)!
        let expected = #"SELECT COUNT("planets"."id") AS "aggregate" FROM "planets" WHERE "planets"."nickname" <> $1 AND "planets"."nickname" = $2 AND "planets"."nickname" <> $3"#
        XCTAssertEqual(result, expected)
        db.reset()
    }

    func testPlanel2FilterPlaceholder4() async throws {
        let db = DummyDatabaseForTestSQLSerializer()
        _ = try await Planet2
            .query(on: db)
            .filter(\.$nickName != "first")
            .filter(\.$nickName != nil)
            .filter(\.$nickName == "second")
            .count()

        XCTAssertEqual(db.sqlSerializers.count, 1)
        let result: String = (db.sqlSerializers.first?.sql)!
        let expected = #"SELECT COUNT("planets"."id") AS "aggregate" FROM "planets" WHERE "planets"."nickname" <> $1 AND "planets"."nickname" IS NOT NULL AND "planets"."nickname" = $2"#
        XCTAssertEqual(result, expected)
        db.reset()
    }

    func testDatabaseGeneratedIDOverride() async throws {
        final class Foo: Model {
            static let schema = "foos"
            @ID(custom: .id) var id: Int?
            init() { }
            init(id: Int?) {
                self.id = id
            }
        }


        let test = CallbackTestDatabase { query in
            switch query.input[0] {
            case .dictionary(let input):
                switch input["id"] {
                case .bind(let bind):
                    XCTAssertEqual(bind as? Int, 1)
                default:
                    XCTFail("invalid input: \(input)")
                }
            default:
                XCTFail("invalid input: \(query)")
            }
            return [
                TestOutput(["id": 0])
            ]
        }
        let foo = Foo(id: 1)
        try await foo.create(on: test.db)
        XCTAssertEqual(foo.id, 1)
    }

    func testPaginationDoesNotCrashWithNegativeNumbers() async throws {
        let db = DummyDatabaseForTestSQLSerializer()
        let pageRequest1 = PageRequest(page: -1, per: 10)
        _ = try await Planet2
            .query(on: db)
            .paginate(pageRequest1)

        let pageRequest2 = PageRequest(page: 1, per: -10)
        _ = try await Planet2
            .query(on: db)
            .paginate(pageRequest2)
    }
}
#endif
#endif
