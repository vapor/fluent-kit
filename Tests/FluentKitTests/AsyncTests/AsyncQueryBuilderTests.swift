import FluentKit
import FluentBenchmark
import Foundation
import SQLKit
import XCTFluent
import XCTest

final class AsyncQueryBuilderTests: XCTestCase {
    override class func setUp() {
        super.setUp()
        XCTAssertTrue(isLoggingConfigured)
    }

    func testFirstEmptyResult() async throws {
        let test = ArrayTestDatabase()
        test.append([])

        let retrievedPlanet = try await Planet.query(on: test.db).first()

        XCTAssertNil(retrievedPlanet)
    }

    func testFirstSingleResult() async throws {
        let planet = Planet(id: UUID(), name: "Tully")
        let test = ArrayTestDatabase()
        test.append([
            TestOutput([
                "id": planet.id as any Sendable,
                "name": planet.name,
                "star_id": UUID()
            ])
        ])

        let retrievedPlanet = try await Planet.query(on: test.db).first()

        XCTAssertEqual(planet.id, retrievedPlanet?.id)
        XCTAssertEqual(planet.name, retrievedPlanet?.name)
    }

    func testFirstManyResults() async throws {
        let planet = Planet(id: UUID(), name: "Tully")
        let test = ArrayTestDatabase()
        test.append([
            TestOutput([
                "id": planet.id as any Sendable,
                "name": planet.name,
                "star_id": UUID()
            ]),
            TestOutput([
                "id": UUID(),
                "name": "Nupeter",
                "star_id": UUID()
            ])
        ])

        let retrievedPlanet = try await Planet.query(on: test.db).first()

        XCTAssertEqual(planet.id, retrievedPlanet?.id)
        XCTAssertEqual(planet.name, retrievedPlanet?.name)
    }

    func testAllManyResults() async throws {
        let starId = UUID()
        let planets = [
            Planet(id: UUID(), name: "P1", starId: starId),
            Planet(id: UUID(), name: "P2", starId: starId),
            Planet(id: UUID(), name: "P3", starId: starId)
        ]
        let test = ArrayTestDatabase()
        test.append(planets.map(TestOutput.init))

        let retrievedPlanets = try await Planet.query(on: test.db).all()

        XCTAssertEqual(retrievedPlanets.count, planets.count)
        XCTAssertEqual(retrievedPlanets.map(\.name), planets.map(\.name))
    }

    func testQueryHistory() async throws {
        let starId = UUID()
        let planets = [
            Planet(id: UUID(), name: "P1", starId: starId),
            Planet(id: UUID(), name: "P2", starId: starId),
            Planet(id: UUID(), name: "P3", starId: starId)
        ]
        let test = ArrayTestDatabase()
        let db = test.database(context: .init(configuration: test.configuration, logger: test.db.logger, eventLoop: test.db.eventLoop, history: .init()))
        test.append(planets.map(TestOutput.init))

        let retrievedPlanets = try await Planet.query(on: db).all()
        XCTAssertEqual(retrievedPlanets.count, planets.count)
        XCTAssertEqual(db.history?.queries.count, 1)
        XCTAssertEqual(db.history?.queries.first?.schema, Planet.schema)
    }

