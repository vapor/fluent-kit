import XCTest
import SQLKit
import FluentKit

extension FluentBenchmarker {
    public func testCompositeRelations() throws {
        try testCompositeParent_loading()
        try testCompositeChildren_loading()
        try testCompositeParent_nestedInCompositeID()
    }

    private func testCompositeParent_loading() throws {
        try self.runTest(#function, [
            CompositeIDParentModel.ModelMigration(),
            CompositeIDParentModel.ModelSeed(),
            CompositeIDChildModel.ModelMigration(),
            CompositeIDChildModel.ModelSeed(),
        ]) {
            let child1 = try XCTUnwrap(CompositeIDChildModel.find(1, on: self.database).wait())
            let child2 = try XCTUnwrap(CompositeIDChildModel.find(2, on: self.database).wait())
            
            XCTAssertEqual(child1.$compositeIdParentModel.id, .init(name: "A"))
            XCTAssertNil(child1.$additionalCompositeIdParentModel.id)
            XCTAssertEqual(child1.$linkedCompositeIdParentModel.id, .init(name: "A"))
            XCTAssertNil(child1.$additionalLinkedCompositeIdParentModel.id)

            XCTAssertEqual(child2.$compositeIdParentModel.id, .init(name: "A"))
            XCTAssertEqual(child2.$additionalCompositeIdParentModel.id, .init(name: "B"))
            XCTAssertEqual(child2.$linkedCompositeIdParentModel.id, .init(name: "B"))
            XCTAssertEqual(child2.$additionalLinkedCompositeIdParentModel.id, .init(name: "A"))
            
            XCTAssertEqual(try child1.$compositeIdParentModel.get(on: self.database).wait().id, child1.$compositeIdParentModel.id)
            XCTAssertNil(try child1.$additionalCompositeIdParentModel.get(on: self.database).wait())
            XCTAssertEqual(try child1.$linkedCompositeIdParentModel.get(on: self.database).wait().id, child1.$linkedCompositeIdParentModel.id)
            XCTAssertNil(try child1.$additionalLinkedCompositeIdParentModel.get(on: self.database).wait())

            XCTAssertEqual(try child2.$compositeIdParentModel.get(on: self.database).wait().id, child2.$compositeIdParentModel.id)
            XCTAssertEqual(try child2.$additionalCompositeIdParentModel.get(on: self.database).wait()?.id, child2.$additionalCompositeIdParentModel.id)
            XCTAssertEqual(try child2.$linkedCompositeIdParentModel.get(on: self.database).wait().id, child2.$linkedCompositeIdParentModel.id)
            XCTAssertEqual(try child2.$additionalLinkedCompositeIdParentModel.get(on: self.database).wait()?.id, child2.$additionalLinkedCompositeIdParentModel.id)
            
            let child3 = try XCTUnwrap(CompositeIDChildModel.query(on: self.database).filter(\.$id == 1).with(\.$compositeIdParentModel).with(\.$additionalCompositeIdParentModel).with(\.$linkedCompositeIdParentModel).with(\.$additionalLinkedCompositeIdParentModel).first().wait())
            let child4 = try XCTUnwrap(CompositeIDChildModel.query(on: self.database).filter(\.$id == 2).with(\.$compositeIdParentModel).with(\.$additionalCompositeIdParentModel).with(\.$linkedCompositeIdParentModel).with(\.$additionalLinkedCompositeIdParentModel).first().wait())
            
            XCTAssertEqual(child3.$compositeIdParentModel.value?.id, child3.$compositeIdParentModel.id)
            XCTAssertNil(child3.$additionalCompositeIdParentModel.value??.id)
            XCTAssertEqual(child3.$linkedCompositeIdParentModel.value?.id, child3.$linkedCompositeIdParentModel.id)
            XCTAssertNil(child3.$additionalLinkedCompositeIdParentModel.value??.id)

            XCTAssertEqual(child4.$compositeIdParentModel.value?.id, child4.$compositeIdParentModel.id)
            XCTAssertEqual(child4.$additionalCompositeIdParentModel.value??.id, child4.$additionalCompositeIdParentModel.id)
            XCTAssertEqual(child4.$linkedCompositeIdParentModel.value?.id, child4.$linkedCompositeIdParentModel.id)
            XCTAssertEqual(child4.$additionalLinkedCompositeIdParentModel.value??.id, child4.$additionalLinkedCompositeIdParentModel.id)
        }
    }

    private func testCompositeChildren_loading() throws {
        try self.runTest(#function, [
            CompositeIDParentModel.ModelMigration(),
            CompositeIDParentModel.ModelSeed(),
            CompositeIDChildModel.ModelMigration(),
            CompositeIDChildModel.ModelSeed(),
        ]) {
            let parent1 = try XCTUnwrap(CompositeIDParentModel.query(on: self.database).filter(\.$id.$name == "A").first().wait())
            let parent2 = try XCTUnwrap(CompositeIDParentModel.query(on: self.database).filter(\.$id.$name == "B").first().wait())
            let parent3 = try XCTUnwrap(CompositeIDParentModel.query(on: self.database).filter(\.$id.$name == "C").first().wait())
            
            let children1_1 = try parent1.$compositeIdChildModels.get(on: self.database).wait()
            let children1_2 = try parent1.$additionalCompositeIdChildModels.get(on: self.database).wait()
            let children1_3 = try parent1.$linkedCompositeIdChildModel.get(on: self.database).wait()
            let children1_4 = try parent1.$additionalLinkedCompositeIdChildModel.get(on: self.database).wait()
            
            let children2_1 = try parent2.$compositeIdChildModels.get(on: self.database).wait()
            let children2_2 = try parent2.$additionalCompositeIdChildModels.get(on: self.database).wait()
            let children2_3 = try parent2.$linkedCompositeIdChildModel.get(on: self.database).wait()
            let children2_4 = try parent2.$additionalLinkedCompositeIdChildModel.get(on: self.database).wait()

            let children3_1 = try parent3.$compositeIdChildModels.get(on: self.database).wait()
            let children3_2 = try parent3.$additionalCompositeIdChildModels.get(on: self.database).wait()
            let children3_3 = try parent3.$linkedCompositeIdChildModel.get(on: self.database).wait()
            let children3_4 = try parent3.$additionalLinkedCompositeIdChildModel.get(on: self.database).wait()
            
            XCTAssertEqual(children1_1.compactMap(\.id).sorted(), [1, 2, 3])
            XCTAssertTrue(children1_2.isEmpty)
            XCTAssertEqual(children1_3?.id, 1)
            XCTAssertEqual(children1_4?.id, 2)
            
            XCTAssertTrue(children2_1.isEmpty)
            XCTAssertEqual(children2_2.compactMap(\.id).sorted(), [2, 3])
            XCTAssertEqual(children2_3?.id, 2)
            XCTAssertEqual(children2_4?.id, 3)
            
            XCTAssertTrue(children3_1.isEmpty)
            XCTAssertTrue(children3_2.isEmpty)
            XCTAssertEqual(children3_3?.id, 3)
            XCTAssertNil(children3_4)

            let parent4 = try XCTUnwrap(CompositeIDParentModel.query(on: self.database).filter(\.$id.$name == "A").with(\.$compositeIdChildModels).with(\.$additionalCompositeIdChildModels).with(\.$linkedCompositeIdChildModel).with(\.$additionalLinkedCompositeIdChildModel).first().wait())
            let parent5 = try XCTUnwrap(CompositeIDParentModel.query(on: self.database).filter(\.$id.$name == "B").with(\.$compositeIdChildModels).with(\.$additionalCompositeIdChildModels).with(\.$linkedCompositeIdChildModel).with(\.$additionalLinkedCompositeIdChildModel).first().wait())
            let parent6 = try XCTUnwrap(CompositeIDParentModel.query(on: self.database).filter(\.$id.$name == "C").with(\.$compositeIdChildModels).with(\.$additionalCompositeIdChildModels).with(\.$linkedCompositeIdChildModel).with(\.$additionalLinkedCompositeIdChildModel).first().wait())
            
            XCTAssertEqual(parent4.$compositeIdChildModels.value?.compactMap(\.id).sorted(), [1, 2, 3])
            XCTAssertTrue(parent4.$additionalCompositeIdChildModels.value?.isEmpty ?? false)
            XCTAssertEqual(parent4.$linkedCompositeIdChildModel.value??.id, 1)
            XCTAssertEqual(parent4.$additionalLinkedCompositeIdChildModel.value??.id, 2)
            
            XCTAssertTrue(parent5.$compositeIdChildModels.value?.isEmpty ?? false)
            XCTAssertEqual(parent5.$additionalCompositeIdChildModels.value?.compactMap(\.id).sorted(), [2, 3])
            XCTAssertEqual(parent5.$linkedCompositeIdChildModel.value??.id, 2)
            XCTAssertEqual(parent5.$additionalLinkedCompositeIdChildModel.value??.id, 3)
            
            XCTAssertTrue(parent6.$compositeIdChildModels.value?.isEmpty ?? false)
            XCTAssertTrue(parent6.$additionalCompositeIdChildModels.value?.isEmpty ?? false)
            XCTAssertEqual(parent6.$linkedCompositeIdChildModel.value??.id, 3)
            XCTAssertNil(parent6.$additionalLinkedCompositeIdChildModel.value??.id)
        }
    }
    
    private func testCompositeParent_nestedInCompositeID() throws {
        try self.runTest(#function, [
            GalaxyMigration(),
            GalaxySeed(),
            CompositeParentTheFirst.ModelMigration(),
            CompositeParentTheSecond.ModelMigration(),
        ]) {
            let anyGalaxy = try XCTUnwrap(Galaxy.query(on: self.database).first().wait())
            
            let parentFirst = CompositeParentTheFirst(parentId: try anyGalaxy.requireID())
            try parentFirst.create(on: self.database).wait()
            
            let parentSecond = CompositeParentTheSecond(parentId: try parentFirst.requireID())
            try parentSecond.create(on: self.database).wait()
            
            XCTAssertEqual(try CompositeParentTheFirst.query(on: self.database).filter(\.$id == parentFirst.requireID()).count().wait(), 1)
            
            let parentFirstAgain = try XCTUnwrap(CompositeParentTheFirst.query(on: self.database).filter(\.$id.$parent.$id == anyGalaxy.requireID()).with(\.$id.$parent).with(\.$children).first().wait())
            
            XCTAssertEqual(parentFirstAgain.id?.$parent.value?.id, anyGalaxy.id)
            XCTAssertEqual(parentFirstAgain.$children.value?.first?.id?.$parent.id, parentFirstAgain.id)
            
            try Galaxy.query(on: self.database).filter(\.$id == anyGalaxy.requireID()).delete(force: true).wait()
            
            XCTAssertEqual(try CompositeParentTheFirst.query(on: self.database).count().wait(), 0)
            XCTAssertEqual(try CompositeParentTheSecond.query(on: self.database).count().wait(), 0)
        }
    }
}

