public struct PageMetadata: Codable {
    public let page: Int
    public let per: Int
    public let total: Int
}

public struct Page<T>: Codable where T: Codable {
    public let items: [T]
    public let metadata: PageMetadata

    public init(items: [T], metadata: PageMetadata) {
        self.items = items
        self.metadata = metadata
    }

    public func map<U>(_ transform: (T) throws -> (U)) rethrows -> Page<U>
        where U: Codable
    {
        try .init(
            items: self.items.map(transform),
            metadata: self.metadata
        )
    }
}

public struct PageRequest: Decodable {
    public let page: Int
    public let per: Int

    enum CodingKeys: String, CodingKey {
        case page = "page"
        case per = "per"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.page = try container.decodeIfPresent(Int.self, forKey: .page) ?? 1
        self.per = try container.decodeIfPresent(Int.self, forKey: .per) ?? 10
    }

    public init(page: Int, per: Int) {
        self.page = page
        self.per = per
    }

    var start: Int {
        (self.page - 1) * self.per
    }

    var end: Int {
        self.page * self.per
    }
}

extension QueryBuilder {
    public func paginate(
        _ request: PageRequest
    ) -> EventLoopFuture<Page<Model>> {
        self.count()
            .flatMap {
                self.range(request.start..<request.end).all().and(value: $0)
            }.map { (models, total) in
                Page(
                    items: models,
                    metadata: .init(
                        page: request.page,
                        per: request.per,
                        total: total
                    )
                )
            }
    }
}
