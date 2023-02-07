import XCTest
import SQLKit

extension FluentBenchmarker {
    public func testCompositeParent() throws {
        try testCompositeParent_get()
        try testCompositeParent_eagerLoad()
    }

    private func testCompositeParent_get() throws {
        try self.runTest(#function, [
            CompositeIDModelMigration(),
            CompositeIDModelSeed(),
            CompositeIDChildModel.ModelMigration(),
            CompositeIDChildModel.ModelSeed(),
        ]) {
            let childModel = try XCTUnwrap(CompositeIDChildModel.query(on: self.database).first().wait())
            
            XCTAssertNotNil(childModel.$compositeIdModel.id.$name.value)
            XCTAssertNotNil(childModel.$compositeIdModel.id.$dimensions.value)
            
            let parentModel = try childModel.$compositeIdModel.get(on: self.database).wait()
            
            XCTAssertEqual(parentModel.id, childModel.$compositeIdModel.id)
        }
    }

    private func testCompositeParent_eagerLoad() throws {
        try self.runTest(#function, [
            CompositeIDModelMigration(),
            CompositeIDModelSeed(),
            CompositeIDChildModel.ModelMigration(),
            CompositeIDChildModel.ModelSeed(),
        ]) {
            let childModel = try XCTUnwrap(CompositeIDChildModel.query(on: self.database).with(\.$compositeIdModel).first().wait())
            
            XCTAssertNotNil(childModel.$compositeIdModel.id.$name.value)
            XCTAssertNotNil(childModel.$compositeIdModel.id.$dimensions.value)
            
            let loadedParentModel = try XCTUnwrap(childModel.$compositeIdModel.value)
            XCTAssertEqual(loadedParentModel.id, childModel.$compositeIdModel.id)
        }
    }
}

public final class CompositeIDChildModel: Model {
    public static let schema = "composite_id_child_models"
    
    @ID(custom: .id)
    public var id: Int?
    
    @CompositeParent(prefix: "comp_id_model", strategy: .snakeCase)
    public var compositeIdModel: CompositeIDModel
    
    public init() {}
    
    public init(id: Int? = nil, compositeIdModelId: CompositeIDModel.IDValue) {
        self.id = id
        self.$compositeIdModel.id = compositeIdModelId
    }
    
    public struct ModelMigration: Migration {
        public init() {}
        
        public func prepare(on database: Database) -> EventLoopFuture<Void> {
            database.schema(CompositeIDChildModel.schema)
                .field(.id, .int, .required, .identifier(auto: (database as? SQLDatabase)?.dialect.name != "sqlite"))
                .field("comp_id_model_name", .string, .required)
                .field("comp_id_model_dimensions", .int, .required)
                .foreignKey(["comp_id_model_name", "comp_id_model_dimensions"], references: CompositeIDModel.schema, ["name", "dimensions"], onDelete: .cascade, onUpdate: .cascade)
                .create()
        }
        
        public func revert(on database: Database) -> EventLoopFuture<Void> {
            database.schema(CompositeIDChildModel.schema).delete()
        }
    }
    
    public struct ModelSeed: Migration {
        public init() {}
        
        public func prepare(on database: Database) -> EventLoopFuture<Void> {
            [
                CompositeIDChildModel(compositeIdModelId: .init(name: "A", dimensions: 1)),
                CompositeIDChildModel(compositeIdModelId: .init(name: "B", dimensions: 1)),
            ].create(on: database)
        }
        
        public func revert(on database: Database) -> EventLoopFuture<Void> {
            CompositeIDChildModel.query(on: database).delete()
        }
    }
}
