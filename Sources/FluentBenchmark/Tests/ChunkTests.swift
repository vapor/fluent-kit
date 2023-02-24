import NIOCore
import XCTest

extension FluentBenchmarker {
    public func testChunk() throws {
        try self.testChunk_fetch()
    }

    private func testChunk_fetch() throws {
        try runTest(#function, [
            GalaxyMigration(),
        ]) {
            var fetched64: [Result<Galaxy, Error>] = []
            var fetched2047: [Result<Galaxy, Error>] = []

            let saves = (1...512).map { i -> EventLoopFuture<Void> in
                return Galaxy(name: "Milky Way \(i)")
                    .save(on: self.database)
            }
            try EventLoopFuture<Void>.andAllSucceed(saves, on: self.database.eventLoop).wait()

            try Galaxy.query(on: self.database).chunk(max: 64) { chunk in
                guard chunk.count == 64 else {
                    XCTFail("bad chunk count")
                    return
                }
                fetched64 += chunk
            }.wait()

            guard fetched64.count == 512 else {
                XCTFail("did not fetch all - only \(fetched64.count) out of 512")
                return
            }

            try Galaxy.query(on: self.database).chunk(max: 511) { chunk in
                guard chunk.count == 511 || chunk.count == 1 else {
                    XCTFail("bad chunk count")
                    return
                }
                fetched2047 += chunk
            }.wait()

            guard fetched2047.count == 512 else {
                XCTFail("did not fetch all - only \(fetched2047.count) out of 512")
                return
            }
        }
    }
}