final class CompositeIDParentModel: Model {
    static let schema = "composite_id_parent_models"
    
    final class IDValue: Fields, Hashable {
        @Field(key: "name")
        var name: String
        
        @Field(key: "dimensions")
        var dimensions: Int
        
        init() {}
        
        init(name: String, dimensions: Int = 1) {
            self.name = name
            self.dimensions = dimensions
        }
        
        static func == (lhs: IDValue, rhs: IDValue) -> Bool {
            lhs.name == rhs.name && lhs.dimensions == rhs.dimensions
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(self.name)
            hasher.combine(self.dimensions)
        }
    }
    
    @CompositeID
    var id: IDValue?
    
    @CompositeChildren(for: \.$compositeIdParentModel) // Children referencing required composite parent
    var compositeIdChildModels: [CompositeIDChildModel]
    
    @CompositeChildren(for: \.$additionalCompositeIdParentModel) // Children referencing optional composite parent
    var additionalCompositeIdChildModels: [CompositeIDChildModel]
    
    @CompositeOptionalChild(for: \.$linkedCompositeIdParentModel) // Optional child referencing required composite parent
    var linkedCompositeIdChildModel: CompositeIDChildModel?
    
    @CompositeOptionalChild(for: \.$additionalLinkedCompositeIdParentModel) // Optional child referencing optional composite parent
    var additionalLinkedCompositeIdChildModel: CompositeIDChildModel?
    
