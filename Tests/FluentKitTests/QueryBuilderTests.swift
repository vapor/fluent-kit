import FluentKit
import FluentBenchmark
import XCTest

final class QueryBuilderTests: XCTestCase {
    final class MyModel: Model, Timestampable {
        static var shared = MyModel()
        static let entity = "my_table"
        
        let id = Field<Int?>("id")
        let createdAt = Field<Date?>("created_at")
        let updatedAt = Field<Date?>("updated_at")
        
        let name = Field<String>("name")
        let age = Field<Int>("age")
    }

    func testMultiSet() throws {
        let builder = QueryBuilder<MyModel>(database: DummyDatabase())
        
        let now = Date()
        
        builder.set(\.name, to: "foo")
        builder.set(\.updatedAt, to: now)
        
        XCTAssertEqual(builder.query.fields.count, 2)
        
        switch builder.query.fields[0] {
        case .field(path: let path, entity: let entity, alias: let alias):
            XCTAssertEqual(path, ["name"])
            XCTAssertEqual(entity, nil)
            XCTAssertEqual(alias, nil)
        default:
            XCTFail("\(builder.query.fields[0]) should case \"\(DatabaseQuery.Field.field(path: ["name"], entity: nil, alias: nil))\"")
        }
        
        switch builder.query.fields[1] {
        case .field(path: let path, entity: let entity, alias: let alias):
            XCTAssertEqual(path, ["updated_at"])
            XCTAssertEqual(entity, nil)
            XCTAssertEqual(alias, nil)
        default:
            XCTFail("\(builder.query.fields[1]) should case \"\(DatabaseQuery.Field.field(path: ["updated_at"], entity: nil, alias: nil))\"")
        }
        
        XCTAssertEqual(builder.query.input.count, 1)
        let values = builder.query.input[0]
        XCTAssertEqual(values.count, 2)
        
        switch values[0] {
        case .bind(let value):
            XCTAssertEqual(value as? String, "foo")
        default:
            XCTFail("\(values[0]) should case \"\(DatabaseQuery.Value.bind("foo"))\"")
        }
        
        switch values[1] {
        case .bind(let value):
            XCTAssertEqual(value as? Date, now)
        default:
            XCTFail("\(values[1]) should case \"\(DatabaseQuery.Value.bind(now))\"")
        }
    }
}
