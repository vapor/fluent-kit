extension FluentBenchmarker {
    public func testMultipleSet() throws {
        try runTest(#function, [
            TestModel.Migration(),
        ]) {
            // Int value set first
            try TestModel.query(on: self.database)
                .set(\.$intValue, to: 1)
                .set(\.$stringValue, to: "a string")
                .update().wait()

            // String value set first
            try TestModel.query(on: self.database)
                .set(\.$stringValue, to: "a string")
                .set(\.$intValue, to: 1)
                .update().wait()
        }
    }
}

private final class TestModel: Model {
    struct Migration: FluentKit.Migration {
        func prepare(on database: Database) -> EventLoopFuture<Void> {
            return database.schema(TestModel.schema)
                .field("id", .int, .identifier(auto: true))
                .field("int_value", .int)
                .field("string_value", .string)
                .create()
        }

        func revert(on database: Database) -> EventLoopFuture<Void> {
            return database.schema(TestModel.schema).delete()
        }
    }
    static let schema = "test"

    @ID(key: "id")
    var id: Int?

    @Field(key: "int_value")
    var intValue: Int?

    @Field(key: "string_value")
    var stringValue: String?

}