    func testPerPageLimit() async throws {
        let starId = UUID()
        let rows = [
            TestOutput(["id": UUID(), "name": "a", "star_id": starId]),
            TestOutput(["id": UUID(), "name": "b", "star_id": starId]),
            TestOutput(["id": UUID(), "name": "c", "star_id": starId]),
            TestOutput(["id": UUID(), "name": "d", "star_id": starId]),
            TestOutput(["id": UUID(), "name": "e", "star_id": starId]),
        ]

        let test = CallbackTestDatabase { query in
            XCTAssertEqual(query.schema, "planets")
            let result: [TestOutput]
            if
                let limit = query.limits.first,
                case let DatabaseQuery.Limit.count(limitValue) = limit,
                let offset = query.offsets.first,
                case let DatabaseQuery.Offset.count(offsetValue) = offset
            {
                result = [TestOutput](rows[min(offsetValue, rows.count - 1)..<min(offsetValue + limitValue, rows.count)])
            } else {
                result = rows
            }
            switch query.action {
            case .aggregate(_):
                return [TestOutput([.aggregate: rows.count])]
            default:
                return result
            }
        }

        let pageSizeLimit = 2

        let db = test.database(
            context: .init(
                configuration: test.configuration,
                logger: test.db.logger,
                eventLoop: test.db.eventLoop,
                history: .init(),
                pageSizeLimit: pageSizeLimit
            )
        )

        let pageRequest = PageRequest(page: 2, per: 3)
        let retrievedPlanets = try await Planet.query(on: db).paginate(pageRequest)
        XCTAssertEqual(retrievedPlanets.items.count, pageSizeLimit, "Page size limit should be respected.")
        XCTAssertEqual(retrievedPlanets.items.first?.name, "c", "Page size limit should determine offset")
    }
    
    func testPaginationInvalidLowerPageBoundary() async throws {
        
        // Given - a dataset with 5 items
        let starId = UUID()
        let rows = [
            TestOutput(["id": UUID(), "name": "a", "star_id": starId]),
            TestOutput(["id": UUID(), "name": "b", "star_id": starId]),
            TestOutput(["id": UUID(), "name": "c", "star_id": starId]),
            TestOutput(["id": UUID(), "name": "d", "star_id": starId]),
            TestOutput(["id": UUID(), "name": "e", "star_id": starId]),
        ]

        let test = CallbackTestDatabase { query in
            XCTAssertEqual(query.schema, "planets")
            let result: [TestOutput]
            if
                let limit = query.limits.first,
                case let DatabaseQuery.Limit.count(limitValue) = limit,
                let offset = query.offsets.first,
                case let DatabaseQuery.Offset.count(offsetValue) = offset
            {
                result = [TestOutput](rows[min(offsetValue, rows.count - 1)..<min(offsetValue + limitValue, rows.count)])
            } else {
                result = rows
            }
            switch query.action {
            case .aggregate(_):
                return [TestOutput([.aggregate: rows.count])]
            default:
                return result
            }
        }

        // And - a page size limit of 2 items
        let pageSizeLimit = 2

        let db = test.database(
            context: .init(
                configuration: test.configuration,
                logger: test.db.logger,
                eventLoop: test.db.eventLoop,
                history: .init(),
                pageSizeLimit: pageSizeLimit
            )
        )
        
        // When - query for invalid lower boundary page index
        let retrievedPlanets = try await Planet.query(on: db).page(withIndex: -1, size: 2)
        
        // Then - the first page should be retrieved
        XCTAssertEqual(retrievedPlanets.items.first?.name, "a", "First page should be minimum.")
        XCTAssertEqual(retrievedPlanets.items.count, 2, "Expecting first page to have a two items.")
    }
    
