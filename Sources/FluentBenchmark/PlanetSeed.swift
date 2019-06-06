import FluentKit

final class PlanetSeed: Migration {
    init() { }
    
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        let milkyWay = self.add([
            "Mercury", "Venus", "Earth", "Mars", "Jupiter", "Saturn", "Uranus", "Neptune"
        ], to: "Milky Way", on: database)
        let andromeda = self.add(["PA-99-N2"], to: "Andromeda", on: database)
        return .andAllSucceed([milkyWay, andromeda], on: database.eventLoop)
    }
    
    private func add(_ planets: [String], to galaxy: String, on database: Database) -> EventLoopFuture<Void> {
        return Galaxy.query(on: database)
            .filter(\.name == galaxy)
            .first()
            .flatMap { galaxy -> EventLoopFuture<Void> in
                guard let galaxy = galaxy else {
                    return database.eventLoop.makeSucceededFuture(())
                }
                let saves = planets.map { name -> EventLoopFuture<Void> in
                    return Planet(name: name, galaxyID: galaxy.id!)
                        .save(on: database)
                }
                return .andAllSucceed(saves, on: database.eventLoop)
            }
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.eventLoop.makeSucceededFuture(())
    }
}
