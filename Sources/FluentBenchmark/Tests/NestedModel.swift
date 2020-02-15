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
                XCTFail("unexpected output")
                return
            }
        }
    }
}
