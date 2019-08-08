public protocol Pivot: Model {
    associatedtype Left: Model
    associatedtype Right: Model
    var leftID: Field<Left.IDValue> { get }
    var rightID: Field<Right.IDValue> { get }
}

@propertyWrapper
public final class Siblings<To, Via>: AnyProperty
    where To: Model, Via: Pivot
{
    // MARK: Wrapper
    private var idValue: Encodable?

    public init(_ pivot: Via.Type) { }

    public var wrappedValue: [To] {
        get { fatalError("Use $ prefix to access") }
        set { fatalError("Use $ prefix to access") }
    }

    public var projectedValue: Siblings<To, Via> {
        return self
    }

    // MARK: Operations

    public func attach(_ to: To, on database: Database) -> EventLoopFuture<Void> {
        guard let fromID = self.idValue else {
            fatalError("Cannot attach siblings relation to unsaved model.")
        }
        guard let toID = to.id else {
            fatalError("Cannot attach unsaved model.")
        }

        let pivot = Via()
        if Via.Right.self == To.self {
            pivot.leftID.inputValue = .bind(fromID)
            pivot.rightID.inputValue = .bind(toID)
        } else {
            pivot.leftID.inputValue = .bind(toID)
            pivot.rightID.inputValue = .bind(fromID)
        }
        return pivot.save(on: database)
    }

    public func detach(_ to: To, on database: Database) -> EventLoopFuture<Void> {
        guard let fromID = self.idValue else {
            fatalError("Cannot attach siblings relation to unsaved model.")
        }
        guard let toID = to.id else {
            fatalError("Cannot attach unsaved model.")
        }

        let query = Via.query(on: database)
        if Via.Right.self == To.self {
            query.filter(\.rightID == toID as! Via.Right.IDValue)
                .filter(\.leftID == fromID as! Via.Left.IDValue)
        } else {
            query.filter(\.rightID == fromID as! Via.Right.IDValue)
                .filter(\.leftID == toID as! Via.Left.IDValue)
        }
        return query.delete()
    }

    // MARK: Query

    public func query(on database: Database) throws -> QueryBuilder<To> {
        guard let id = self.idValue else {
            fatalError("Cannot query siblings relation from unsaved model.")
        }

        var toForeignKeyName: String {
            if Via.Right.self == To.self {
                return Via.key(for: \.rightID)
            } else {
                return Via.key(for: \.leftID)
            }
        }

        var fromForeignKeyName: String {
            if Via.Right.self == To.self {
                return Via.key(for: \.leftID)
            } else {
                return Via.key(for: \.rightID)
            }
        }

        return To.query(on: database)
            .join(Via.self, toForeignKeyName,
                  to: To.self, To.key(for: \._$id),
                  method: .inner)
            .filter(
                .field(
                    path: [fromForeignKeyName],
                    entity: Via.entity,
                    alias: nil
                ),
                .equal,
                .bind(id)
            )
    }

    func output(from output: DatabaseOutput) throws {
        if Via.Right.self == To.self {
            let key = Via.Left.key(for: \._$id)
            if output.contains(field: key) {
                self.idValue = try output.decode(field: key, as: Via.Left.IDValue.self)
            }
        } else {
            let key = Via.Right.key(for: \._$id)
            if output.contains(field: key) {
                self.idValue = try output.decode(field: key, as: Via.Right.IDValue.self)
            }
        }
    }

    func encode(to encoder: Encoder) throws {

    }

    func decode(from decoder: Decoder) throws {
        
    }
}
