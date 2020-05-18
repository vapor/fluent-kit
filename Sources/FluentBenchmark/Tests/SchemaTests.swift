import FluentSQL

extension FluentBenchmarker {
    public func testSchema() throws {
        try self.testSchema_addConstraint()
        try self.testSchema_addNamedConstraint()
    }

    private func testSchema_addConstraint() throws {
        try self.runTest(#function, [
            CreateCategories()
        ]) {
            guard let sql = self.database as? SQLDatabase, sql.dialect.alterTableSyntax.allowsBatch else {
                self.database.logger.warning("Skipping \(#function)")
                return
            }
            // Add unique constraint
            try AddUniqueConstraintToCategories().prepare(on: self.database).wait()

            try Category(name: "a").create(on: self.database).wait()
            try Category(name: "b").create(on: self.database).wait()
            do {
                try Category(name: "a").create(on: self.database).wait()
                XCTFail("Duplicate save should have errored")
            } catch let error as DatabaseError where error.isConstraintFailure {
                // pass
            }

            // Remove unique constraint
            try AddUniqueConstraintToCategories().revert(on: self.database).wait()
            try Category(name: "a").create(on: self.database).wait()
        }
    }

    private func testSchema_addNamedConstraint() throws {
        try self.runTest(#function, [
            CreateCategories()
        ]) {
            guard let sql = self.database as? SQLDatabase, sql.dialect.alterTableSyntax.allowsBatch else {
                self.database.logger.warning("Skipping \(#function)")
                return
            }
            // Add unique constraint
            try AddNamedUniqueConstraintToCategories().prepare(on: self.database).wait()

            try Category(name: "a").create(on: self.database).wait()
            try Category(name: "b").create(on: self.database).wait()
            do {
                try Category(name: "a").create(on: self.database).wait()
                XCTFail("Duplicate save should have errored")
            } catch let error as DatabaseError where error.isConstraintFailure {
                // pass
            }

            // Remove unique constraint
            try AddNamedUniqueConstraintToCategories().revert(on: self.database).wait()
            try Category(name: "a").create(on: self.database).wait()
        }
    }
}

final class Category: Model {
    static let schema = "categories"
    @ID var id: UUID?
    @Field(key: "name") var name: String
    init() { }
    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
}

struct CreateCategories: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("categories")
            .id()
            .field("name", .string, .required)
            .create()
    }
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("categories")
            .delete()
    }
}

struct AddUniqueConstraintToCategories: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("categories")
            .unique(on: "name")
            .update()
    }
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("categories")
            .deleteUnique(on: "name")
            .update()
    }
}


struct AddNamedUniqueConstraintToCategories: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("categories")
            .unique(on: "name", name: "foo")
            .update()
    }
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("categories")
            .deleteConstraint(name: "foo")
            .update()
    }
}
