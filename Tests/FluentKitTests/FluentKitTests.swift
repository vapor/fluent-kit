import FluentKit
import FluentBenchmark
import XCTest
import Foundation
import FluentSQL
import XCTFluent

final class FluentKitTests: XCTestCase {
    override class func setUp() {
        super.setUp()
        XCTAssertTrue(isLoggingConfigured)
    }
    
    func testMigrationLogNames() throws {
        XCTAssertEqual(MigrationLog.path(for: \.$id), [.id])
        XCTAssertEqual(MigrationLog.path(for: \.$name), ["name"])
        XCTAssertEqual(MigrationLog.path(for: \.$batch), ["batch"])
        XCTAssertEqual(MigrationLog.path(for: \.$createdAt), ["created_at"])
        XCTAssertEqual(MigrationLog.path(for: \.$updatedAt), ["updated_at"])
    }

    func testGalaxyPlanetNames() throws {
        XCTAssertEqual(Galaxy.path(for: \.$id), [.id])
        XCTAssertEqual(Galaxy.path(for: \.$name), ["name"])

        XCTAssertEqual(Planet.path(for: \.$id), [.id])
        XCTAssertEqual(Planet.path(for: \.$name), ["name"])
        XCTAssertEqual(Planet.path(for: \.$star.$id), ["star_id"])
    }

