import XCTest
import Logging

class DbQueryTestCase: XCTestCase {
    var db = DummyDatabaseForTestSQLSerializer()
    
    override class func setUp() {
        super.setUp()
        XCTAssertTrue(isLoggingConfigured)
    }

    override func setUp() {
        self.db = DummyDatabaseForTestSQLSerializer()
    }
    
    override func tearDown() {
        self.db.reset()
    }
}

func assertQuery(
    _ db: DummyDatabaseForTestSQLSerializer,
    _ query: String,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    XCTAssertEqual(db.sqlSerializers.count, 1, file: file, line: line)
    XCTAssertEqual(db.sqlSerializers.first?.sql, query, file: file, line: line)
}

func assertLastQuery(
    _ db: DummyDatabaseForTestSQLSerializer,
    _ query: String,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    XCTAssertEqual(db.sqlSerializers.last?.sql, query, file: file, line: line)
}

func env(_ name: String) -> String? {
    return ProcessInfo.processInfo.environment[name]
}

let isLoggingConfigured: Bool = {
    LoggingSystem.bootstrap {
        var handler = StreamLogHandler.standardOutput(label: $0)
        handler.logLevel = env("LOG_LEVEL").flatMap { .init(rawValue: $0) } ?? .info
        return handler
    }
    return true
}()