    init() {}
    
    init(id: IDValue) {
        self.id = id
    }
    
    convenience init(name: String, dimensions: Int) {
        self.init(id: .init(name: name, dimensions: dimensions))
    }

    struct ModelMigration: Migration {
        func prepare(on database: Database) -> EventLoopFuture<Void> {
            database.schema(CompositeIDParentModel.schema)
                .field("name", .string, .required)
                .field("dimensions", .int, .required)
                .compositeIdentifier(over: "name", "dimensions")
                .create()
        }
        
        func revert(on database: Database) -> EventLoopFuture<Void> {
            database.schema(CompositeIDParentModel.schema)
                .delete()
        }
    }

    struct ModelSeed: Migration {
        func prepare(on database: Database) -> EventLoopFuture<Void> {
            [
                CompositeIDParentModel(name: "A", dimensions: 1),
                CompositeIDParentModel(name: "B", dimensions: 1),
                CompositeIDParentModel(name: "C", dimensions: 1),
            ].map { $0.create(on: database) }.flatten(on: database.eventLoop)
        }
        
        func revert(on database: Database) -> EventLoopFuture<Void> {
            CompositeIDParentModel.query(on: database).delete()
        }
    }
}

final class CompositeIDChildModel: Model {
    static let schema = "composite_id_child_models"
    
