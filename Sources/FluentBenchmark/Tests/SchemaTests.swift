import FluentKit
import FluentSQL
import Foundation
import NIOCore
import SQLKit
import XCTest

extension FluentBenchmarker {
    public func testSchema(foreignKeys: Bool = true) throws {
        try self.testSchema_addConstraint()
        try self.testSchema_addNamedConstraint()
        if foreignKeys {
            try self.testSchema_fieldReference()
        }
        if self.database is any SQLDatabase {
            try self.testSchema_customSqlConstraints()
            try self.testSchema_customSqlFields()
            try self.testSchema_deleteConstraints()
        }
    }

    private func testSchema_addConstraint() throws {
        try self.runTest(
            #function,
            [
                CreateCategories()
            ]
        ) {
            guard let sql = self.database as? any SQLDatabase, sql.dialect.alterTableSyntax.allowsBatch else {
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
            } catch let error as any DatabaseError where error.isConstraintFailure {
                // pass
            }

            // Remove unique constraint
            try AddUniqueConstraintToCategories().revert(on: self.database).wait()
            try Category(name: "a").create(on: self.database).wait()
        }
    }

    private func testSchema_addNamedConstraint() throws {
        try self.runTest(
            #function,
            [
                CreateCategories()
            ]
        ) {
            guard let sql = self.database as? any SQLDatabase, sql.dialect.alterTableSyntax.allowsBatch else {
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
            } catch let error as any DatabaseError where error.isConstraintFailure {
                // pass
            }

            // Remove unique constraint
            try AddNamedUniqueConstraintToCategories().revert(on: self.database).wait()
            try Category(name: "a").create(on: self.database).wait()
        }
    }

    private func testSchema_fieldReference() throws {
        try self.runTest(
            #function,
            [
                SolarSystem()
            ]
        ) {
            XCTAssertThrowsError(
                try Star.query(on: self.database)
                    .filter(\.$name == "Sol")
                    .delete(force: true).wait()
            )
        }
    }

    private func testSchema_customSqlConstraints() throws {
        try self.runTest(
            #function,
            [
                DeleteTableMigration(name: "custom_constraints")
            ]
        ) {
            let normalized1 = (self.database as! any SQLDatabase).dialect.normalizeSQLConstraint(identifier: SQLIdentifier("id_unq_1"))

            try self.database.schema("custom_constraints")
                .id()

                // Test query string SQL for entire table constraints:
                .constraint(.sql(embed: "CONSTRAINT \(normalized1) UNIQUE (\(ident: "id"))"))

                // Test raw SQL for table constraint definitions (but not names):
                .constraint(.constraint(.sql(unsafeRaw: "UNIQUE (id)"), name: "id_unq_2"))
                .constraint(.constraint(.sql(embed: "UNIQUE (\(ident: "id"))"), name: "id_unq_3"))

                .create().wait()

            if (self.database as! any SQLDatabase).dialect.alterTableSyntax.allowsBatch {
                try self.database.schema("custom_constraints")
                    // Test raw SQL for dropping constraints:
                    .deleteConstraint(
                        .sql(embed: "\(SQLDropTypedConstraint(name: SQLIdentifier("id_unq_1"), algorithm: .sql(unsafeRaw: "")))")
                    )
                    .update().wait()
            }
        }
    }

    private func testSchema_customSqlFields() throws {
        try self.runTest(
            #function,
            [
                DeleteTableMigration(name: "custom_fields")
            ]
        ) {
            try self.database.schema("custom_fields")
                .id()

                // Test query string SQL for field data types:
                .field("morenotid", .sql(embed: "\(unsafeRaw: "TEXT")"))

                // Test raw SQL for field names:
                .field(.definition(name: .sql(embed: "\(ident: "stillnotid")"), dataType: .int, constraints: [.required]))

                // Test raw SQL for field constraints:
                .field("neverbeid", .string, .sql(embed: "NOT NULL"))

                // Test raw SQL for entire field definitions:
                .field(.sql(unsafeRaw: "idnah INTEGER NOT NULL"))
                .field(.sql(embed: "\(ident: "notid") INTEGER"))

                .create().wait()

            if (self.database as! any SQLDatabase).dialect.alterTableSyntax.allowsBatch {
                try self.database.schema("custom_fields")

                    // Test raw SQL for field updates:
                    .updateField(.sql(embed: "\(SQLAlterColumnDefinitionType(column: .init("notid"), dataType: .text))"))

                    .update().wait()
            }
        }
    }

    private func testSchema_deleteConstraints() throws {
        try self.runTest(
            #function,
            [
                CreateCategories(),
                DeleteTableMigration(name: "normal_constraints"),
            ]
        ) {
            try self.database.schema("normal_constraints")
                .id()

                .field("catid", .uuid)
                .foreignKey(["catid"], references: Category.schema, [.id], onDelete: .noAction, onUpdate: .noAction)
                .foreignKey(["catid"], references: Category.schema, [.id], onDelete: .noAction, onUpdate: .noAction, name: "second_fkey")
                .unique(on: "catid")
                .unique(on: "id", name: "second_ukey")

                .create().wait()

            if (self.database as! any SQLDatabase).dialect.alterTableSyntax.allowsBatch {
                try self.database.schema("normal_constraints")
                    // Test `DROP FOREIGN KEY` (MySQL) or `DROP CONSTRAINT` (Postgres)
                    .deleteConstraint(
                        .constraint(.foreignKey([.key("catid")], Category.schema, [.key(.id)], onDelete: .noAction, onUpdate: .noAction))
                    )
                    // Test name-based `DROP FOREIGN KEY` (MySQL)
                    .deleteForeignKey(name: "second_fkey")
                    // Test `DROP KEY` (MySQL) or `DROP CONSTRAINT` (Postgres)
                    .deleteUnique(on: "catid")
                    // Test name-based `DROP KEY` (MySQL) or `DROP CONSTRAINT` (Postgres)
                    .deleteConstraint(name: "second_ukey")

                    .update().wait()
            }
        }
    }
}

final class Category: Model, @unchecked Sendable {
    static let schema = "categories"
    @ID var id: UUID?
    @Field(key: "name") var name: String
    init() {}
    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
}

struct CreateCategories: Migration {
    func prepare(on database: any Database) -> EventLoopFuture<Void> {
        database.schema("categories")
            .id()
            .field("name", .string, .required)
            .create()
    }
    func revert(on database: any Database) -> EventLoopFuture<Void> {
        database.schema("categories")
            .delete()
    }
}

struct AddUniqueConstraintToCategories: Migration {
    func prepare(on database: any Database) -> EventLoopFuture<Void> {
        database.schema("categories")
            .unique(on: "name")
            .update()
    }
    func revert(on database: any Database) -> EventLoopFuture<Void> {
        database.schema("categories")
            .deleteUnique(on: "name")
            .update()
    }
}

struct AddNamedUniqueConstraintToCategories: Migration {
    func prepare(on database: any Database) -> EventLoopFuture<Void> {
        database.schema("categories")
            .unique(on: "name", name: "foo")
            .update()
    }
    func revert(on database: any Database) -> EventLoopFuture<Void> {
        database.schema("categories")
            .deleteConstraint(name: "foo")
            .update()
    }
}

/// Specialized utility used by the custom SQL tests, used to ensure they clean up after themselves.
struct DeleteTableMigration: Migration {
    let name: String

    func prepare(on database: any Database) -> EventLoopFuture<Void> {
        database.eventLoop.makeSucceededVoidFuture()
    }

    func revert(on database: any Database) -> EventLoopFuture<Void> {
        database.schema(self.name).delete()
    }
}
