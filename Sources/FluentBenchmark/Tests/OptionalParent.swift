extension FluentBenchmarker {
    public func testOptionalParent() throws {
        try runTest(#function, [
            UserMigration()
        ]) {
            // seed
            do {
                let swift = User(
                    name: "Swift",
                    pet: .init(name: "Foo", type: .dog),
                    bestFriend: nil
                )
                try swift.save(on: self.database).wait()
                let vapor = User(
                    name: "Vapor",
                    pet: .init(name: "Bar", type: .cat),
                    bestFriend: swift
                )
                try vapor.save(on: self.database).wait()
            }

            // test
            let users = try User.query(on: self.database)
                .with(\.$bestFriend)
                .with(\.$friends)
                .all().wait()
            for user in users {
                switch user.name {
                case "Swift":
                    XCTAssertEqual(user.bestFriend?.name, nil)
                    XCTAssertEqual(user.friends.count, 1)
                case "Vapor":
                    XCTAssertEqual(user.bestFriend?.name, "Swift")
                    XCTAssertEqual(user.friends.count, 0)
                default:
                    XCTFail("unexpected name: \(user.name)")
                }
            }

            // test query with no ids
            // https://github.com/vapor/fluent-kit/issues/85
            let users2 = try User.query(on: self.database)
                .with(\.$bestFriend)
                .filter(\.$bestFriend == nil)
                .all().wait()
            XCTAssertEqual(users2.count, 1)
            XCTAssert(users2.first?.bestFriend == nil)
        }
    }
}
