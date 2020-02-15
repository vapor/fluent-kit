import FluentKit

final class SchoolSeed: Migration {
    init() { }

    func prepare(on database: Database) -> EventLoopFuture<Void> {
        let amsterdam = self.add(
            [
                (name: "schoolA1", pupils: 500),
                (name: "schoolA2", pupils: 250),
                (name: "schoolA3", pupils: 400),
                (name: "schoolA4", pupils: 50)
            ],
            to: "Amsterdam",
            on: database
        )
        let newYork = self.add(
            [
                (name: "schoolB1", pupils: 500),
                (name: "schoolB2", pupils: 500),
                (name: "schoolB3", pupils: 400),
                (name: "schoolB4", pupils: 200)
            ],
            to: "New York",
            on: database
        )
        return .andAllSucceed([amsterdam, newYork], on: database.eventLoop)
    }

    private func add(_ schools: [(name: String, pupils: Int)], to city: String, on database: Database) -> EventLoopFuture<Void> {
        return City.query(on: database)
            .filter(\.$name == city)
            .first()
            .flatMap { city -> EventLoopFuture<Void> in
                guard let city = city else {
                    return database.eventLoop.makeSucceededFuture(())
                }
                let saves = schools.map { school -> EventLoopFuture<Void> in
                    return School(name: school.name, pupils: school.pupils, cityID: city.id!)
                        .save(on: database)
                }
                return .andAllSucceed(saves, on: database.eventLoop)
            }
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.eventLoop.makeSucceededFuture(())
    }
}
