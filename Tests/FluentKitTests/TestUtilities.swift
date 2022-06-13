import XCTest
import Logging

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

func env(_ name: String) -> String? {
    return ProcessInfo.processInfo.environment[name]
}

let isLoggingConfigured: Bool = {
    LoggingSystem.bootstrap { label in
        var handler = StreamLogHandler.standardOutput(label: label)
        handler.logLevel = env("LOG_LEVEL").flatMap { Logger.Level(rawValue: $0) } ?? .info
        return handler
    }
    return true
}()
