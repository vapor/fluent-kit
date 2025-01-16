import FluentKit
import FluentSQL
import SQLKit
import XCTest
import XCTFluent

final class SQLTests: DbQueryTestCase {
    func testFetchFluentModels() async throws {
        let date1 = Date(), date2 = Date(), uuid1 = UUID(), uuid2 = UUID()
        
        self.db.fakedRows.append(contentsOf: [
            [
                .init([
                    "id": 1, "field": "a", "optfield": 0, "bool": true, "optbool": false,
                    "created_at": date1, "enum": Enum1.foo.rawValue, "optenum": Enum1.bar.rawValue,
                    "group_groupfield1": 32 as Int32, "group_groupfield2": 64 as Int64,
                ]),
                .init([
                    "id": 2, "field": "c", "optfield": nil, "bool": false, "optbool": nil,
                    "created_at": date2, "enum": Enum1.bar.rawValue, "optenum": nil,
                    "group_groupfield1": 64 as Int32, "group_groupfield2": 32 as Int64,
                ]),
            ],
            [
                .init(["id": 1, "field": Data([0, 1, 2, 3]), "model1_id": 1, "othermodel1_id": 2]),
                .init(["id": 2, "field": Data([4, 5, 6, 7]), "model1_id": 2, "othermodel1_id": nil]),
            ],
            [
                .init(["model1_id": 1, "model2_id": 1]),
            ],
            [
                .init(["field1": 1.0, "field2": uuid1, "pivot_model1_id": 1, "pivot_model2_id": 1, "optpivot_model1_id": 2, "optpivot_model2_id": 2]),
                .init(["field1": 2.0, "field2": uuid2, "pivot_model1_id": 2, "pivot_model2_id": 2, "optpivot_model1_id": nil, "optpivot_model2_id": nil]),
            ],
        ])

        let model1s = try await self.db.select().columns("*").from(Model1.schema).all(decodingFluent: Model1.self)
        let model2s = try await self.db.select().columns("*").from(Model2.schema).all(decodingFluent: Model2.self)
        let pivots = try await self.db.select().columns("*").from(Pivot.schema).all(decodingFluent: Pivot.self)
        let fromPivots = try await self.db.select().columns("*").from(FromPivot.schema).all(decodingFluent: FromPivot.self)
        
        XCTAssertEqual(model1s.count, 2)
        XCTAssertEqual(model2s.count, 2)
        XCTAssertEqual(pivots.count, 1)
        XCTAssertEqual(fromPivots.count, 2)
        
        let model1_1 = try XCTUnwrap(model1s.dropFirst(0).first)
        let model1_2 = try XCTUnwrap(model1s.dropFirst(1).first)
        let model2_1 = try XCTUnwrap(model2s.dropFirst(0).first)
        let model2_2 = try XCTUnwrap(model2s.dropFirst(1).first)
        let pivot = try XCTUnwrap(pivots.first)
        let fromPivot1 = try XCTUnwrap(fromPivots.dropFirst(0).first)
        let fromPivot2 = try XCTUnwrap(fromPivots.dropFirst(1).first)
        
        XCTAssertEqual(model1_1.$id.value, 1)
        XCTAssertEqual(model1_1.$field.value, "a")
        XCTAssertEqual(model1_1.$optField.value, .some(.some(0)))
        XCTAssertEqual(model1_1.$bool.value, true)
        XCTAssertEqual(model1_1.$optBool.value, .some(.some(false)))
        XCTAssertEqual(model1_1.$createdAt.value, .some(.some(date1)))
        XCTAssertEqual(model1_1.$enum.value, .foo)
        XCTAssertEqual(model1_1.$optEnum.value, .some(.some(.bar)))
        XCTAssertEqual(model1_1.$group.$groupfield1.value, 32)
        XCTAssertEqual(model1_1.$group.$groupfield2.value, 64)
        XCTAssertEqual(model1_1.$model2s.fromId, model1_1.$id.value)
        XCTAssertEqual(model1_1.$otherModel2.fromId, model1_1.$id.value)
        XCTAssertEqual(model1_1.$pivotedModels2.fromId, model1_1.$id.value)

        XCTAssertEqual(model1_2.$id.value, 2)
        XCTAssertEqual(model1_2.$field.value, "c")
        XCTAssertEqual(model1_2.$optField.value, .some(.none))
        XCTAssertEqual(model1_2.$bool.value, false)
        XCTAssertEqual(model1_2.$optBool.value, .some(.none))
        XCTAssertEqual(model1_2.$createdAt.value, .some(.some(date2)))
        XCTAssertEqual(model1_2.$enum.value, .bar)
        XCTAssertEqual(model1_2.$optEnum.value, .some(.none))
        XCTAssertEqual(model1_2.$group.$groupfield1.value, 64)
        XCTAssertEqual(model1_2.$group.$groupfield2.value, 32)
        XCTAssertEqual(model1_2.$model2s.fromId, model1_2.$id.value)
        XCTAssertEqual(model1_2.$otherModel2.fromId, model1_2.$id.value)
        XCTAssertEqual(model1_2.$pivotedModels2.fromId, model1_2.$id.value)
        
        XCTAssertEqual(model2_1.$id.value, 1)
        XCTAssertEqual(model2_1.$field.value, Data([0, 1, 2, 3]))
        XCTAssertEqual(model2_1.$model1.id, 1)
        XCTAssertEqual(model2_1.$otherModel1.id, 2)

        XCTAssertEqual(model2_2.$id.value, 2)
        XCTAssertEqual(model2_2.$field.value, Data([4, 5, 6, 7]))
        XCTAssertEqual(model2_2.$model1.id, 2)
        XCTAssertEqual(model2_2.$otherModel1.id, nil)
        
        XCTAssertEqual(pivot.$id.$model1.id, 1)
        XCTAssertEqual(pivot.$id.$model2.id, 1)
        
        XCTAssertEqual(fromPivot1.$id.$field1.value, 1.0)
        XCTAssertEqual(fromPivot1.$id.$field2.value, uuid1)
        XCTAssertEqual(fromPivot1.$pivot.id.$model1.$id.value, 1)
        XCTAssertEqual(fromPivot1.$pivot.id.$model2.$id.value, 1)
        XCTAssertEqual(fromPivot1.$optPivot.id?.$model1.$id.value, 2)
        XCTAssertEqual(fromPivot1.$optPivot.id?.$model2.$id.value, 2)

        XCTAssertEqual(fromPivot2.$id.$field1.value, 2.0)
        XCTAssertEqual(fromPivot2.$id.$field2.value, uuid2)
        XCTAssertEqual(fromPivot2.$pivot.id.$model1.$id.value, 2)
        XCTAssertEqual(fromPivot2.$pivot.id.$model2.$id.value, 2)
        XCTAssertEqual(fromPivot2.$optPivot.id?.$model1.$id.value, nil)
        XCTAssertEqual(fromPivot2.$optPivot.id?.$model2.$id.value, nil)
    }
    
