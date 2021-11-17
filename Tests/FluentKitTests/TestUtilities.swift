import XCTest

class DbQueryTestCase: XCTestCase {
    var db = DummyDatabaseForTestSQLSerializer()
    
    override func setUp() {
        db = DummyDatabaseForTestSQLSerializer()
    }
    
    override func tearDown() {
        db.reset()
    }
}

func assertQuery(
    _ db: DummyDatabaseForTestSQLSerializer,
    _ query: String,
    file: StaticString = #file,
    line: UInt = #line
) {
    XCTAssertEqual(db.sqlSerializers.count, 1, file: file, line: line)
    XCTAssertEqual(db.sqlSerializers.first?.sql, query, file: file, line: line)
}

func assertLastQuery(
    _ db: DummyDatabaseForTestSQLSerializer,
    _ query: String,
    file: StaticString = #file,
    line: UInt = #line
) {
    XCTAssertEqual(db.sqlSerializers.last?.sql, query, file: file, line: line)
}
