extension FluentBenchmarker {
    public func testModelMiddleware() throws {
        try self.runTest(#function, [
            UserMigration(),
        ]) {
            self.databases.middleware.use(UserMiddleware())

            let user = User(name: "A")
            // create
            do {
                try user.create(on: self.database).wait()
            } catch let error as TestError {
                XCTAssertEqual(error.string, "didCreate")
            }
            XCTAssertEqual(user.name, "B")

            // update
            user.name = "C"
            do {
                try user.update(on: self.database).wait()
            } catch let error as TestError {
                XCTAssertEqual(error.string, "didUpdate")
            }
            XCTAssertEqual(user.name, "D")

            // soft delete
            do {
                try user.delete(on: self.database).wait()
            } catch let error as TestError {
                XCTAssertEqual(error.string, "didSoftDelete")
            }
            XCTAssertEqual(user.name, "E")

            // restore
            do {
                try user.restore(on: self.database).wait()
            } catch let error as TestError {
                XCTAssertEqual(error.string, "didRestore")
            }
            XCTAssertEqual(user.name, "F")

            // force delete
            do {
                try user.delete(force: true, on: self.database).wait()
            } catch let error as TestError {
                XCTAssertEqual(error.string, "didDelete")
            }
            XCTAssertEqual(user.name, "G")
        }
    }
}

private struct TestError: Error {
    var string: String
}

private final class User: Model {
    static let schema = "users"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Timestamp(key: "deletedAt", on: .delete)
    var deletedAt: Date?

    init() { }

    init(id: IDValue? = nil, name: String) {
        self.id = id
        self.name = name
    }
}

private struct UserMiddleware: ModelMiddleware {
    func create(model: User, on db: Database, next: AnyModelResponder) -> EventLoopFuture<Void> {
        model.name = "B"

        return next.create(model, on: db).flatMap {
            return db.eventLoop.makeFailedFuture(TestError(string: "didCreate"))
        }
    }

    func update(model: User, on db: Database, next: AnyModelResponder) -> EventLoopFuture<Void> {
        model.name = "D"

        return next.update(model, on: db).flatMap {
            return db.eventLoop.makeFailedFuture(TestError(string: "didUpdate"))
        }
    }

    func softDelete(model: User, on db: Database, next: AnyModelResponder) -> EventLoopFuture<Void> {
        model.name = "E"

        return next.softDelete(model, on: db).flatMap {
            return db.eventLoop.makeFailedFuture(TestError(string: "didSoftDelete"))
        }
    }

    func restore(model: User, on db: Database, next: AnyModelResponder) -> EventLoopFuture<Void> {
        model.name = "F"

        return next.restore(model , on: db).flatMap {
            return db.eventLoop.makeFailedFuture(TestError(string: "didRestore"))
        }
    }

    func delete(model: User, force: Bool, on db: Database, next: AnyModelResponder) -> EventLoopFuture<Void> {
        model.name = "G"

        return next.delete(model, force: force, on: db).flatMap {
            return db.eventLoop.makeFailedFuture(TestError(string: "didDelete"))
        }
    }
}

private struct UserMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("users")
            .field("id", .uuid, .identifier(auto: false))
            .field("name", .string, .required)
            .field("deletedAt", .datetime)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("users").delete()
    }
}