    func testInsertFluentModels() async throws {
        let model1_1 = Model1(), model1_2 = Model1()
        model1_1.field = "a"
        model1_1.optField = 1
        model1_1.bool = true
        model1_1.optBool = false
        model1_1.createdAt = Date()
        model1_1.enum = .foo
        model1_1.optEnum = .bar
        model1_1.group.groupfield1 = 32
        model1_1.group.groupfield2 = 64
        model1_2.id = 2
        model1_2.field = "b"
        model1_2.optField = nil
        model1_2.bool = true
        model1_2.optBool = nil
        model1_2.createdAt = Date()
        model1_2.enum = .foo
        model1_2.optEnum = nil
        model1_2.group.groupfield1 = 32
        model1_2.group.groupfield2 = 64
        let model2_1 = Model2(), model2_2 = Model2()
        model2_1.field = Data([0])
        model2_1.$model1.id = 1
        model2_1.$otherModel1.id = 2
        model2_2.id = 2
        model2_2.field = Data([1])
        model2_2.$model1.id = 2
        model2_2.$otherModel1.id = nil
        let pivot = Pivot()
        pivot.id?.$model1.id = 1
        pivot.id?.$model2.id = 1
        let fromPivot1 = FromPivot(), fromPivot2 = FromPivot()
        fromPivot1.id?.field1 = 1.0
        fromPivot1.id?.field2 = UUID()
        fromPivot1.$pivot.id.$model1.id = 1
        fromPivot1.$pivot.id.$model2.id = 1
        fromPivot1.$optPivot.id = .init(model1Id: 2, model2Id: 2)
        fromPivot2.id?.field1 = 1.0
        fromPivot2.id?.field2 = UUID()
        fromPivot2.$pivot.id.$model1.id = 2
        fromPivot2.$pivot.id.$model2.id = 2
        fromPivot2.$optPivot.id = nil
        
        try await self.db.insert(into: Model1.schema).fluentModels([model1_1, model1_2]).run()
        try await self.db.insert(into: Model2.schema).fluentModels([model2_1, model2_2]).run()
        try await self.db.insert(into: Pivot.schema).fluentModel(pivot).run()
        try await self.db.insert(into: FromPivot.schema).fluentModels([fromPivot1, fromPivot2]).run()
        
        XCTAssertEqual(self.db.sqlSerializers.count, 4)
        XCTAssertEqual(self.db.sqlSerializers.dropFirst(0).first?.sql, #"INSERT INTO "model1s" ("bool", "created_at", "enum", "field", "group_groupfield1", "group_groupfield2", "id", "optbool", "optenum", "optfield") VALUES ($1, $2, 'foo', $3, $4, $5, DEFAULT, $6, 'bar', $7), ($8, $9, 'foo', $10, $11, $12, $13, NULL, NULL, NULL)"#)
        XCTAssertEqual(self.db.sqlSerializers.dropFirst(0).first?.binds.count, 13)
        XCTAssertEqual(self.db.sqlSerializers.dropFirst(1).first?.sql, #"INSERT INTO "model2s" ("field", "id", "model1_id", "othermodel1_id") VALUES ($1, DEFAULT, $2, $3), ($4, $5, $6, NULL)"#)
        XCTAssertEqual(self.db.sqlSerializers.dropFirst(1).first?.binds.count, 6)
        XCTAssertEqual(self.db.sqlSerializers.dropFirst(2).first?.sql, #"INSERT INTO "pivots" ("model1_id", "model2_id") VALUES ($1, $2)"#)
        XCTAssertEqual(self.db.sqlSerializers.dropFirst(2).first?.binds.count, 2)
        XCTAssertEqual(self.db.sqlSerializers.dropFirst(3).first?.sql, #"INSERT INTO "from_pivots" ("field1", "field2", "optpivot_model1_id", "optpivot_model2_id", "pivot_model1_id", "pivot_model2_id") VALUES ($1, $2, $3, $4, $5, $6), ($7, $8, NULL, NULL, $9, $10)"#)
        XCTAssertEqual(self.db.sqlSerializers.dropFirst(3).first?.binds.count, 10)
    }
}

enum Enum1: String, Codable {
    case foo, bar
}

final class AGroup: Fields, @unchecked Sendable {
    @Field(key: "groupfield1") var groupfield1: Int32
    @Field(key: "groupfield2") var groupfield2: Int64
}

final class Model1: Model, @unchecked Sendable {
    static let schema = "model1s"

    @ID(custom: .id) var id: Int?
    @Field(key: "field") var field: String
    @OptionalField(key: "optfield") var optField: Int?
    @Boolean(key: "bool") var bool
    @OptionalBoolean(key: "optbool") var optBool
    @Timestamp(key: "created_at", on: .create) var createdAt
    @Enum(key: "enum") var `enum`: Enum1
    @OptionalEnum(key: "optenum") var optEnum: Enum1?
    @Group(key: "group") var group: AGroup
    @Children(for: \.$model1) var model2s: [Model2]
    @OptionalChild(for: \.$otherModel1) var otherModel2: Model2?
    @Siblings(through: Pivot.self, from: \.$id.$model1, to: \.$id.$model2) var pivotedModels2: [Model2]

    init() {}
}

final class Model2: Model, @unchecked Sendable {
    static let schema = "model2s"

    @ID(custom: .id) var id: Int?
    @Field(key: "field") var field: Data
    @Parent(key: "model1_id") var model1: Model1
    @OptionalParent(key: "othermodel1_id") var otherModel1: Model1?
    @Siblings(through: Pivot.self, from: \.$id.$model2, to: \.$id.$model1) var pivotedModels1: [Model1]

    init() {}
}

final class Pivot: Model, @unchecked Sendable {
    static let schema = "pivots"

    final class IDValue: Fields, Hashable, @unchecked Sendable {
        @Parent(key: "model1_id") var model1: Model1
        @Parent(key: "model2_id") var model2: Model2

        init() {}
        init(model1Id: Model1.IDValue, model2Id: Model2.IDValue) { (self.$model1.id, self.$model2.id) = (model1Id, model2Id) }

        static func == (lhs: IDValue, rhs: IDValue) -> Bool { lhs.$model1.id == rhs.$model1.id && lhs.$model2.id == rhs.$model2.id }
        func hash(into hasher: inout Hasher) { hasher.combine(self.$model1.id); hasher.combine(self.$model2.id) }
    }

    @CompositeID var id: IDValue?
    @CompositeChildren(for: \.$pivot) var fromPivots: [FromPivot]
    @CompositeOptionalChild(for: \.$optPivot) var fromOptPivot: FromPivot?

    init() {}
    init(model1Id: Model1.IDValue, model2Id: Model2.IDValue) { self.id = .init(model1Id: model1Id, model2Id: model2Id) }
}

final class FromPivot: Model, @unchecked Sendable {
    static let schema = "from_pivots"
    
    final class IDValue: Fields, Hashable, @unchecked Sendable {
        @Field(key: "field1") var field1: Double
        @Field(key: "field2") var field2: UUID

        init() {}
        init(field1: Double, field2: UUID) { (self.field1, self.field2) = (field1, field2) }

        static func == (lhs: IDValue, rhs: IDValue) -> Bool { lhs.field1 == rhs.field1 && lhs.field2 == rhs.field2 }
        func hash(into hasher: inout Hasher) { hasher.combine(self.field1); hasher.combine(self.field2) }
    }
    
    @CompositeID var id: IDValue?
    @CompositeParent(prefix: "pivot", strategy: .snakeCase) var pivot: Pivot
    @CompositeOptionalParent(prefix: "optpivot", strategy: .snakeCase) var optPivot: Pivot?
    
    init() {}
    init(field1: Double, field2: UUID) { self.id = .init(field1: field1, field2: field2) }
}
