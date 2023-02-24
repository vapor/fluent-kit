import FluentKit
import Foundation
import NIOCore
import XCTest

extension FluentBenchmarker {
    public func testPerformance(decimalType: DatabaseSchema.DataType = .string) throws {
        try self.testPerformance_largeModel(decimalType: decimalType)
        try self.testPerformance_siblings()
    }

    private func testPerformance_largeModel(decimalType: DatabaseSchema.DataType) throws {
        try runTest(#function, [
            FooMigration(decimalType: decimalType)
        ]) {
            for _ in 0..<100 {
                let foo = Foo(
                    bar: 42,
                    baz: 3.14159,
                    qux: "foobar",
                    quux: .init(),
                    quuz: 2.71828,
                    corge: [1, 2, 3],
                    grault: [4, 5, 6],
                    garply: ["foo", "bar", "baz"],
                    fred: 1.4142135623730950,
                    plugh: 1337,
                    xyzzy: 9.94987437106,
                    thud: .init(foo: 5, bar: 23, baz: "1994")
                )
                try foo.save(on: self.database).wait()
            }
            let foos = try Foo.query(on: self.database).all().wait()
            for foo in foos {
                XCTAssertNotNil(foo.id)
            }
            XCTAssertEqual(foos.count, 100)
        }
    }
}

private final class Foo: Model {
     static let schema = "foos"

     struct Thud: Codable {
         var foo: Int
         var bar: Double
         var baz: String
     }

     @ID(key: .id) var id: UUID?
     @Field(key: "bar") var bar: Int
     @Field(key: "baz") var baz: Double
     @Field(key: "qux") var qux: String
     @Field(key: "quux") var quux: Date
     @Field(key: "quuz") var quuz: Float
     @Field(key: "corge") var corge: [Int]
     @Field(key: "grault") var grault: [Double]
     @Field(key: "garply") var garply: [String]
     @Field(key: "fred") var fred: Decimal
     @Field(key: "plugh") var plugh: Int?
     @Field(key: "xyzzy") var xyzzy: Double?
     @Field(key: "thud") var thud: Thud

     init() { }

     init(
         id: UUID? = nil,
         bar: Int,
         baz: Double,
         qux: String,
         quux: Date,
         quuz: Float,
         corge: [Int],
         grault: [Double],
         garply: [String],
         fred: Decimal,
         plugh: Int?,
         xyzzy: Double?,
         thud: Thud
     ) {
         self.id = id
         self.bar = bar
         self.baz = baz
         self.qux = qux
         self.quux = quux
         self.quuz = quuz
         self.corge = corge
         self.grault = grault
         self.garply = garply
         self.fred = fred
         self.plugh = plugh
         self.xyzzy = xyzzy
         self.thud = thud
     }
}

private struct FooMigration: Migration {
    let decimalType: DatabaseSchema.DataType

    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("foos")
            .field("id", .uuid, .identifier(auto: false))
            .field("bar", .int, .required)
            .field("baz", .double, .required)
            .field("qux", .string, .required)
            .field("quux", .datetime, .required)
            .field("quuz", .float, .required)
            .field("corge", .array(of: .int), .required)
            .field("grault", .array(of: .double), .required)
            .field("garply", .array(of: .string), .required)
            .field("fred", self.decimalType, .required)
            .field("plugh", .int)
            .field("xyzzy", .double)
            .field("thud", .json, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("foos").delete()
    }
}
