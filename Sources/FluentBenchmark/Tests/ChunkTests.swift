import NIOConcurrencyHelpers
import NIOCore
import XCTest

extension FluentBenchmarker {
    public func testChunk() throws {
        try self.testChunk_fetch()
    }

    private func testChunk_fetch() throws {
        try runTest(
            #function,
            [
                GalaxyMigration()
            ]
        ) {

            let saves = (1...512).map { i -> EventLoopFuture<Void> in
                return Galaxy(name: "Milky Way \(i)")
                    .save(on: self.database)
            }
            try EventLoopFuture<Void>.andAllSucceed(saves, on: self.database.eventLoop).wait()

            let fetched64 = NIOLockedValueBox<Int>(0)

            try Galaxy.query(on: self.database).chunk(max: 64) { chunk in
                guard chunk.count == 64 else {
                    XCTFail("bad chunk count")
                    return
                }
                fetched64.withLockedValue { $0 += chunk.count }
            }.wait()

            guard fetched64.withLockedValue({ $0 }) == 512 else {
                XCTFail("did not fetch all - only \(fetched64.withLockedValue { $0 }) out of 512")
                return
            }

            let fetched511 = NIOLockedValueBox<Int>(0)

            try Galaxy.query(on: self.database).chunk(max: 511) { chunk in
                guard chunk.count == 511 || chunk.count == 1 else {
                    XCTFail("bad chunk count")
                    return
                }
                fetched511.withLockedValue { $0 += chunk.count }
            }.wait()

            guard fetched511.withLockedValue({ $0 }) == 512 else {
                XCTFail("did not fetch all - only \(fetched511.withLockedValue { $0 }) out of 512")
                return
            }
        }
    }
}
