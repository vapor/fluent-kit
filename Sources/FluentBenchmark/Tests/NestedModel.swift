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
                throw Failure("unexpected user count")
            }
            guard user.name == "Tanner" else {
                throw Failure("unexpected user name")
            }
            guard user.pet.name == "Ziz" else {
                throw Failure("unexpected pet name")
            }
            guard user.pet.type == .cat else {
                throw Failure("unexpected pet type")
            }

            struct UserJSON: Equatable, Codable {
                var id: Int
                var name: String
                var pet: PetJSON
            }
            struct PetJSON: Equatable, Codable {
                var name: String
                var type: String
            }
            // {"id":2,"name":"Tanner","pet":{"name":"Ziz","type":"cat"}}
            let expected = UserJSON(id: 2, name: "Tanner", pet: .init(name: "Ziz", type: "cat"))

            let decoded = try JSONDecoder().decode(UserJSON.self, from: JSONEncoder().encode(user))
            guard decoded == expected else {
                throw Failure("unexpected output")
            }
        }
    }
}
