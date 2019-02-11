import XCTest

@testable import FluentKitTests

// MARK: FluentKitTests

extension FluentKitTests {
	static let __allFluentKitTestsTests = [
        ("testStub", testStub),
	]
}

// MARK: Test Runner

#if !os(macOS)
public func __buildTestEntries() -> [XCTestCaseEntry] {
	return [
		// FluentKitTests
		testCase(FluentKitTests.__allFluentKitTestsTests),
	]
}

let tests = __buildTestEntries()
XCTMain(tests)
#endif

