import FluentSQL
import XCTest

extension FluentBenchmarker {
    public func testSQLEnums() throws {
        try runTest(#function, [
            _PlanetMigration(),
        ]) {
            try _Planet(name: "Earth", type: .smallRocky)
                .save(on: self.database).wait()
            try _Planet(name: "Jupiter", type: .gasGiant)
                .save(on: self.database).wait()

            let planets1 = try _Planet.query(on: self.database).sort(\.$name).all().wait()
            XCTAssertEqual(planets1.map { "\($0.name):\($0.type)" }, [
                "Earth:smallRocky",
                "Jupiter:gasGiant"
            ])

            try _PlanetAddDwarfType().prepare(on: self.database).wait()

            try _Planet(name: "Pluto", type: .dwarf)
                .save(on: self.database).wait()

            let planets2 = try _Planet.query(on: self.database).sort(\.$name).all().wait()
            XCTAssertEqual(planets2.map { "\($0.name):\($0.type)" }, [
                "Earth:smallRocky",
                "Jupiter:gasGiant",
                "Pluto:dwarf"
            ])
        }
    }
}

private enum PlanetType: String, Codable, SQLExpressible {
    case smallRocky
    case gasGiant
    case dwarf

    var sql: SQLExpression {
        // serializes the value as a literal string in
        // queries instead of binding the value
        SQLLiteral.string(self.rawValue)
    }
}

private final class _Planet: Model {
    static let schema = "planets"

    @ID(key: "id")
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Field(key: "type")
    var type: PlanetType

    public init() { }

    init(id: UUID? = nil, name: String, type: PlanetType) {
        self.id = id
        self.name = name
        self.type = type
    }
}

private struct _PlanetMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        // this test is for SQL databases only
        guard let sql = database as? SQLDatabase else {
            return database.eventLoop.makeFailedFuture(
                FluentBenchmarker.Failure("SQL database required")
            )
        }

        let planetType: EventLoopFuture<DatabaseSchema.DataType>
        switch sql.dialect.enumSyntax {
        case .unsupported:
            // if the database does not support enums,
            // just store the enum value as an unchecked string
            planetType = database.eventLoop.makeSucceededFuture(.string)
        case .typeName:
            // if the database supports types, create a new enum type
            planetType = sql.create(
                enum: "PLANET_TYPE", cases: "smallRocky", "gasGiant"
            ).run().map {
                .sql(.type("PLANET_TYPE"))
            }
        case .inline:
            // use in-line enum data types if supported
            planetType = database.eventLoop.makeSucceededFuture(
                .sql(.enum("smallRocky", "gasGiant"))
            )
        }

        return planetType.flatMap {
            database.schema("planets")
                .field("id", .uuid, .identifier(auto: false))
                .field("name", .string, .required)
                .field("type", $0, .required)
                .create()
        }
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        // this test is for SQL databases only
        guard let sql = database as? SQLDatabase else {
            return database.eventLoop.makeFailedFuture(
                FluentBenchmarker.Failure("SQL database required")
            )
        }

        return database.schema("planets").delete().flatMap {
            if case .typeName = sql.dialect.enumSyntax {
                // if the database supports types, drop the type
                // created by the forward migration
                return sql.drop(type: "PLANET_TYPE").run()
            } else {
                return database.eventLoop.makeSucceededFuture(())
            }
        }
    }
}

private struct _PlanetAddDwarfType: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        // this test is for SQL databases only
        guard let sql = database as? SQLDatabase else {
            return database.eventLoop.makeFailedFuture(
                FluentBenchmarker.Failure("SQL database required")
            )
        }

        switch sql.dialect.enumSyntax {
        case .unsupported:
            // if the database does not support typed enums,
            // nothing needs to be done here
            return database.eventLoop.makeSucceededFuture(())
        case .typeName:
            // if the database supports types, add the new enum case
            return sql.alter(type: "PLANET_TYPE").add(value: "dwarf").run()
        case .inline:
            // if the database supports in-line enums, modify the
            // table schema to add the new enum case
            return database.schema("planets")
                .updateField("type", .sql(.enum("smallRocky", "gasGiant", "dwarf")))
                .update()
        }
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        // not possible to undo
        return database.eventLoop.makeSucceededFuture(())
    }
}