    @ID(custom: .id)
    var id: Int?
    
    @CompositeParent(prefix: "comp_parent_model", strategy: .snakeCase) // required composite parent referencing multiple children
    var compositeIdParentModel: CompositeIDParentModel
    
    @CompositeOptionalParent(prefix: "addl_comp_parent_model", strategy: .snakeCase) // optional composite parent referencing multiple children
    var additionalCompositeIdParentModel: CompositeIDParentModel?
    
    @CompositeParent(prefix: "comp_linked_model", strategy: .snakeCase) // required composite parent referencing one optional child
    var linkedCompositeIdParentModel: CompositeIDParentModel
    
    @CompositeOptionalParent(prefix: "addl_comp_linked_model", strategy: .snakeCase) // optional composite parent referencing one optional child
    var additionalLinkedCompositeIdParentModel: CompositeIDParentModel?
    
    init() {}
    
    init(
        id: Int? = nil,
        parentId: CompositeIDParentModel.IDValue,
        additionalParentId: CompositeIDParentModel.IDValue?,
        linkedId: CompositeIDParentModel.IDValue,
        additionalLinkedId: CompositeIDParentModel.IDValue?
    ) {
        self.id = id
        self.$compositeIdParentModel.id = parentId
        self.$additionalCompositeIdParentModel.id = additionalParentId
        self.$linkedCompositeIdParentModel.id = linkedId
        self.$additionalLinkedCompositeIdParentModel.id = additionalLinkedId
    }
    
    struct ModelMigration: Migration {
        func prepare(on database: Database) -> EventLoopFuture<Void> {
            database.schema(CompositeIDChildModel.schema)
                .field(.id, .int, .required, .identifier(auto: (database as? SQLDatabase)?.dialect.name != "sqlite"))

                .field("comp_parent_model_name", .string, .required)
                .field("comp_parent_model_dimensions", .int, .required)
                .foreignKey(["comp_parent_model_name", "comp_parent_model_dimensions"],
                    references: CompositeIDParentModel.schema, ["name", "dimensions"]
                )

                .field("addl_comp_parent_model_name", .string)
                .field("addl_comp_parent_model_dimensions", .int)
                .constraint(.optionalCompositeReferenceCheck("addl_comp_parent_model_name", "addl_comp_parent_model_dimensions"))
                .foreignKey(["addl_comp_parent_model_name", "addl_comp_parent_model_dimensions"],
                    references: CompositeIDParentModel.schema, ["name", "dimensions"]
                )

                .field("comp_linked_model_name", .string, .required)
                .field("comp_linked_model_dimensions", .int, .required)
                .unique(on: "comp_linked_model_name", "comp_linked_model_dimensions")
                .foreignKey(["comp_linked_model_name", "comp_linked_model_dimensions"],
                    references: CompositeIDParentModel.schema, ["name", "dimensions"]
                )
                
                .field("addl_comp_linked_model_name", .string)
                .field("addl_comp_linked_model_dimensions", .int)
                .unique(on: "addl_comp_linked_model_name", "addl_comp_linked_model_dimensions")
                .constraint(.optionalCompositeReferenceCheck("addl_comp_linked_model_name", "addl_comp_linked_model_dimensions"))
                .foreignKey(["addl_comp_linked_model_name", "addl_comp_linked_model_dimensions"],
                    references: CompositeIDParentModel.schema, ["name", "dimensions"]
                )
                .create()
        }
        
        func revert(on database: Database) -> EventLoopFuture<Void> {
            database.schema(CompositeIDChildModel.schema).delete()
        }
    }
    
    struct ModelSeed: Migration {
        func prepare(on database: Database) -> EventLoopFuture<Void> {
            [
                CompositeIDChildModel(id: 1, parentId: .init(name: "A"), additionalParentId: nil,              linkedId: .init(name: "A"), additionalLinkedId: nil),
                CompositeIDChildModel(id: 2, parentId: .init(name: "A"), additionalParentId: .init(name: "B"), linkedId: .init(name: "B"), additionalLinkedId: .init(name: "A")),
                CompositeIDChildModel(id: 3, parentId: .init(name: "A"), additionalParentId: .init(name: "B"), linkedId: .init(name: "C"), additionalLinkedId: .init(name: "B")),
            ].create(on: database)
        }
        