    func testPaginationInvalidUpperPageBoundary() async throws {
        
        // Given - a dataset with 5 items
        let starId = UUID()
        let rows = [
            TestOutput(["id": UUID(), "name": "a", "star_id": starId]),
            TestOutput(["id": UUID(), "name": "b", "star_id": starId]),
            TestOutput(["id": UUID(), "name": "c", "star_id": starId]),
            TestOutput(["id": UUID(), "name": "d", "star_id": starId]),
            TestOutput(["id": UUID(), "name": "e", "star_id": starId]),
        ]

        let test = CallbackTestDatabase { query in
            XCTAssertEqual(query.schema, "planets")
            let result: [TestOutput]
            if
                let limit = query.limits.first,
                case let DatabaseQuery.Limit.count(limitValue) = limit,
                let offset = query.offsets.first,
                case let DatabaseQuery.Offset.count(offsetValue) = offset
            {
                result = [TestOutput](rows[min(offsetValue, rows.count - 1)..<min(offsetValue + limitValue, rows.count)])
            } else {
                result = rows
            }
            switch query.action {
            case .aggregate(_):
                return [TestOutput([.aggregate: rows.count])]
            default:
                return result
            }
        }

        // And - a page size limit of 2 items, resulting in a total of 3 pages (5 items / 2 per page)
        let pageSizeLimit = 2

        let db = test.database(
            context: .init(
                configuration: test.configuration,
                logger: test.db.logger,
                eventLoop: test.db.eventLoop,
                history: .init(),
                pageSizeLimit: pageSizeLimit
            )
        )
        
        // When - query for invalid upper boundary page index
        let retrievedPlanets = try await Planet.query(on: db).page(withIndex: 4, size: 2)
        
        // Then - the last page should be retrieved
        XCTAssertEqual(retrievedPlanets.items.first?.name, "e", "Last page should be maximum.")
        XCTAssertEqual(retrievedPlanets.items.count, 1, "Expecting last page to have a single item.")
    }

    // https://github.com/vapor/fluent-kit/issues/310
    func testJoinOverloads() async throws {
        final class UnsafeMutableTransferBox<Wrapped>: @unchecked Sendable {
            var wrappedValue: Wrapped
            init(_ wrappedValue: Wrapped) { self.wrappedValue = wrappedValue }
        }

        let query = UnsafeMutableTransferBox<DatabaseQuery?>(nil)
        let test = CallbackTestDatabase {
            query.wrappedValue = $0
            return []
        }
        let planets = try await Planet.query(on: test.db)
            .join(Star.self, on: \Star.$id == \Planet.$star.$id)
            .filter(\.$name, .custom("ilike"), "earth")
            .filter(Star.self, \.$name, .custom("ilike"), "Sol")
            .all()
        XCTAssertEqual(planets.count, 0)
        XCTAssertNotNil(query.wrappedValue?.filters[1])
        switch query.wrappedValue?.filters[1] {
        case .value(let field, let method, let value):
            switch field {
            case .path(let path, let schema):
                XCTAssertEqual(path, ["name"])
                XCTAssertEqual(schema, "stars")
            case .extendedPath(let path, let schema, let space):
                XCTAssertEqual(path, ["name"])
                XCTAssertEqual(schema, "stars")
                XCTAssertNil(space)
            default:
                XCTFail("\(field)")
            }
            switch method {
            case .custom(let any as String):
                XCTAssertEqual(any, "ilike")
            default:
                XCTFail("\(method)")
            }
            switch value {
            case .bind(let any as String):
                XCTAssertEqual(any, "Sol")
            default:
                XCTFail("\(value)")
            }
        default:
            XCTFail("no query")
        }
    }

    func testComplexJoinOperators() async throws {
        let db = DummyDatabaseForTestSQLSerializer()
        
        _ = try await Planet.query(on: db)
            .join(Star.self, on: \Star.$id == \Planet.$star.$id && \Star.$name != \Planet.$name)
            .all()
        XCTAssertEqual(db.sqlSerializers.count, 1)
        XCTAssertEqual(try db.sqlSerializers.xctAt(0).sql, #"SELECT "planets"."id" AS "planets_id", "planets"."name" AS "planets_name", "planets"."star_id" AS "planets_star_id", "planets"."possible_star_id" AS "planets_possible_star_id", "planets"."deleted_at" AS "planets_deleted_at", "stars"."id" AS "stars_id", "stars"."name" AS "stars_name", "stars"."galaxy_id" AS "stars_galaxy_id", "stars"."deleted_at" AS "stars_deleted_at" FROM "planets" INNER JOIN "stars" ON "stars"."id" = "planets"."star_id" AND "stars"."name" <> "planets"."name" WHERE ("planets"."deleted_at" IS NULL OR "planets"."deleted_at" > $1) AND ("stars"."deleted_at" IS NULL OR "stars"."deleted_at" > $2)"#)
    }
}