    func testGalaxyPlanetSorts() throws {
        let db = DummyDatabaseForTestSQLSerializer()
        _ = try Planet.query(on: db).sort(\.$name, .descending).all().wait()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql.contains(#"ORDER BY "planets"."name" DESC"#), true)
        db.reset()
        
        _ = try Planet.query(on: db)
            .join(parent: \Planet.$star)
            .sort(Star.self, \.$name, .ascending)
            .all().wait()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql.contains(#"ORDER BY "stars"."name" ASC"#), true)
        db.reset()
        
        _ = try Planet.query(on: db).sort(\.$id, .descending).all().wait()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql.contains(#"ORDER BY "planets"."id" DESC"#), true)
        db.reset()
        
        _ = try Planet.query(on: db)
            .join(parent: \.$star)
            .sort(Star.self, \.$id, .ascending)
            .all().wait()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql.contains(#"ORDER BY "stars"."id" ASC"#), true)
        db.reset()
        
        _ = try Planet.query(on: db).sort("name", .descending).all().wait()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql.contains(#"ORDER BY "planets"."name" DESC"#), true)
        db.reset()
        
        _ = try Planet.query(on: db)
            .join(parent: \Planet.$star)
            .sort(Star.self, "name", .ascending)
            .all().wait()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql.contains(#"ORDER BY "stars"."name" ASC"#), true)
        db.reset()
    }

    func testGroupSorts() throws {
        let db = DummyDatabaseForTestSQLSerializer()
        _ = try User.query(on: db).sort(\.$pet.$name).all { _ in }.wait()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql.contains(#"ORDER BY "users"."pet_name" ASC"#), true)
        db.reset()

        _ = try User.query(on: db).sort(\.$pet.$toy.$name, .descending).all { _ in }.wait()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql.contains(#"ORDER BY "users"."pet_toy_name" DESC"#), true)
        db.reset()

        _ = try User.query(on: db).sort(\.$pet.$toy.$foo.$bar, .ascending).all { _ in }.wait()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql.contains(#"ORDER BY "users"."pet_toy_foo_bar" ASC"#), true)
        db.reset()
    }

    func testJoins() throws {
        let db = DummyDatabaseForTestSQLSerializer()
        _ = try Planet.query(on: db).join(child: \Planet.$governor).all().wait()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql.contains(#"INNER JOIN "governors" ON "planets"."id" = "governors"."planet_id"#), true)
        db.reset()
        
        _ = try Planet.query(on: db).join(children: \Planet.$moons).all().wait()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql.contains(#"INNER JOIN "moons" ON "planets"."id" = "moons"."planet_id"#), true)
        db.reset()

        _ = try Planet.query(on: db).join(parent: \Planet.$star).all().wait()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql.contains(#"INNER JOIN "stars" ON "planets"."star_id" = "stars"."id"#), true)
        db.reset()

        _ = try Planet.query(on: db).join(parent: \Planet.$possibleStar).all().wait()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql.contains(#"INNER JOIN "stars" ON "planets"."possible_star_id" = "stars"."id"#), true)
        db.reset()

        _ = try Planet.query(on: db).join(siblings: \Planet.$tags).all().wait()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql.contains(#"INNER JOIN "planet+tag" ON "planets"."id" = "planet+tag"."planet_id""#), true)
        XCTAssertEqual(db.sqlSerializers.first?.sql.contains(#"INNER JOIN "tags" ON "planet+tag"."tag_id" = "tags"."id""#), true)
        db.reset()
    }
    
    func testSingleColumnSelect() throws {
        let db = DummyDatabaseForTestSQLSerializer()
        
        _ = try Planet.query(on: db).all(\.$name).wait()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql, #"SELECT "planets"."name" AS "planets_name" FROM "planets""#)
        db.reset()
    }
    
    func testSQLDistinct() throws {
        let db = DummyDatabaseForTestSQLSerializer()
        
        _ = try Planet.query(on: db).unique().all(\.$name).wait()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql, #"SELECT DISTINCT "planets"."name" AS "planets_name" FROM "planets""#)
        db.reset()
        
        _ = try Planet.query(on: db).unique().all().wait()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql.starts(with: #"SELECT DISTINCT "planets"."#), true)
        db.reset()
        
        _ = try? Planet.query(on: db).unique().count(\.$name).wait()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql, #"SELECT COUNT(DISTINCT("planets"."name")) AS "aggregate" FROM "planets""#)
        db.reset()
        
        _ = try? Planet.query(on: db).unique().sum(\.$id).wait()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql, #"SELECT SUM(DISTINCT("planets"."id")) AS "aggregate" FROM "planets""#)
        db.reset()
    }

    func testSQLSchemaCustomIndex() throws {
        let db = DummyDatabaseForTestSQLSerializer()
        try db.schema("foo").field(.custom("INDEX i_foo (foo)")).update().wait()
        print(db.sqlSerializers)
    }
  
    func testRequiredFieldConstraint() throws {
        let db = DummyDatabaseForTestSQLSerializer()
        try db.schema("planets")
            .field("id", .int64, .required)
            .create()
            .wait()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql, #"CREATE TABLE "planets"("id" BIGINT NOT NULL)"#)
    }

    func testIdentifierFieldConstraint() throws {
        let db = DummyDatabaseForTestSQLSerializer()
        try db.schema("planets")
            .field("id", .int64, .identifier(auto: false))
            .create()
            .wait()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql, #"CREATE TABLE "planets"("id" BIGINT PRIMARY KEY)"#)
        db.reset()

        try db.schema("planets")
            .field("id", .int64, .identifier(auto: true))
            .create()
            .wait()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql, #"CREATE TABLE "planets"("id" BIGINT PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY)"#)
    }

    func testForeignKeyFieldConstraint() throws {
        let db = DummyDatabaseForTestSQLSerializer()
        try db.schema("planets")
            .field("galaxy_id", .int64, .references("galaxies", "id"))
            .create()
            .wait()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql, #"CREATE TABLE "planets"("galaxy_id" BIGINT REFERENCES "galaxies" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION)"#)
        db.reset()

        try db.schema("planets")
            .field("galaxy_id", .int64, .references("galaxies", "id", onDelete: .restrict, onUpdate: .cascade))
            .create()
            .wait()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql, #"CREATE TABLE "planets"("galaxy_id" BIGINT REFERENCES "galaxies" ("id") ON DELETE RESTRICT ON UPDATE CASCADE)"#)
    }

    func testMultipleFieldConstraint() throws {
        let db = DummyDatabaseForTestSQLSerializer()
        try db.schema("planets")
            .field("id", .int64, .required, .identifier(auto: true))
            .create()
            .wait()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql, #"CREATE TABLE "planets"("id" BIGINT NOT NULL PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY)"#)
    }

    func testUniqueTableConstraint() throws {
        let db = DummyDatabaseForTestSQLSerializer()
        try db.schema("planets")
            .field("id", .int64)
            .unique(on: "id")
            .create()
            .wait()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql, #"CREATE TABLE "planets"("id" BIGINT, CONSTRAINT "uq:planets.id" UNIQUE ("id"))"#)
        db.reset()

        try db.schema("planets")
            .field("id", .int64)
            .field("name", .string)
            .unique(on: "id", "name")
            .create()
            .wait()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql, #"CREATE TABLE "planets"("id" BIGINT, "name" TEXT, CONSTRAINT "uq:planets.id+planets.name" UNIQUE ("id", "name"))"#)
    }

    func testForeignKeyTableConstraint() throws {
        let db = DummyDatabaseForTestSQLSerializer()
        try db.schema("planets")
            .field("galaxy_id", .int64)
            .foreignKey("galaxy_id", references: "galaxies", "id")
            .create()
            .wait()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql, #"CREATE TABLE "planets"("galaxy_id" BIGINT, CONSTRAINT "fk:planets.galaxy_id+planets.id" FOREIGN KEY ("galaxy_id") REFERENCES "galaxies" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION)"#)
        db.reset()

        try db.schema("planets")
            .field("galaxy_id", .int64)
            .foreignKey(
                "galaxy_id",
                references: "galaxies", "id",
                onDelete: .restrict,
                onUpdate: .cascade
            )
            .create()
            .wait()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql, #"CREATE TABLE "planets"("galaxy_id" BIGINT, CONSTRAINT "fk:planets.galaxy_id+planets.id" FOREIGN KEY ("galaxy_id") REFERENCES "galaxies" ("id") ON DELETE RESTRICT ON UPDATE CASCADE)"#)
        db.reset()

         try db.schema("planets")
             .field("galaxy_id", .int64)
             .field("galaxy_name", .string)
             .foreignKey(
                 ["galaxy_id", "galaxy_name"],
                 references: "galaxies", ["id", "name"],
                 onUpdate: .cascade
             )
             .create()
             .wait()
         XCTAssertEqual(db.sqlSerializers.count, 1)
         XCTAssertEqual(db.sqlSerializers.first?.sql, #"CREATE TABLE "planets"("galaxy_id" BIGINT, "galaxy_name" TEXT, CONSTRAINT "fk:planets.galaxy_id+planets.galaxy_name+planets.id+planets.name" FOREIGN KEY ("galaxy_id", "galaxy_name") REFERENCES "galaxies" ("id", "name") ON DELETE NO ACTION ON UPDATE CASCADE)"#)
    }
    
    func testIfNotExistsTableCreate() throws {
        let db = DummyDatabaseForTestSQLSerializer()
        try db.schema("planets")
            .field("galaxy_id", .int64)
            .ignoreExisting()
            .create()
            .wait()
            
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql, #"CREATE TABLE IF NOT EXISTS "planets"("galaxy_id" BIGINT)"#)
        db.reset()

        try db.schema("planets")
            .field("galaxy_id", .int64)
            .create()
            .wait()
            
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(db.sqlSerializers.first?.sql, #"CREATE TABLE "planets"("galaxy_id" BIGINT)"#)
    }
    
    func testDecodeWithoutID() throws {
        let json = """
        {"name": "Earth", "moonCount": 1}
        """
        let planet = try JSONDecoder().decode(Planet2.self, from: Data(json.utf8))
        XCTAssertEqual(planet.id, nil)
        XCTAssertEqual(planet.name, "Earth")
        XCTAssertEqual(planet.nickName, nil)
        XCTAssertEqual(planet.moonCount, 1)
    }
    
    func testDecodeWithID() throws {
        let json = """
        {"id": 42, "name": "Earth", "moonCount": 1}
        """
        let planet = try JSONDecoder().decode(Planet2.self, from: Data(json.utf8))
        XCTAssertEqual(planet.id, 42)
        XCTAssertEqual(planet.name, "Earth")
        XCTAssertEqual(planet.nickName, nil)
        XCTAssertEqual(planet.moonCount, 1)
    }
    
    func testDecodeWithOptional() throws {
        let json = """
        {"id": 42, "name": "Earth", "moonCount": 1, "nickName": "The Blue Marble"}
        """
        let planet = try JSONDecoder().decode(Planet2.self, from: Data(json.utf8))
        XCTAssertEqual(planet.id, 42)
        XCTAssertEqual(planet.name, "Earth")
        XCTAssertEqual(planet.nickName, "The Blue Marble")
        XCTAssertEqual(planet.moonCount, 1)
    }
    
    func testDecodeMissingRequired() throws {
        let json = """
        {"name": "Earth"}
        """
        do {
            _ = try JSONDecoder().decode(Planet2.self, from: Data(json.utf8))
            XCTFail("should have thrown")
        } catch {
            print(error)
        }
    }

    // GitHub PR: https://github.com/vapor/fluent-kit/pull/209
    func testDecodeEnumProperty() throws {
        let json = """
        {"name": "Squeeky", "type": "mouse"}
        """
        do {
            let toy = try JSONDecoder().decode(Toy.self, from: Data(json.utf8))
            XCTAssertNotNil(toy.$type.value)
        } catch {
            return XCTFail("\(error)")
        }
    }

    func testCreateEmptyModelArrayDoesntQuery() throws {
        let db = DummyDatabaseForTestSQLSerializer()
        try [Planet2]().create(on: db).wait()
        XCTAssertEqual(db.sqlSerializers.count, 0)
    }

    func testCompoundModel() throws {
        let tanner = User(
            name: "Tanner",
            pet: .init(
                name: "Ziz",
                type: .cat,
                toy: .init(
                    name: "Foo",
                    type: .mouse,
                    foo: .init(bar: 42, baz: "hello")
                )
            )
        )

        // GroupProperty<User, Pet>
        let a = tanner.$pet
        print(a)

        // GroupedProperty<User, GroupProperty<Pet, Toy>>
        let b = tanner.$pet.$toy
        print(b)

        // GroupedProperty<User, GroupedProperty<Pet, GroupProperty<Toy, Foo>>>
        let c = tanner.$pet.$toy.$foo
        print(c)

        // GroupedProperty<User, GroupedProperty<Pet, GroupedProperty<Toy, FieldProperty<Foo, Int>>>>
        let d = tanner.$pet.$toy.$foo.$bar
        print(d)

        XCTAssertEqual(tanner.pet.name, "Ziz")
        XCTAssertEqual(tanner.$pet.$name.value, "Ziz")
        XCTAssertEqual(User.path(for: \.$pet.$toy.$foo.$bar).map { $0.description }, ["pet_toy_foo_bar"])

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .sortedKeys
            let encoded = try encoder.encode(tanner)
            let result = String(data:encoded, encoding: .utf8)!
            let expected = #"{"deletedAt":null,"id":null,"name":"Tanner","pet":{"name":"Ziz","toy":{"foo":{"bar":42,"baz":"hello"},"name":"Foo","type":"mouse"},"type":"cat"}}"#
            XCTAssertEqual(result, expected)
        }
    }

    func testPlanet2FilterPlaceholder1() throws {
            let db = DummyDatabaseForTestSQLSerializer()
            _ = try Planet2
                .query(on: db)
                .filter(\.$nickName != "first")
                .count()
                .wait()
            XCTAssertEqual(db.sqlSerializers.count, 1)
            let result: String = (db.sqlSerializers.first?.sql)!
            let expected = #"SELECT COUNT("planets"."id") AS "aggregate" FROM "planets" WHERE "planets"."nickname" <> $1"#
            XCTAssertEqual(result, expected)
            db.reset()
        }

    func testPlanet2FilterPlaceholder2() throws {
            let db = DummyDatabaseForTestSQLSerializer()
            _ = try Planet2
                .query(on: db)
                .filter(\.$nickName != nil)
                .count()
                .wait()
            XCTAssertEqual(db.sqlSerializers.count, 1)
            let result: String = (db.sqlSerializers.first?.sql)!
            let expected = #"SELECT COUNT("planets"."id") AS "aggregate" FROM "planets" WHERE "planets"."nickname" IS NOT NULL"#
            XCTAssertEqual(result, expected)
            db.reset()
        }

    func testPlanet2FilterPlaceholder3() throws {
            let db = DummyDatabaseForTestSQLSerializer()
            _ = try Planet2
                .query(on: db)
                .filter(\.$nickName != "first")
                .filter(\.$nickName == "second")
                .filter(\.$nickName != "third")
                .count()
                .wait()
            XCTAssertEqual(db.sqlSerializers.count, 1)
            let result: String = (db.sqlSerializers.first?.sql)!
            let expected = #"SELECT COUNT("planets"."id") AS "aggregate" FROM "planets" WHERE "planets"."nickname" <> $1 AND "planets"."nickname" = $2 AND "planets"."nickname" <> $3"#
            XCTAssertEqual(result, expected)
            db.reset()
        }

    func testPlanet2FilterPlaceholder4() throws {
        let db = DummyDatabaseForTestSQLSerializer()
        _ = try Planet2
            .query(on: db)
            .filter(\.$nickName != "first")
            .filter(\.$nickName != nil)
            .filter(\.$nickName == "second")
            .count()
            .wait()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        let result: String = (db.sqlSerializers.first?.sql)!
        let expected = #"SELECT COUNT("planets"."id") AS "aggregate" FROM "planets" WHERE "planets"."nickname" <> $1 AND "planets"."nickname" IS NOT NULL AND "planets"."nickname" = $2"#
        XCTAssertEqual(result, expected)
        db.reset()
    }

    func testLoggerOverride() throws {
        let db: Database = DummyDatabaseForTestSQLSerializer()
        XCTAssertEqual(db.logger.logLevel, env("LOG_LEVEL").flatMap { Logger.Level(rawValue: $0) } ?? .info)
        var logger = db.logger
        logger.logLevel = .critical
        let new = db.logging(to: logger)
        XCTAssertEqual(new.logger.logLevel, .critical)
    }

    func testEnumDecode() throws {
        enum Bar: String, Codable, Equatable {
            case baz
        }
        final class Foo: Model {
            static let schema = "foos"
            @ID var id: UUID?
            @Enum(key: "bar") var bar: Bar
            init() { }
        }

        do {
            let foo = try JSONDecoder().decode(Foo.self, from: Data("""
            {"bar": "baz"}
            """.utf8))
            XCTAssertEqual(foo.bar, .baz)
        }
        do {
            _ = try JSONDecoder().decode(Foo.self, from: Data("""
            {"bar": "qux"}
            """.utf8))
            XCTFail("should not have passed")
        } catch DecodingError.typeMismatch(let foo, let context) {
            XCTAssert(foo is Bar.Type)
            XCTAssertEqual(context.codingPath.map(\.stringValue), ["bar"])
        }
    }

    func testOptionalEnumDecode() throws {
        enum Bar: String, Codable, Equatable {
            case baz
        }
        final class Foo: Model {
            static let schema = "foos"
            @ID var id: UUID?
            @OptionalEnum(key: "bar") var bar: Bar?
            init() { }
        }

        do {
            let foo = try JSONDecoder().decode(Foo.self, from: Data("""
            {"bar": "baz"}
            """.utf8))
            XCTAssertEqual(foo.bar, .baz)
        }
        do {
            _ = try JSONDecoder().decode(Foo.self, from: Data("""
            {"bar": "qux"}
            """.utf8))
            XCTFail("should not have passed")
        } catch DecodingError.typeMismatch(let foo, let context) {
            XCTAssert(foo is Bar?.Type)
            XCTAssertEqual(context.codingPath.map(\.stringValue), ["bar"])
        }
    }

    func testDatabaseGeneratedIDOverride() throws {
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
        try foo.create(on: test.db).wait()
        XCTAssertEqual(foo.id, 1)
    }


    func testQueryBuilderFieldsFor() throws {
        let test = ArrayTestDatabase()
        let builder = User.query(on: test.db)
        XCTAssertEqual(builder.query.fields.count, 0)
        _ = builder.fields(for: User.self)
        XCTAssertEqual(builder.query.fields.count, 9)
    }

    func testPaginationDoesntCrashWithNegativeNumbers() throws {
        let db = DummyDatabaseForTestSQLSerializer()
        let pageRequest1 = PageRequest(page: -1, per: 10)
        XCTAssertNoThrow(try Planet2
            .query(on: db)
            .paginate(pageRequest1)
            .wait())

        let pageRequest2 = PageRequest(page: 1, per: -10)
        XCTAssertNoThrow(try Planet2
            .query(on: db)
            .paginate(pageRequest2)
            .wait())
    }
    
    func testModelsWithSpacesSpecified() throws {
        let db = DummyDatabaseForTestSQLSerializer()
        try db.schema(AltPlanet.schema, space: AltPlanet.space)
            .id()
            .field("name", .string, .required)
            .field("star_id", .uuid, .references(Star.schema, "id"), .required)
            .field("possible_star_id", .uuid, .references(Star.schema, "id"))
            .field("createdAt", .datetime)
            .field("updatedAt", .datetime)
            .field("deletedAt", .datetime, .sql(.default(SQLLiteral.null)))
            .create()
            .wait()
        _ = try AltPlanet.query(on: db).filter(\.$name == "Earth").all().wait()
        try AltPlanet(name: "Nemesis").create(on: db).wait()
        let updateMe = AltPlanet(id: UUID(), name: "Vulcan")
        updateMe.$id.exists = true
        try updateMe.update(on: db).wait()
        try AltPlanet.query(on: db).filter(\.$name != "Arret").delete(force: true).wait()
        _ = try Star.query(on: db).join(AltPlanet.self, on: \AltPlanet.$star.$id == \Star.$id).fields(for: Star.self).withDeleted().first().wait()
        
        XCTAssertEqual(db.sqlSerializers.count, 6)
        XCTAssertEqual(db.sqlSerializers.dropFirst(0).first?.sql, #"CREATE TABLE "mirror_universe"."planets"("id" UUID PRIMARY KEY, "name" TEXT NOT NULL, "star_id" UUID REFERENCES "stars" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION NOT NULL, "possible_star_id" UUID REFERENCES "stars" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION, "createdAt" TIMESTAMPTZ, "updatedAt" TIMESTAMPTZ, "deletedAt" TIMESTAMPTZ DEFAULT NULL)"#)
        XCTAssertEqual(db.sqlSerializers.dropFirst(1).first?.sql, #"SELECT "mirror_universe"."planets"."id" AS "mirror_universe_planets_id", "mirror_universe"."planets"."name" AS "mirror_universe_planets_name", "mirror_universe"."planets"."star_id" AS "mirror_universe_planets_star_id", "mirror_universe"."planets"."possible_star_id" AS "mirror_universe_planets_possible_star_id", "mirror_universe"."planets"."createdAt" AS "mirror_universe_planets_createdAt", "mirror_universe"."planets"."updatedAt" AS "mirror_universe_planets_updatedAt", "mirror_universe"."planets"."deletedAt" AS "mirror_universe_planets_deletedAt" FROM "mirror_universe"."planets" WHERE "mirror_universe"."planets"."name" = $1 AND ("mirror_universe"."planets"."deletedAt" IS NULL OR "mirror_universe"."planets"."deletedAt" > $2)"#)
        XCTAssertEqual(db.sqlSerializers.dropFirst(2).first?.sql, #"INSERT INTO "mirror_universe"."planets" ("id", "createdAt", "updatedAt", "name") VALUES ($1, $2, $3, $4)"#)
        XCTAssertEqual(db.sqlSerializers.dropFirst(3).first?.sql, #"UPDATE "mirror_universe"."planets" SET "updatedAt" = $1, "name" = $2, "id" = $3 WHERE "mirror_universe"."planets"."id" = $4 AND ("mirror_universe"."planets"."deletedAt" IS NULL OR "mirror_universe"."planets"."deletedAt" > $5)"#)
        XCTAssertEqual(db.sqlSerializers.dropFirst(4).first?.sql, #"DELETE FROM "mirror_universe"."planets" WHERE "mirror_universe"."planets"."name" <> $1"#)
        XCTAssertEqual(db.sqlSerializers.dropFirst(5).first?.sql, #"SELECT "stars"."id" AS "stars_id", "stars"."name" AS "stars_name", "stars"."galaxy_id" AS "stars_galaxy_id" FROM "stars" INNER JOIN "mirror_universe"."planets" ON "stars"."id" = "mirror_universe"."planets"."star_id" LIMIT 1"#)
    }
    
    func testFieldsPropertiesPerformance() throws {
        measure {
            for _ in 1 ... 10_000 {
                XCTAssertEqual(LotsOfFields().properties.count, 21)
            }
        }
    }
}

final class User: Model {
    static let schema = "users"

    @ID var id: UUID?

    @Field(key: "name")
    var name: String

    @Timestamp(key: "deleted_at", on: .delete)
    var deletedAt: Date?

    @Group(key: "pet")
    var pet: Pet

    init() { }

    init(id: UUID? = nil, name: String, pet: Pet) {
        self.id = id
        self.name = name
        self.pet = pet
    }
}

enum Animal: String, Codable {
    case cat, dog
}

final class Pet: Fields {
    @Field(key: "name")
    var name: String

    @Field(key: "type")
    var type: Animal

    @Group(key: "toy")
    var toy: Toy

    init() { }

    init(name: String, type: Animal, toy: Toy) {
        self.name = name
        self.type = type
        self.toy = toy
    }
}

enum ToyType: String, Codable {
    case mouse, bone
}

final class Toy: Fields {
    @Field(key: "name")
    var name: String

    @Enum(key: "type")
    var type: ToyType

    @Group(key: "foo")
    var foo: Foo

    init() { }

    init(name: String, type: ToyType, foo: Foo) {
        self.name = name
        self.type = type
        self.foo = foo
    }
}

final class Foo: Fields {
    @Field(key: "bar")
    var bar: Int

    @Field(key: "baz")
    var baz: String

    init() { }

    init(bar: Int, baz: String) {
        self.bar = bar
        self.baz = baz
    }
}

final class Planet2: Model {
    static let schema = "planets"
    
    @ID(custom: "id", generatedBy: .database)
    var id: Int?
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "nickname")
    var nickName: String?
    
    @Field(key: "moon_count")
    var moonCount: Int
    
    init() { }
    
    init(id: Int? = nil, name: String, moonCount: Int) {
        self.id = id
        self.name = name
        self.moonCount = moonCount
    }
}

final class AltPlanet: Model {
    public static let space: String? = "mirror_universe"
    public static let schema = "planets"

    @ID(key: .id)
    public var id: UUID?

    @Field(key: "name")
    public var name: String

    @Parent(key: "star_id")
    public var star: Star

    @OptionalParent(key: "possible_star_id")
    public var possibleStar: Star?
    
    @Timestamp(key: "createdAt", on: .create)
    public var createdAt: Date?

    @Timestamp(key: "updatedAt", on: .update)
    public var updatedAt: Date?

    @Timestamp(key: "deletedAt", on: .delete)
    public var deletedAt: Date?

    public init() {}

    public init(id: IDValue? = nil, name: String) {
        self.id = id
        self.name = name
    }

    public init(id: IDValue? = nil, name: String, starId: UUID) {
        self.id = id
        self.name = name
        self.$star.id = starId
    }
}

final class LotsOfFields: Model {
    static let schema = "never_used"
    
    @ID(custom: "id")
    var id: Int?
    
    @Field(key: "field1")
    var field1: String
    
    @Field(key: "field2")
    var field2: String
    
    @Field(key: "field3")
    var field3: String
    
    @Field(key: "field4")
    var field4: String
    
    @Field(key: "field5")
    var field5: String
    
    @Field(key: "field6")
    var field6: String
    
    @Field(key: "field7")
    var field7: String
    
    @Field(key: "field8")
    var field8: String
    
    @Field(key: "field9")
    var field9: String
    
    @Field(key: "field10")
    var field10: String
    
    @Field(key: "field11")
    var field11: String
    
    @Field(key: "field12")
    var field12: String
    
    @Field(key: "field13")
    var field13: String
    
    @Field(key: "field14")
    var field14: String
    
    @Field(key: "field15")
    var field15: String
    
    @Field(key: "field16")
    var field16: String
    
    @Field(key: "field17")
    var field17: String
    
    @Field(key: "field18")
    var field18: String
    
    @Field(key: "field19")
    var field19: String
    
    @Field(key: "field20")
    var field20: String
}
