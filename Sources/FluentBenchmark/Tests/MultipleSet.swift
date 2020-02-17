extension FluentBenchmarker {
    public func testMultipleSet() throws {
        try runTest(#function, [
            TestMigration(),
        ]) {
            // Int value set first
            try Test.query(on: self.database)
                .set(\.$intValue, to: 1)
                .set(\.$stringValue, to: "a string")
                .update().wait()

            // String value set first
            try Test.query(on: self.database)
                .set(\.$stringValue, to: "a string")
                .set(\.$intValue, to: 1)
                .update().wait()
        }
    }
}

private final class Test: Model {
    static let schema = "test"

    @ID(key: FluentBenchmarker.idKey)
    var id: UUID?

    @Field(key: "int_value")
    var intValue: Int?

    @Field(key: "string_value")
    var stringValue: String?
}

private struct TestMigration: FluentKit.Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("test")
            .field("id", .uuid, .identifier(auto: false))
            .field("int_value", .int)
            .field("string_value", .string)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("test").delete()
    }
}
