//extension FluentBenchmarker {
//    public func testNestedField() throws {
//        try runTest(#function, [
//            UserMigration(),
//            UserSeed()
//        ]) {
//            let users = try User.query(on: self.database)
//                .filter(\.$pet.$type == .cat)
//                .all().wait()
//
//            guard let user = users.first, users.count == 1 else {
//                XCTFail("Unexpected user count: \(users.count)")
//                return
//            }
//            XCTAssertEqual(user.name, "Tanner")
//            XCTAssertEqual(user.pet.name, "Ziz")
//            XCTAssertEqual(user.pet.type, .cat)
//
//            struct UserJSON: Equatable, Codable {
//                var id: UUID
//                var name: String
//                var pet: PetJSON
//            }
//            struct PetJSON: Equatable, Codable {
//                var name: String
//                var type: String
//            }
//            let expected = UserJSON(
//                id: user.id!,
//                name: "Tanner",
//                pet: .init(name: "Ziz", type: "cat")
//            )
//            let decoded = try JSONDecoder().decode(UserJSON.self, from: JSONEncoder().encode(user))
//            XCTAssertEqual(decoded, expected)
//        }
//    }
//}
//
//private final class User: Model {
//    static let schema = "users"
//
//    @ID(key: .id)
//    var id: UUID?
//
//    @Field(key: "name")
//    var name: String
//
//    @NestedField(key: "pet")
//    var pet: Pet
//
//    init() { }
//
//    init(id: IDValue? = nil, name: String, pet: Pet) {
//        self.id = id
//        self.name = name
//        self.pet = pet
//    }
//}
//
//private final class Pet: Fields {
//    @Field(key: "name")
//    var name: String
//
//    @Field(key: "type")
//    var type: Animal
//
//    init() { }
//
//    init(name: String, type: Animal) {
//        self.name = name
//        self.type = type
//    }
//}
//
//private enum Animal: String, Codable {
//    case cat, dog
//}
//
//private struct UserMigration: Migration {
//    func prepare(on database: Database) -> EventLoopFuture<Void> {
//        database.schema("users")
//            .field("id", .uuid, .identifier(auto: false))
//            .field("name", .string, .required)
//            .field("pet", .json, .required)
//            .create()
//    }
//
//    func revert(on database: Database) -> EventLoopFuture<Void> {
//        database.schema("users").delete()
//    }
//}
//
//
//private struct UserSeed: Migration {
//    init() { }
//
//    func prepare(on database: Database) -> EventLoopFuture<Void> {
//        let tanner = User(name: "Tanner", pet: .init(name: "Ziz", type: .cat))
//        let logan = User(name: "Logan", pet: .init(name: "Runa", type: .dog))
//        return logan.save(on: database)
//            .and(tanner.save(on: database))
//            .map { _ in }
//    }
//
//    func revert(on database: Database) -> EventLoopFuture<Void> {
//        database.eventLoop.makeSucceededFuture(())
//    }
//}
