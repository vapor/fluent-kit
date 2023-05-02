import FluentKit
import Foundation
import NIOCore
import XCTest

extension FluentBenchmarker {

    public func testMiddleware() throws {
        try self.testMiddleware_methods()
        try self.testMiddleware_batchCreationFail()
        try self.testAsyncMiddleware_methods()
    }
    
    public func testMiddleware_methods() throws {
        self.databases.middleware.use(UserMiddleware())
        defer { self.databases.middleware.clear() }

        try self.runTest(#function, [
            UserMigration(),
        ]) {
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

    public func testAsyncMiddleware_methods() throws {
        self.databases.middleware.use(AsyncUserMiddleware())
        defer { self.databases.middleware.clear() }

        try self.runTest(#function, [
            UserMigration(),
        ]) {
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
    
    public func testMiddleware_batchCreationFail() throws {
        self.databases.middleware.clear()
        self.databases.middleware.use(UserBatchMiddleware())
        defer { self.databases.middleware.clear() }

        try self.runTest(#function, [
            UserMigration(),
        ]) {
            let user = User(name: "A")
            let user2 = User(name: "B")
            let user3 = User(name: "C")
          
            XCTAssertThrowsError(try [user, user2, user3].create(on: self.database).wait()) { error in
                let testError = (error as? TestError)
                XCTAssertEqual(testError?.string, "cancelCreation")
            }
            
            let userCount = try User.query(on: self.database).count().wait()
            XCTAssertEqual(userCount, 0)
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

private struct UserBatchMiddleware: ModelMiddleware {
    func create(model: User, on db: Database, next: AnyModelResponder) -> EventLoopFuture<Void> {
        if model.name == "A" {
            model.name = "AA"
            return next.create(model, on: db)
        } else if model.name == "C" {
            model.name = "CC"
            return next.create(model, on: db)
        } else {
            return db.eventLoop.makeFailedFuture(TestError(string: "cancelCreation"))
        }
    }
}

private struct AsyncUserMiddleware: AsyncModelMiddleware {
    func create(model: User, on db: Database, next: AnyAsyncModelResponder) async throws {
        model.name = "B"

        try await next.create(model, on: db)
        throw TestError(string: "didCreate")
    }

    func update(model: User, on db: Database, next: AnyAsyncModelResponder) async throws {
        model.name = "D"

        try await next.update(model, on: db)
        throw TestError(string: "didUpdate")
    }

    func softDelete(model: User, on db: Database, next: AnyAsyncModelResponder) async throws {
        model.name = "E"

        try await next.softDelete(model, on: db)
        throw TestError(string: "didSoftDelete")
    }

    func restore(model: User, on db: Database, next: AnyAsyncModelResponder) async throws {
        model.name = "F"

        try await next.restore(model , on: db)
        throw TestError(string: "didRestore")
    }

    func delete(model: User, force: Bool, on db: Database, next: AnyAsyncModelResponder) async throws {
        model.name = "G"

        try await next.delete(model, force: force, on: db)
        throw TestError(string: "didDelete")
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
