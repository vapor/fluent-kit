import FluentKit
import XCTest
import NIO

final class ModelTests: XCTestCase {
    private struct BatchInsertDatabaseOutput: DatabaseOutput {
        let value: Int
        
        init(_ value: Int) {
            self.value = value
        }
        
        func contains(field: String) -> Bool {
            return field == "id"
        }
        
        func decode<T>(field: String, as type: T.Type) throws -> T where T : Decodable {
            return value as! T
        }
        
        var description: String {
            return "\(value)"
        }
    }
    
    private struct BatchInsertDatabase: Database {
        var eventLoop: EventLoop {
            return EmbeddedEventLoop()
        }
        
        init() { }
        
        func execute(_ query: DatabaseQuery, _ onOutput: @escaping (DatabaseOutput) throws -> ()) -> EventLoopFuture<Void> {
            XCTAssertEqual(query.fields.count, 4)
            XCTAssertEqual(query.input.count, 2)
            let values1 = query.input[0]
            XCTAssertEqual(values1.count, 4)
            let values2 = query.input[1]
            XCTAssertEqual(values2.count, 4)


            switch query.fields[0] {
            case .field(path: let path, entity: let entity, alias: let alias):
                XCTAssertEqual(path, ["age"])
                XCTAssertEqual(entity, nil)
                XCTAssertEqual(alias, nil)
            default:
                XCTFail("\(query.fields[0]) should case \"\(DatabaseQuery.Field.field(path: ["age"], entity: nil, alias: nil))\"")
            }
            switch values1[0] {
            case .bind(let value):
                XCTAssertEqual(value as? Int, 21)
            default:
                XCTFail("\(values1[0]) should case \"\(DatabaseQuery.Value.bind(21))\"")
            }
            switch values2[0] {
            case .bind(let value):
                XCTAssertEqual(value as? Int, 22)
            default:
                XCTFail("\(values1[0]) should case \"\(DatabaseQuery.Value.bind(22))\"")
            }


            switch query.fields[1] {
            case .field(path: let path, entity: _, alias: _):
                XCTAssertEqual(path, ["created_at"])
            default:
                XCTFail("\(query.fields[1]) should case \"\(DatabaseQuery.Field.field(path: ["created_at"], entity: nil, alias: nil))\"")
            }


            switch query.fields[2] {
            case .field(path: let path, entity: _, alias: _):
                XCTAssertEqual(path, ["name"])
            default:
                XCTFail("\(query.fields[2]) should case \"\(DatabaseQuery.Field.field(path: ["name"], entity: nil, alias: nil))\"")
            }
            switch values1[2] {
            case .bind(let value):
                XCTAssertEqual(value as? String, "foo")
            default:
                XCTFail("\(values1[2]) should case \"\(DatabaseQuery.Value.bind("foo"))\"")
            }
            switch values2[2] {
            case .bind(let value):
                XCTAssertEqual(value as? String, "bar")
            default:
                XCTFail("\(values1[2]) should case \"\(DatabaseQuery.Value.bind("bar"))\"")
            }


            switch query.fields[3] {
            case .field(path: let path, entity: _, alias: _):
                XCTAssertEqual(path, ["updated_at"])
            default:
                XCTFail("\(query.fields[3]) should case \"\(DatabaseQuery.Field.field(path: ["updated_at"], entity: nil, alias: nil))\"")
            }

            do {
                try onOutput(BatchInsertDatabaseOutput(1))
                try onOutput(BatchInsertDatabaseOutput(2))
                return self.eventLoop.makeSucceededFuture(())
            } catch {
                return self.eventLoop.makeFailedFuture(error)
            }
        }

        func execute(_ schema: DatabaseSchema) -> EventLoopFuture<Void> {
            return self.eventLoop.makeSucceededFuture(())
        }
        
        func close() -> EventLoopFuture<Void> {
            return self.eventLoop.makeSucceededFuture(())
        }
        
        func withConnection<T>(_ closure: @escaping (Database) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
            return closure(self)
        }
    }
    
    final class BatchInsertModel: Model, Timestampable {
        static var shared = BatchInsertModel()
        static let entity = "my_table"
        
        let id = Field<Int?>("id")
        let createdAt = Field<Date?>("created_at")
        let updatedAt = Field<Date?>("updated_at")
        
        let name = Field<String>("name")
        let age = Field<Int>("age")
    }
    
    func testBatchInsert() throws {
        //
        let database = BatchInsertDatabase()
        
        //
        let row1 = Row<BatchInsertModel>()
        row1.set(\.name, to: "foo")
        row1.set(\.age, to: 21)
        
        let row2 = Row<BatchInsertModel>()
        row2.set(\.name, to: "bar")
        row2.set(\.age, to: 22)
        
        //
        XCTAssertNoThrow(try [row1, row2].create(on: database).wait())
        
        XCTAssertEqual(row1.get(\.id), 1)
        XCTAssertEqual(row2.get(\.id), 2)
    }
}