        func revert(on database: Database) -> EventLoopFuture<Void> {
            CompositeIDChildModel.query(on: database).delete()
        }
    }
}

extension DatabaseSchema.Constraint {
    /// Convenience overload of `optionalCompositeReferenceCheck(_:)`.
    static func optionalCompositeReferenceCheck(_ field1: FieldKey, _ field2: FieldKey, _ moreFields: FieldKey...) -> DatabaseSchema.Constraint {
        return self.optionalCompositeReferenceCheck([field1, field2] + moreFields)
    }

    /// Returns a `CHECK` constraint whose condition requires that none of the provided fields be NULL
    /// unless all of them are. This is useful for guaranteeing that the columns making up a NULLable
    /// multi-column foreign key never specify only a partial key (even if such a key is permitted by
    /// the database itself, Fluent's relations make no attempt to support it).
    static func optionalCompositeReferenceCheck<C>(_ fields: C) -> DatabaseSchema.Constraint where C: Collection, C.Element == FieldKey {
        guard fields.count > 1 else { fatalError("A composite reference check must cover at least two fields.") }
        let fields = fields.map { SQLIdentifier($0.description) }
        
        return .sql(.check(SQLGroupExpression(SQLBinaryExpression(
            SQLGroupExpression(SQLBinaryExpression(fields.first!, .is, SQLLiteral.null)),
            .equal,
            SQLGroupExpression(SQLBinaryExpression(SQLFunction.coalesce([SQLLiteral.null] + fields.dropFirst().map{$0}), .is, SQLLiteral.null))
        ))))
    }
}

final class CompositeParentTheFirst: Model {
    static let schema = "composite_parent_the_first"
    
    final class IDValue: Fields, Hashable {
        @Parent(key: "parent_id")
        var parent: Galaxy
        
        init() {}
        
        init(parentId: Galaxy.IDValue) {
            self.$parent.id = parentId
        }
        
        static func == (lhs: IDValue, rhs: IDValue) -> Bool {
            lhs.$parent.id == rhs.$parent.id
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(self.$parent.id)
        }
    }
    
    @CompositeID
    var id: IDValue?
    
    @CompositeChildren(for: \.$id.$parent)
    var children: [CompositeParentTheSecond]
    
    init() {}
    
    init(parentId: Galaxy.IDValue) {
        self.id = .init(parentId: parentId)
    }
    
    struct ModelMigration: Migration {
        func prepare(on database: Database) -> EventLoopFuture<Void> {
            database.schema(CompositeParentTheFirst.schema)
                .field("parent_id", .uuid, .required)
                .foreignKey("parent_id", references: Galaxy.schema, .id, onDelete: .cascade, onUpdate: .cascade)
                .compositeIdentifier(over: "parent_id")
                .create()
        }
        
        func revert(on database: Database) -> EventLoopFuture<Void> {
            database.schema(CompositeParentTheFirst.schema)
                .delete()
        }
    }
}

final class CompositeParentTheSecond: Model {
    static let schema = "composite_parent_the_second"
    
    final class IDValue: Fields, Hashable {
        @CompositeParent(prefix: "ref", strategy: .snakeCase)
        var parent: CompositeParentTheFirst

        init() {}

        init(parentId: CompositeParentTheFirst.IDValue) {
            self.$parent.id.$parent.id = parentId.$parent.id
        }

        static func == (lhs: IDValue, rhs: IDValue) -> Bool {
            lhs.$parent.id == rhs.$parent.id
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(self.$parent.id)
        }
    }
    
    @CompositeID
    var id: IDValue?
    
    init() {}
    
    init(parentId: CompositeParentTheFirst.IDValue) {
        self.id = .init(parentId: parentId)
    }
    
    struct ModelMigration: Migration {
        func prepare(on database: Database) -> EventLoopFuture<Void> {
            database.schema(CompositeParentTheSecond.schema)
                .field("ref_parent_id", .uuid, .required)
                .foreignKey("ref_parent_id", references: CompositeParentTheFirst.schema, "parent_id", onDelete: .cascade, onUpdate: .cascade)
                .compositeIdentifier(over: "ref_parent_id")
                .create()
        }
        
        func revert(on database: Database) -> EventLoopFuture<Void> {
            database.schema(CompositeParentTheSecond.schema)
                .delete()
        }
    }
}
