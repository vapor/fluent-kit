public protocol Pivot: Model {
    associatedtype Left: Model
    associatedtype Right: Model
    static var leftID: PartialKeyPath<Self> { get }
    static var rightID: PartialKeyPath<Self> { get }
}

extension Pivot {
    var _$leftID: AnyField {
        return self[keyPath: Self.leftID] as! AnyField
    }
    var _$rightID: AnyField {
        return self[keyPath: Self.rightID] as! AnyField
    }
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

    private var toForeignKeyName: String {
        if Via.Right.self == To.self {
            return Via.key(for: \Via._$rightID)
        } else {
            return Via.key(for: \Via._$leftID)
        }
    }

    private var fromForeignKeyName: String {
        if Via.Right.self == To.self {
            return Via.key(for: \Via._$leftID)
        } else {
            return Via.key(for: \Via._$rightID)
        }
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
            pivot._$leftID.inputValue = .bind(fromID)
            pivot._$rightID.inputValue = .bind(toID)
        } else {
            pivot._$leftID.inputValue = .bind(toID)
            pivot._$rightID.inputValue = .bind(fromID)
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
            query.filter(
                .field(path: [Via.key(for: \Via._$leftID)], entity: Via.entity, alias: nil),
                .equal,
                .bind(fromID)
            ).filter(
            .field(path: [Via.key(for: \Via._$rightID)], entity: Via.entity, alias: nil),
                .equal,
                .bind(toID)
            )
        } else {
            query.filter(
                .field(path: [Via.key(for: \Via._$rightID)], entity: Via.entity, alias: nil),
                .equal,
                .bind(fromID)
            ).filter(
            .field(path: [Via.key(for: \Via._$leftID)], entity: Via.entity, alias: nil),
                .equal,
                .bind(toID)
            )
        }
        return query.delete()
    }

    // MARK: Query

    public func query(on database: Database) throws -> QueryBuilder<To> {
        guard let id = self.idValue else {
            fatalError("Cannot query siblings relation from unsaved model.")
        }
        return To.query(on: database)
            .join(Via.self, self.toForeignKeyName,
                  to: To.self, To.key(for: \._$id),
                  method: .inner)
            .filter(
                .field(
                    path: [self.fromForeignKeyName],
                    entity: Via.entity,
                    alias: nil
                ),
                .equal,
                .bind(id)
            )
    }

    func output(from output: DatabaseOutput, label: String) throws {
        if Via.Right.self == To.self {
            let key = Via.Left.key(for: \._$id)
            if output.contains(field: key) {
                self.idValue = try output.decode(field: key, as: Via.Left.ID.self)
            }
        } else {
            let key = Via.Right.key(for: \._$id)
            if output.contains(field: key) {
                self.idValue = try output.decode(field: key, as: Via.Right.ID.self)
            }
        }
    }

    func encode(to encoder: inout ModelEncoder, label: String) throws {
        fatalError()
    }

    func decode(from decoder: ModelDecoder, label: String) throws {
        fatalError()
    }
}
