extension FluentBenchmarker {
    public func testNestedModel() throws {
        try runTest(#function, [
            UserMigration(),
            UserSeed()
        ]) {
            let users = try User.query(on: self.database)
                .filter(\.$pet, "type", .equal, User.Pet.Animal.cat)
                .all().wait()

            guard let user = users.first, users.count == 1 else {
                XCTFail("unexpected user count")
                return
            }
            guard user.name == "Tanner" else {
                XCTFail("unexpected user name")
                return
            }
            guard user.pet.name == "Ziz" else {
                XCTFail("unexpected pet name")
                return
            }
            guard user.pet.type == .cat else {
                XCTFail("unexpected pet type")
                return
            }

            struct UserJSON: Equatable, Codable {
                var id: UUID
                var name: String
                var pet: PetJSON
            }
            struct PetJSON: Equatable, Codable {
                var name: String
                var type: String
            }
            // {"id":...,"name":"Tanner","pet":{"name":"Ziz","type":"cat"}}
            let expected = UserJSON(id: user.id!, name: "Tanner", pet: .init(name: "Ziz", type: "cat"))

            let decoded = try JSONDecoder().decode(UserJSON.self, from: JSONEncoder().encode(user))
            guard decoded == expected else {
                XCTFail("unexpected output")
                return
            }
        }
    }
}

private final class User: Model {
    struct Pet: Codable {
        enum Animal: String, Codable {
            case cat, dog
        }
        var name: String
        var type: Animal
    }
    static let schema = "users"

    @ID(key: FluentBenchmarker.idKey)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Field(key: "pet")
    var pet: Pet

    @OptionalParent(key: "bf_id")
    var bestFriend: User?

    @Children(for: \.$bestFriend)
    var friends: [User]

    init() { }

    init(id: IDValue? = nil, name: String, pet: Pet, bestFriend: User? = nil) {
        self.id = id
        self.name = name
        self.pet = pet
        self.$bestFriend.id = bestFriend?.id
    }
}

private struct UserMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("users")
            .field("id", .uuid, .identifier(auto: false))
            .field("name", .string, .required)
            .field("pet", .json, .required)
            .field("bf_id", .uuid)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("users").delete()
    }
}


private struct UserSeed: Migration {
    init() { }

    func prepare(on database: Database) -> EventLoopFuture<Void> {
        let tanner = User(name: "Tanner", pet: .init(name: "Ziz", type: .cat))
        let logan = User(name: "Logan", pet: .init(name: "Runa", type: .dog))
        return logan.save(on: database)
            .and(tanner.save(on: database))
            .map { _ in }
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.eventLoop.makeSucceededFuture(())
    }
}
